"""
BigQuery Data Analyst Agent

A LangGraph agent that takes natural language → queries BigQuery → renders charts.
Includes web search fallback for questions BigQuery can't answer.

Usage:
    python bq_agent.py "What were the top 5 baby names in 2020?"
    python bq_agent.py "Show me the trend of 'Emma' over the last 20 years"
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
# -----------------------------------------------------------------------------

PROJECT = os.environ.get("GOOGLE_CLOUD_PROJECT", "knowsee-platform-development")
LOCATION = os.environ.get("GOOGLE_CLOUD_LOCATION", "europe-west2")
PUBLIC_PROJECT = "bigquery-public-data"
MAX_ITERATIONS = 12

# -----------------------------------------------------------------------------
# Clients
# -----------------------------------------------------------------------------

bq_client = bigquery.Client(project=PROJECT)
llm = ChatVertexAI(model="gemini-2.5-flash", project=PROJECT, location=LOCATION, temperature=0.3)
_ddg_search = DuckDuckGoSearchRun()

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------


class DataAnalystState(TypedDict):
    """State flows through the graph."""

    messages: Annotated[list[BaseMessage], add_messages]
    charts: list[dict]  # List of chart configs (plain dicts to avoid schema issues)
    iteration_count: int


# -----------------------------------------------------------------------------
# Tools
# -----------------------------------------------------------------------------


@tool
def web_search(query: str) -> str:
    """Search the web for current information, news, trends, or topics NOT available in BigQuery.

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


ALL_TOOLS = [list_datasets, list_tables, get_table_schema, execute_query, suggest_chart, web_search]

# -----------------------------------------------------------------------------
# System Prompt
# -----------------------------------------------------------------------------

SYSTEM_PROMPT = f"""You are a cynical but brilliant Data Analyst with access to BigQuery public datasets AND web search.
Today: {datetime.now(timezone.utc).strftime("%Y-%m-%d")}

## CRITICAL RULE - USER INSTRUCTIONS OVERRIDE DEFAULTS:
If the user explicitly mentions a data source (e.g., "use BigQuery", "use Google Trends dataset"),
you MUST use that source. Query the data first, then explain any limitations in your response.
Do NOT skip to web_search when the user has specified a data source.

## TOOL SELECTION (decide FIRST):

**Use BigQuery when:**
- User explicitly mentions BigQuery, a specific dataset, or "public data"
- Question involves structured data analysis (counts, aggregations, comparisons)
- Historical trends with specific metrics (baby names over time, taxi trips by hour)
- Statistical queries on known datasets
- User asks to "plot", "chart", or "visualise" data (BigQuery provides the data for charts)

**Use web_search ONLY when:**
- User explicitly asks for web/internet search
- You have already queried BigQuery AND found it insufficient for the question
- Question is about current events, news, or real-time information that BigQuery cannot have
- You need qualitative opinions, not quantitative data

## BigQuery WORKFLOW (when using BigQuery):
1. list_datasets() -> see available datasets AND their limitations
2. list_tables(dataset_id) -> get EXACT table names (NEVER guess)
3. get_table_schema(dataset_id, table_id) -> understand columns
4. execute_query(sql) -> run your query
5. suggest_chart() -> ALWAYS call this after execute_query if the data can be visualised

## VISUALISATION GUIDELINES (MANDATORY):
**CRITICAL: If execute_query returns 2+ rows and user asked to "plot", "chart", "visualise", or "show trends",
you MUST call suggest_chart. Failing to do so is an error.**

After execute_query returns data with 2+ rows:
1. Parse the JSON result from execute_query
2. Call suggest_chart with the data, choosing the right chart type:
   - **line**: Trends over time (years, months, dates) - USE FOR "trends" questions
   - **bar**: Comparing categories (names, states, products)
   - **pie**: Part-to-whole (max 6 slices, use sparingly)
   - **scatter**: Correlation between two numbers
   - **histogram**: Distribution of a single metric
3. Create a clear, descriptive title based on what the user asked
4. Pass the `rows` array from execute_query result as the `data` parameter

## MULTI-PART QUESTIONS:
If the user asks multiple questions, handle each separately:
1. Answer the first question completely (query + suggest_chart)
2. Then answer the second question (with its own query + suggest_chart)
3. Call suggest_chart for EACH dataset that should be visualised

## Rules:
- NEVER guess table names. Always call list_tables first.
- Read dataset limitations carefully - if a dataset can't answer the question, use web_search
- Use LIMIT for exploration queries
- Only SELECT statements allowed
- ALWAYS call suggest_chart after getting query results with 2+ rows
- Summarise findings in 2-3 sentences after presenting data"""

# -----------------------------------------------------------------------------
# Graph Nodes
# -----------------------------------------------------------------------------

llm_with_tools = llm.bind_tools(ALL_TOOLS)


async def agent_node(state: DataAnalystState) -> dict:
    """LLM decides: call tool or respond."""
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
    """Extract chart configs from suggest_chart tool calls."""
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
# Chart Rendering
# -----------------------------------------------------------------------------


def render_chart(chart_config: dict) -> None:
    """Render a single chart using Plotly based on LLM-provided config."""
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
