"""
BigQuery Data Analyst Agent (POC)

A LangGraph agent that takes natural language → queries BigQuery → renders charts.

Usage:
    python bq_agent.py "What were the top 5 baby names in 2020?"
    python bq_agent.py "Show me the trend of 'Emma' over the last 20 years"

## PRODUCTION NOTES

### Architecture (when integrating into backend/):
- This agent becomes ONE of several specialists behind a router
- Router node (in graph.py) classifies intent → routes to:
  1. data_analyst - BigQuery queries, charts, structured data
  2. web_search - Current events, news, qualitative info (separate agent)
  3. chat - General conversation, greetings, help

### Frontend Integration (Vercel AI SDK):
- Charts render via `inline-chart.tsx` component
- execute_query results → sent as data stream part with type="chart"
- Frontend receives: { type: "chart", chart_type, config, data }
- Recharts renders based on chart_type (line/bar/pie/etc.)
- See: frontend/components/inline-chart.tsx

### Tools to Extract:
- web_search → Move to dedicated WebSearchAgent
- suggest_chart → Output becomes stream part, not tool (frontend renders)

### State to Add for Production:
- user_id, chat_id for persistence
- query_history for context
- cost_tracking (bytes_processed from BQ)
"""

import asyncio
import json
import os
import sys
from datetime import datetime, timezone
from typing import Annotated, Literal

import pandas as pd
import plotly.express as px
from google.cloud import bigquery
from langchain_community.tools import DuckDuckGoSearchRun
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage, ToolMessage
from langchain_core.tools import tool
from langchain_google_vertexai import ChatVertexAI
from langgraph.graph import END, StateGraph
from langgraph.graph.message import add_messages
from langgraph.prebuilt import ToolNode
from typing_extensions import TypedDict

# -----------------------------------------------------------------------------
# Configuration
# PROD: Move to backend/src/config.py, load from environment/secrets
# -----------------------------------------------------------------------------

PROJECT = os.environ.get("GOOGLE_CLOUD_PROJECT", "knowsee-platform-development")
LOCATION = os.environ.get("GOOGLE_CLOUD_LOCATION", "europe-west2")
PUBLIC_PROJECT = "bigquery-public-data"
MAX_ITERATIONS = 12  # PROD: Consider per-user limits, cost controls

# -----------------------------------------------------------------------------
# Clients
# PROD: Use dependency injection, connection pooling
# -----------------------------------------------------------------------------

bq_client = bigquery.Client(project=PROJECT)
llm = ChatVertexAI(model="gemini-2.5-flash", project=PROJECT, location=LOCATION, temperature=0.3)
_ddg_search = DuckDuckGoSearchRun()  # PROD: Remove - web_search becomes separate agent

# -----------------------------------------------------------------------------
# State
# PROD: Extend with user_id, chat_id, detected_intent, cost_bytes
# -----------------------------------------------------------------------------


class DataAnalystState(TypedDict, total=False):
    """State flows through the graph.

    PROD additions:
    - user_id: str - for auth/billing
    - chat_id: str - for persistence
    - bytes_processed: int - BQ cost tracking
    """

    # Required
    messages: Annotated[list[BaseMessage], add_messages]
    iteration_count: int

    # Output
    charts: list[dict]  # PROD: Stream as data parts, not accumulated in state

    # Router fields (Reject + Redirect pattern)
    detected_intent: str  # "data_analyst" | "web_search" | "chat"
    pending_web_query: str | None  # Query that couldn't be answered by BQ

    # Options for user (rendered as buttons in frontend)
    show_options: bool
    options: list[dict]  # [{"action": "__ACTION__:X", "label": "...", "description": "..."}]


# -----------------------------------------------------------------------------
# Intent Detection (Router Logic)
# Uses ACTION PREFIXES instead of regex - deterministic and unambiguous
# -----------------------------------------------------------------------------

# Action prefixes - frontend sends these when user clicks an option button
# Format: "__ACTION__:<action_type>" at start of message
ACTION_PREFIX = "__ACTION__:"
ACTION_WEB_SEARCH = f"{ACTION_PREFIX}WEB_SEARCH"
ACTION_REFINE_QUERY = f"{ACTION_PREFIX}REFINE_QUERY"
ACTION_NEW_QUESTION = f"{ACTION_PREFIX}NEW_QUESTION"


def detect_intent(message: str, has_pending_web_query: bool = False) -> str:
    """Detect user intent from message - uses explicit actions, not regex.

    Frontend Flow:
        1. Agent can't answer → returns message + options as data stream part
        2. Frontend renders: "I can't find this in BigQuery" + [Search Web] [Ask Differently] buttons
        3. User clicks [Search Web] → frontend sends "__ACTION__:WEB_SEARCH"
        4. Router sees action prefix → routes to web_search agent

    This is deterministic - no guessing user intent from natural language.

    Args:
        message: The user's message (may contain action prefix).
        has_pending_web_query: Whether a previous turn suggested web search.

    Returns:
        One of: "data_analyst", "web_search", "chat"
    """
    text = message.strip()

    # 1. Check for explicit action (from button click)
    if text.startswith(ACTION_WEB_SEARCH):
        return "web_search"
    if text.startswith(ACTION_REFINE_QUERY):
        return "data_analyst"
    if text.startswith(ACTION_NEW_QUESTION):
        return "data_analyst"

    # 2. Simple heuristics for initial routing (not approval parsing)
    text_lower = text.lower()

    # Greetings → chat
    if text_lower in ["hi", "hello", "hey", "help"]:
        return "chat"

    # Default → data_analyst (it will offer options if it can't help)
    return "data_analyst"


# Options to show when agent can't answer from BigQuery
# Frontend renders these as clickable buttons
# PROD: Sent as data stream part: { type: "options", options: [...] }
FALLBACK_OPTIONS = [
    {
        "action": ACTION_WEB_SEARCH,
        "label": "Search the web",
        "description": "Find current information online",
    },
    {
        "action": ACTION_REFINE_QUERY,
        "label": "Ask differently",
        "description": "Rephrase for BigQuery data",
    },
]


# -----------------------------------------------------------------------------
# Tools
# PROD: Move to backend/src/agents/data_analyst/tools.py
# PROD: web_search → separate WebSearchAgent (router decides which agent)
# -----------------------------------------------------------------------------


@tool
def web_search(query: str) -> str:
    """PROD: REMOVE - This becomes a separate WebSearchAgent.
    Router classifies intent and routes to appropriate agent.

    Search the web for current information, news, trends, or topics NOT available in BigQuery.

    Use this tool when:
    - The question is about current events, news, or recent developments
    - You need information about specific topics/categories (e.g., "AI trends", "tech news")
    - BigQuery public datasets cannot answer the question (no categorisation, wrong domain)
    - The user asks about trending topics in a specific industry or field

    Do NOT use this for:
    - Questions that can be answered with structured BigQuery data
    - Historical statistical analysis (use BigQuery instead)
    """
    return _ddg_search.run(query)


@tool
def list_datasets() -> str:
    """List available public BigQuery datasets with capabilities and limitations."""
    return """Available datasets in bigquery-public-data:

1. **usa_names** - US baby names 1910-present
   - Tables: usa_1910_current
   - Good for: Name popularity over time, gender trends, state comparisons
   - Note: US only, no global data

2. **google_trends** - Search trends data
   - Tables: top_terms, top_rising_terms, international_top_terms
   - Good for: Top search terms by week/region, rising searches, trend analysis over time
   - Contains: Raw search terms with scores, weekly data, regional breakdowns
   - Example queries: "top 10 trending searches this month", "search trends by country"
   - Note: Terms are not categorised by topic, but you CAN query for specific terms or top N terms

3. **ga4_obfuscated_sample_ecommerce** - GA4 e-commerce events
   - Good for: User behaviour analysis, conversion funnels, event tracking examples
   - Note: Sample data, obfuscated

4. **samples** - Classic BigQuery samples
   - Tables: shakespeare, natality, github_timeline
   - Good for: Learning SQL, text analysis, birth statistics

5. **austin_bikeshare** / **chicago_taxi_trips** / **new_york_taxi_trips**
   - Good for: Transportation analysis, geospatial queries, time patterns

## WORKFLOW:
ALWAYS follow: list_tables -> get_table_schema -> execute_query -> suggest_chart (if 2+ rows)

Use list_tables(dataset_id) to see exact table names before querying."""


@tool
def list_tables(dataset_id: str) -> str:
    """List all tables in a dataset. ALWAYS call this before get_table_schema."""
    sql = f"""
    SELECT table_name
    FROM `bigquery-public-data.{dataset_id}.INFORMATION_SCHEMA.TABLES`
    """
    try:
        rows = list(bq_client.query(sql).result())
        if not rows:
            return f"No tables found in {dataset_id}"
        lines = [f"Tables in bigquery-public-data.{dataset_id}:"]
        for r in rows:
            lines.append(f"  - {r.table_name}")
        return "\n".join(lines)
    except Exception as e:
        return f"Error listing tables: {e}"


@tool
def get_table_schema(dataset_id: str, table_id: str) -> str:
    """Get schema of a BigQuery table. Call list_tables first to get valid table names."""
    try:
        table_ref = f"{PUBLIC_PROJECT}.{dataset_id}.{table_id}"
        table = bq_client.get_table(table_ref)
        lines = [f"Schema for {table_ref} ({table.num_rows:,} rows):"]
        for field in table.schema:
            lines.append(f"  - {field.name}: {field.field_type}")
        return "\n".join(lines)
    except Exception as e:
        return f"Error: {e}"


@tool
def execute_query(sql: str, max_rows: int = 100) -> str:
    """Execute a SELECT query. Returns JSON with columns, rows, and total_rows."""
    if any(kw in sql.upper() for kw in ["INSERT", "UPDATE", "DELETE", "DROP", "CREATE"]):
        return json.dumps({"error": "Only SELECT allowed", "columns": [], "rows": []})
    try:
        result = bq_client.query(sql).result(timeout=30)
        columns = [f.name for f in result.schema]
        rows = []
        for i, row in enumerate(result):
            if i >= min(max_rows, 1000):
                break
            row_dict = {}
            for col in columns:
                val = row[col]
                row_dict[col] = val.isoformat() if hasattr(val, "isoformat") else val
            rows.append(row_dict)
        return json.dumps({"columns": columns, "rows": rows, "total_rows": result.total_rows})
    except Exception as e:
        return json.dumps({"error": str(e), "columns": [], "rows": []})


# PROD: This tool's output becomes a Vercel AI SDK data stream part
# Frontend receives: { type: "chart", chartType, title, xAxis, yAxis, data }
# inline-chart.tsx renders using Recharts (LineChart, BarChart, PieChart, etc.)
@tool
def suggest_chart(
    chart_type: Literal["line", "bar", "pie", "scatter", "area", "histogram"],
    title: str,
    x_column: str,
    y_column: str,
    data: list[dict],
    color_column: str | None = None,
) -> str:
    """Suggest a visualisation for query results. Call this AFTER execute_query when data should be visualised.

    Args:
        chart_type: The type of chart that best represents the data:
            - "line": Time series, trends over time
            - "bar": Comparisons across categories
            - "pie": Part-to-whole relationships (use sparingly, max 6 slices)
            - "scatter": Correlation between two numeric variables
            - "area": Cumulative totals over time
            - "histogram": Distribution of a single numeric variable
        title: A descriptive title for the chart (based on the user's question)
        x_column: Column name for the x-axis
        y_column: Column name for the y-axis (the metric being measured)
        data: The query result rows to visualise (from execute_query)
        color_column: Optional column for grouping/coloring (e.g., gender, category)

    Returns:
        Confirmation that the chart has been queued for rendering.
    """
    if not data:
        return "Error: No data provided for chart"

    sample = data[0]
    missing = []
    if x_column not in sample:
        missing.append(f"x_column '{x_column}'")
    if y_column not in sample:
        missing.append(f"y_column '{y_column}'")
    if color_column and color_column not in sample:
        missing.append(f"color_column '{color_column}'")

    if missing:
        return f"Error: Columns not found in data: {', '.join(missing)}. Available: {list(sample.keys())}"

    config = {
        "chart_type": chart_type,
        "title": title,
        "x": x_column,
        "y": y_column,
        "color": color_column,
        "data": data,
        "_is_chart_config": True,
    }
    return json.dumps(config)


# Tool sets per agent (Reject + Redirect pattern)
# Data analyst has NO web_search - it must suggest and wait for approval
DATA_ANALYST_TOOLS = [list_datasets, list_tables, get_table_schema, execute_query, suggest_chart]
WEB_SEARCH_TOOLS = [web_search]  # Separate agent, only activated on user approval
CHAT_TOOLS = []  # Chat agent has no tools, just responds

# POC: Still using combined tools for testing, but production splits them
ALL_TOOLS = DATA_ANALYST_TOOLS + WEB_SEARCH_TOOLS

# -----------------------------------------------------------------------------
# System Prompt
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# System Prompts (one per agent in production)
# -----------------------------------------------------------------------------

DATA_ANALYST_PROMPT = f"""You are a Data Analyst with access to BigQuery public datasets.
Today: {datetime.now(timezone.utc).strftime("%Y-%m-%d")}

## YOUR CAPABILITIES
You can ONLY query BigQuery public datasets. You do NOT have web search capability.

## WORKFLOW (follow strictly):
1. list_datasets() → see available datasets
2. list_tables(dataset_id) → get EXACT table names (NEVER guess)
3. get_table_schema(dataset_id, table_id) → understand columns
4. execute_query(sql) → run your query
5. suggest_chart() → ALWAYS call this if query returns 2+ rows

## WHEN YOU CANNOT ANSWER:
If the question cannot be answered with BigQuery data (e.g., current events,
qualitative opinions, topics not in the datasets), respond with:

"I can't find this in the available BigQuery datasets. Would you like me to
search the web instead?"

Do NOT apologise excessively. Do NOT attempt to answer without data.
Simply state the limitation and offer the web search alternative.

## VISUALISATION (MANDATORY):
If execute_query returns 2+ rows and user asked to "plot", "chart", or "visualise":
- You MUST call suggest_chart
- Choose: line (time series), bar (categories), pie (parts of whole)
- Pass the `rows` array from execute_query as the `data` parameter

## RULES:
- NEVER guess table names - always call list_tables first
- Use LIMIT for exploration queries
- Only SELECT statements allowed
- Summarise findings in 2-3 sentences"""

WEB_SEARCH_PROMPT = f"""You are a Research Assistant with web search capability.
Today: {datetime.now(timezone.utc).strftime("%Y-%m-%d")}

The user has approved a web search. Answer their question using web_search.

## GUIDELINES:
- Search for relevant, recent information
- Cite sources when possible
- Summarise findings clearly
- If results are insufficient, say so honestly"""

CHAT_PROMPT = """You are a helpful assistant. Answer the user's question conversationally.
If they ask about data analysis, suggest they ask a specific data question."""

# POC: Using combined prompt, production uses per-agent prompts
SYSTEM_PROMPT = DATA_ANALYST_PROMPT

# -----------------------------------------------------------------------------
# Graph Nodes
# -----------------------------------------------------------------------------

# Bind tools per agent type
llm_data_analyst = llm.bind_tools(DATA_ANALYST_TOOLS)
llm_web_search = llm.bind_tools(WEB_SEARCH_TOOLS)
llm_chat = llm  # No tools

# POC: Combined for testing
llm_with_tools = llm.bind_tools(ALL_TOOLS)


def router_node(state: DataAnalystState) -> dict:
    """Route to appropriate agent based on user intent.

    This is the key to the Reject + Redirect pattern:
    - Runs BEFORE any agent
    - Classifies intent using deterministic regex (fast, predictable)
    - Sets detected_intent which determines which agent handles the request

    PROD: This becomes the entry point of the main graph.
    """
    messages = state.get("messages", [])
    if not messages:
        return {"detected_intent": "chat"}

    # Get the latest user message
    last_human_msg = None
    for msg in reversed(messages):
        if isinstance(msg, HumanMessage):
            last_human_msg = msg.content if isinstance(msg.content, str) else str(msg.content)
            break

    if not last_human_msg:
        return {"detected_intent": "chat"}

    # Check if there's a pending web query (user might be approving it)
    has_pending = bool(state.get("pending_web_query"))

    intent = detect_intent(last_human_msg, has_pending_web_query=has_pending)

    return {"detected_intent": intent}


async def data_analyst_node(state: DataAnalystState) -> dict:
    """Data Analyst agent - BigQuery only, no web search.

    When agent can't answer, it returns structured options for the frontend:
    {
        "messages": [...],
        "show_options": True,
        "options": [
            {"action": "__ACTION__:WEB_SEARCH", "label": "Search the web"},
            {"action": "__ACTION__:REFINE_QUERY", "label": "Ask differently"},
        ],
        "pending_web_query": "original user question"
    }

    Frontend renders these as clickable buttons. User click → sends action → router handles.
    """
    messages = list(state["messages"])

    if not any(isinstance(m, SystemMessage) for m in messages):
        messages = [SystemMessage(content=DATA_ANALYST_PROMPT)] + messages

    response = await llm_data_analyst.ainvoke(messages)

    # Check if agent is suggesting web search (can't answer from BQ)
    result: dict = {
        "messages": [response],
        "iteration_count": state.get("iteration_count", 0) + 1,
    }

    # Detect if agent couldn't answer and offered web search
    response_text = str(response.content).lower() if response.content else ""
    if "search the web" in response_text or "can't find" in response_text:
        # Extract original question for redirect flow
        for msg in messages:
            if isinstance(msg, HumanMessage):
                result["pending_web_query"] = (
                    msg.content if isinstance(msg.content, str) else str(msg.content)
                )
                break

        # PROD: These become data stream parts that frontend renders as buttons
        # await stream.write_data({ "type": "options", "options": FALLBACK_OPTIONS })
        result["show_options"] = True
        result["options"] = FALLBACK_OPTIONS

    return result


async def web_search_node(state: DataAnalystState) -> dict:
    """Web Search agent - activated only when user approves."""
    messages = list(state["messages"])

    # Use the pending query if this is an approval flow
    pending = state.get("pending_web_query")
    if pending:
        # Inject context about what we're searching for
        context_msg = SystemMessage(
            content=f"{WEB_SEARCH_PROMPT}\n\nOriginal question to answer: {pending}"
        )
        messages = [context_msg] + messages
    elif not any(isinstance(m, SystemMessage) for m in messages):
        messages = [SystemMessage(content=WEB_SEARCH_PROMPT)] + messages

    response = await llm_web_search.ainvoke(messages)

    return {
        "messages": [response],
        "iteration_count": state.get("iteration_count", 0) + 1,
        "pending_web_query": None,  # Clear after use
    }


async def chat_node(state: DataAnalystState) -> dict:
    """Simple chat agent - no tools."""
    messages = list(state["messages"])

    if not any(isinstance(m, SystemMessage) for m in messages):
        messages = [SystemMessage(content=CHAT_PROMPT)] + messages

    response = await llm_chat.ainvoke(messages)

    return {
        "messages": [response],
        "iteration_count": state.get("iteration_count", 0) + 1,
    }


# POC: Keep original agent_node for backward compatibility
async def agent_node(state: DataAnalystState) -> dict:
    """POC: Combined agent with all tools. PROD: Use router + specialised agents."""
    messages = list(state["messages"])

    if not any(isinstance(m, SystemMessage) for m in messages):
        messages = [SystemMessage(content=SYSTEM_PROMPT)] + messages

    response = await llm_with_tools.ainvoke(messages)
    return {
        "messages": [response],
        "iteration_count": state.get("iteration_count", 0) + 1,
    }


def should_continue(state: DataAnalystState) -> str:
    """Route: tools, or generate output."""
    if state.get("iteration_count", 0) >= MAX_ITERATIONS:
        return "generate_output"

    last = state["messages"][-1]
    if isinstance(last, AIMessage) and getattr(last, "tool_calls", None):
        return "tools"
    return "generate_output"


async def generate_output_node(state: DataAnalystState) -> dict:
    """Extract chart configs from suggest_chart tool calls.

    PROD: Instead of accumulating charts in state, stream each as a data part:
        await stream.write_data({
            "type": "chart",
            "chartType": config["chart_type"],
            "title": config["title"],
            "xAxis": config["x"],
            "yAxis": config["y"],
            "data": config["data"],
        })
    Frontend DataStreamHandler receives and renders via inline-chart.tsx
    """
    charts = []

    for msg in state["messages"]:
        if not isinstance(msg, ToolMessage):
            continue
        if msg.name != "suggest_chart":
            continue
        try:
            parsed = json.loads(msg.content) if isinstance(msg.content, str) else msg.content
            if isinstance(parsed, dict) and parsed.get("_is_chart_config"):
                chart_config = {k: v for k, v in parsed.items() if k != "_is_chart_config"}
                charts.append(chart_config)
        except (json.JSONDecodeError, TypeError):
            continue

    return {"charts": charts}


# -----------------------------------------------------------------------------
# Build Graph
# PROD: This becomes a subgraph within the main router graph:
#
#   START → router_node ─┬→ data_analyst_subgraph → END
#                        ├→ web_search_subgraph   → END
#                        └→ chat_subgraph         → END
#
# Each subgraph has its own tools and specialised prompt
# -----------------------------------------------------------------------------

graph = StateGraph(DataAnalystState)
graph.add_node("agent", agent_node)
graph.add_node("tools", ToolNode(ALL_TOOLS))
graph.add_node("generate_output", generate_output_node)

graph.set_entry_point("agent")
graph.add_conditional_edges(
    "agent",
    should_continue,
    {
        "tools": "tools",
        "generate_output": "generate_output",
    },
)
graph.add_edge("tools", "agent")
graph.add_edge("generate_output", END)

data_analyst = graph.compile()


# -----------------------------------------------------------------------------
# Production Graph (Reject + Redirect Pattern)
# Uncomment to test the router-based architecture
# -----------------------------------------------------------------------------


def build_production_graph() -> StateGraph:
    """Build the production router-based graph.

    Flow:
        START → router → [data_analyst | web_search | chat] → tools? → generate_output → END

    The router classifies intent BEFORE any LLM call, ensuring:
    - Web search only happens with explicit user approval
    - Each agent has only its designated tools
    - Clear separation of concerns
    """
    prod_graph = StateGraph(DataAnalystState)

    # Add all nodes
    prod_graph.add_node("router", router_node)
    prod_graph.add_node("data_analyst", data_analyst_node)
    prod_graph.add_node("web_search", web_search_node)
    prod_graph.add_node("chat", chat_node)
    prod_graph.add_node("data_analyst_tools", ToolNode(DATA_ANALYST_TOOLS))
    prod_graph.add_node("web_search_tools", ToolNode(WEB_SEARCH_TOOLS))
    prod_graph.add_node("generate_output", generate_output_node)

    # Entry point is router
    prod_graph.set_entry_point("router")

    # Router dispatches to appropriate agent
    def route_by_intent(state: DataAnalystState) -> str:
        return state.get("detected_intent", "chat")

    prod_graph.add_conditional_edges(
        "router",
        route_by_intent,
        {
            "data_analyst": "data_analyst",
            "web_search": "web_search",
            "chat": "chat",
        },
    )

    # Data analyst can call tools or finish
    def data_analyst_should_continue(state: DataAnalystState) -> str:
        if state.get("iteration_count", 0) >= MAX_ITERATIONS:
            return "generate_output"
        last = state["messages"][-1] if state.get("messages") else None
        if isinstance(last, AIMessage) and getattr(last, "tool_calls", None):
            return "data_analyst_tools"
        return "generate_output"

    prod_graph.add_conditional_edges(
        "data_analyst",
        data_analyst_should_continue,
        {
            "data_analyst_tools": "data_analyst_tools",
            "generate_output": "generate_output",
        },
    )
    prod_graph.add_edge("data_analyst_tools", "data_analyst")

    # Web search can call tools or finish
    def web_search_should_continue(state: DataAnalystState) -> str:
        if state.get("iteration_count", 0) >= MAX_ITERATIONS:
            return "generate_output"
        last = state["messages"][-1] if state.get("messages") else None
        if isinstance(last, AIMessage) and getattr(last, "tool_calls", None):
            return "web_search_tools"
        return "generate_output"

    prod_graph.add_conditional_edges(
        "web_search",
        web_search_should_continue,
        {
            "web_search_tools": "web_search_tools",
            "generate_output": "generate_output",
        },
    )
    prod_graph.add_edge("web_search_tools", "web_search")

    # Chat goes straight to output
    prod_graph.add_edge("chat", "generate_output")

    # Output is terminal
    prod_graph.add_edge("generate_output", END)

    return prod_graph.compile()


# Uncomment to use production graph:
# data_analyst = build_production_graph()

# -----------------------------------------------------------------------------
# Chart Rendering
# POC ONLY: Plotly for notebook testing
# PROD: Remove entirely - frontend handles rendering via inline-chart.tsx + Recharts
# -----------------------------------------------------------------------------


def render_chart(chart_config: dict) -> None:
    """POC: Render chart in notebook. PROD: Frontend renders via Recharts."""
    df = pd.DataFrame(chart_config["data"])
    chart_type = chart_config["chart_type"]
    title = chart_config.get("title", "Chart")
    x = chart_config["x"]
    y = chart_config["y"]
    color = chart_config.get("color")

    chart_funcs = {
        "line": px.line,
        "bar": px.bar,
        "pie": px.pie,
        "scatter": px.scatter,
        "area": px.area,
        "histogram": px.histogram,
    }

    func = chart_funcs.get(chart_type, px.bar)
    kwargs: dict = {"data_frame": df, "title": title}

    if chart_type == "pie":
        kwargs["names"] = x
        kwargs["values"] = y
    elif chart_type == "histogram":
        kwargs["x"] = y
    else:
        kwargs["x"] = x
        kwargs["y"] = y
        if color:
            kwargs["color"] = color

    fig = func(**kwargs)
    fig.show()


# -----------------------------------------------------------------------------
# Main Entry Point
# -----------------------------------------------------------------------------


async def analyse(question: str, show_trace: bool = False) -> dict:
    """Run the data analyst agent and display results."""
    result = await data_analyst.ainvoke(
        {
            "messages": [HumanMessage(content=question)],
            "charts": [],
            "iteration_count": 0,
        }
    )

    if show_trace:
        print("=" * 60)
        print("TRACE:")
        for i, msg in enumerate(result["messages"]):
            content_preview = str(msg.content)[:100] if msg.content else "(empty)"
            print(f"[{i}] {type(msg).__name__}: {content_preview}...")
        print("=" * 60)

    # Print final answer
    final_msg = result["messages"][-1]
    print(f"\nAnswer: {final_msg.content}\n")

    # Render all charts
    charts = result.get("charts", [])
    if charts:
        print(f"Rendering {len(charts)} chart(s)...\n")
        for i, chart_config in enumerate(charts):
            print(f"Chart {i + 1}: {chart_config.get('title', 'Untitled')}")
            render_chart(chart_config)

    return result


def main():
    """CLI entry point."""
    if len(sys.argv) < 2:
        print("Usage: python bq_agent.py '<question>'")
        print("Example: python bq_agent.py 'What were the top 5 baby names in 2020?'")
        sys.exit(1)

    print(data_analyst)
    question = "".join(sys.argv[1:])
    print(f"\nQuestion: {question}\n")
    asyncio.run(analyse(question, show_trace=True))


if __name__ == "__main__":
    main()
