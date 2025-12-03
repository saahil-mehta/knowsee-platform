# Data Analyst Agent Blueprint

Build incrementally. Each phase is testable independently. Don't move on until the current phase works.

---

## Phase 1: Single Agent + BigQuery

**Goal:** Agent can query BigQuery and return structured results.

**Files:**
```
backend/src/agents/data_analyst/
├── __init__.py
├── agent.py      # Graph definition
├── tools.py      # BQ tools only
├── prompts.py    # System prompt
└── state.py      # TypedDict state
```

**Tools (4 only):**
```python
DATA_ANALYST_TOOLS = [
    list_datasets,      # Show available datasets
    list_tables,        # Show tables in dataset
    get_table_schema,   # Show columns
    execute_query,      # Run SQL, return JSON
]
```

**Graph:**
```
START → agent → tools → agent → ... → END
```

**Test:**
```python
result = await agent.ainvoke({"messages": [HumanMessage("Top 5 baby names in 2020")]})
assert "rows" in result  # Got data back
```

**Done when:** Agent correctly queries BQ for 5+ different questions.

---

## Phase 2: Chart Streaming to Frontend

**Goal:** Charts render in the Next.js frontend.

**Backend changes:**
```python
# In stream.py - add chart data part
async def stream_chart(chart_config: dict):
    await stream.write_data({
        "type": "chart",
        "chartType": chart_config["chart_type"],
        "title": chart_config["title"],
        "xAxis": chart_config["x"],
        "yAxis": chart_config["y"],
        "data": chart_config["data"],
    })
```

**Frontend changes:**
```
frontend/components/
├── inline-chart.tsx      # Recharts wrapper
└── data-stream-handler.tsx  # Handle chart data parts
```

**inline-chart.tsx:**
```tsx
export function InlineChart({ chartType, title, xAxis, yAxis, data }) {
  const ChartComponent = {
    line: LineChart,
    bar: BarChart,
    pie: PieChart,
  }[chartType] || BarChart;

  return (
    <ChartComponent data={data}>
      <XAxis dataKey={xAxis} />
      <YAxis />
      <Tooltip />
      <Bar dataKey={yAxis} /> {/* or Line, etc */}
    </ChartComponent>
  );
}
```

**Test:**
```
1. Send "Plot top 10 baby names" from UI
2. Chart appears inline in chat
```

**Done when:** 3+ chart types render correctly (line, bar, pie).

---

## Phase 3: Reject + Redirect Pattern 

**Goal:** Agent offers options when it can't answer from BigQuery.

**State additions:**
```python
class DataAnalystState(TypedDict, total=False):
    messages: Annotated[list, add_messages]
    iteration_count: int
    charts: list[dict]
    # New fields
    pending_web_query: str | None
    show_options: bool
    options: list[dict]
```

**Prompt update:**
```python
DATA_ANALYST_PROMPT = """...
## WHEN YOU CANNOT ANSWER:
If the question cannot be answered with BigQuery data, respond with:
"I can't find this in the available BigQuery datasets. Would you like me to search the web instead?"
..."""
```

**Backend - detect and attach options:**
```python
async def data_analyst_node(state):
    response = await llm.ainvoke(messages)
    result = {"messages": [response]}

    # If agent couldn't answer, offer options
    if "can't find" in response.content.lower():
        result["show_options"] = True
        result["options"] = [
            {"action": "__ACTION__:WEB_SEARCH", "label": "Search the web"},
            {"action": "__ACTION__:REFINE", "label": "Ask differently"},
        ]
        result["pending_web_query"] = original_question

    return result
```

**Frontend - render options:**
```tsx
// In message.tsx or data-stream-handler.tsx
if (data.show_options) {
  return (
    <div className="flex gap-2 mt-2">
      {data.options.map(opt => (
        <Button
          key={opt.action}
          variant="outline"
          onClick={() => sendMessage(opt.action)}
        >
          {opt.label}
        </Button>
      ))}
    </div>
  );
}
```

**Test:**
```
1. Ask "What are AI trends for 2025?"
2. Agent says "I can't find this..." + shows [Search web] [Ask differently] buttons
3. Buttons are clickable
```

**Done when:** Options appear for 3+ "unanswerable" questions.

---

## Phase 4: Router + Web Search Agent 

**Goal:** Clicking "Search web" actually searches and returns results.

**New files:**
```
backend/src/agents/
├── data_analyst/    # Existing
├── web_search/      # New
│   ├── agent.py
│   ├── tools.py     # web_search tool
│   └── prompts.py
└── router.py        # Intent classification
```

**Router logic:**
```python
ACTION_PREFIX = "__ACTION__:"

def detect_intent(message: str) -> str:
    if message.startswith(f"{ACTION_PREFIX}WEB_SEARCH"):
        return "web_search"
    if message.strip().lower() in ["hi", "hello", "help"]:
        return "chat"
    return "data_analyst"
```

**Production graph:**
```python
def build_graph():
    graph = StateGraph(State)

    graph.add_node("router", router_node)
    graph.add_node("data_analyst", data_analyst_node)
    graph.add_node("web_search", web_search_node)
    graph.add_node("data_analyst_tools", ToolNode(DATA_ANALYST_TOOLS))
    graph.add_node("web_search_tools", ToolNode(WEB_SEARCH_TOOLS))

    graph.set_entry_point("router")

    graph.add_conditional_edges("router", route_by_intent, {
        "data_analyst": "data_analyst",
        "web_search": "web_search",
    })

    # ... tool loops for each agent

    return graph.compile()
```

**Test the full flow:**
```
1. "What are AI trends?" → Data analyst → "Can't find" + [Search web]
2. Click [Search web] → "__ACTION__:WEB_SEARCH" sent
3. Router → web_search agent → DuckDuckGo → results displayed
```

**Done when:** Full redirect flow works end-to-end.

---

## Phase 5: Production Hardening 

**Goal:** Ready for real users.

### 5a. Persistence
```python
class DataAnalystState(TypedDict, total=False):
    # Add
    user_id: str
    chat_id: str

# Save to DB after each response
async def save_message(chat_id: str, message: Message):
    await db.execute(
        "INSERT INTO messages (chat_id, role, content) VALUES ($1, $2, $3)",
        chat_id, message.role, message.content
    )
```

### 5b. Cost tracking
```python
@tool
def execute_query(sql: str) -> dict:
    result = bq_client.query(sql)
    return {
        "rows": rows,
        "bytes_processed": result.total_bytes_processed,  # Track this
    }

# Aggregate per user for billing alerts
```

### 5c. Error handling
```python
async def data_analyst_node(state):
    try:
        response = await llm.ainvoke(messages)
    except Exception as e:
        logger.error("Agent failed", error=str(e))
        return {
            "messages": [AIMessage(content="Sorry, I encountered an error. Please try again.")],
            "error": str(e),
        }
```

### 5d. Observability
```python
# Structured logging
logger.info("Agent response",
    intent=state.get("detected_intent"),
    tool_calls=[tc.name for tc in response.tool_calls],
    bytes_processed=state.get("bytes_processed"),
)

# Trace IDs for debugging
```

### 5e. Rate limiting
```python
# In FastAPI middleware
@app.middleware("http")
async def rate_limit(request, call_next):
    user_id = get_user_id(request)
    if await is_rate_limited(user_id):
        raise HTTPException(429, "Too many requests")
    return await call_next(request)
```

---

## File Structure (Final)

```
backend/src/
├── agents/
│   ├── __init__.py
│   ├── router.py              # Intent classification
│   ├── state.py               # Shared state TypedDict
│   ├── data_analyst/
│   │   ├── __init__.py
│   │   ├── agent.py           # Graph + nodes
│   │   ├── tools.py           # BQ tools
│   │   └── prompts.py
│   └── web_search/
│       ├── __init__.py
│       ├── agent.py
│       ├── tools.py           # DuckDuckGo
│       └── prompts.py
├── stream.py                  # Vercel AI SDK streaming
└── app.py                     # FastAPI routes

frontend/
├── components/
│   ├── inline-chart.tsx       # Recharts wrapper
│   ├── action-buttons.tsx     # Option buttons
│   └── data-stream-handler.tsx
└── lib/
    └── actions.ts             # Action constants
```

---

## Quick Reference: What Each Phase Delivers

| Phase | Deliverable | Test |
|-------|-------------|------|
| 1 | BQ queries work | "Top 5 names" returns data |
| 2 | Charts render | Line/bar/pie show in UI |
| 3 | Options appear | "Can't find" shows buttons |
| 4 | Redirect works | Click [Search web] → results |
| 5 | Production ready | Handles errors, tracks costs |

---

## Anti-Patterns to Avoid

1. **Don't build the router before Phase 4** — You don't need it until you have 2+ agents
2. **Don't add web_search to data_analyst** — Keep tools separate per agent
3. **Don't parse natural language for approval** — Use action prefixes
4. **Don't accumulate charts in state** — Stream them as data parts
5. **Don't skip error handling** — LLMs fail, BQ times out, networks drop

---

## Commands to Test Each Phase

```bash
# Phase 1: Direct agent test
cd backend && python -c "
from agents.data_analyst import agent
import asyncio
asyncio.run(agent.ainvoke({'messages': [('human', 'Top 5 names')]}))
"

# Phase 2: Frontend test
cd frontend && pnpm dev
# Open localhost:3000, send "Plot top 10 baby names"

# Phase 3: Options test
# Send "What are AI trends?" - should see buttons

# Phase 4: Full flow test
# Click [Search web] button - should get web results

# Phase 5: Load test
# wrk -t4 -c100 -d30s http://localhost:8000/api/chat
```

---

Start with Phase 1. Don't skip ahead.
