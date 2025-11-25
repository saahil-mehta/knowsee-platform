# LangGraph + Vercel AI SDK Integration
  ┌─────────────────────────────────────────────────────────────────┐
  │                         Browser                                  │
  │  useChat() hook → sends POST to /api/chat                       │
  └─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                    Next.js (port 3001)                          │
  │  next.config.ts rewrites /api/chat → http://127.0.0.1:8000     │
  └─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                    FastAPI (port 8000)                          │
  │  backend/src/app.py → receives request                          │
  │  backend/src/stream.py → streams SSE events                     │
  │  backend/src/graph.py → LangGraph + ChatVertexAI (Gemini 2.5)  │
  └─────────────────────────────────────────────────────────────────┘

The Streaming Protocol:
  data: {"type":"start","messageId":"msg-xxx"}
  data: {"type":"text-start","id":"text-1"}
  data: {"type":"text-delta","id":"text-1","delta":"Hello"}
  data: {"type":"text-end","id":"text-1"}
  data: {"type":"finish","messageMetadata":{"finishReason":"stop"}}
  data: [DONE]


This document explains how the Python LangGraph backend integrates with the Next.js frontend using the Vercel AI SDK Data Stream Protocol.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [The Vercel AI SDK Data Stream Protocol](#the-vercel-ai-sdk-data-stream-protocol)
3. [Frontend Flow](#frontend-flow)
4. [Backend Flow](#backend-flow)
5. [Message Format Conversion](#message-format-conversion)
6. [How Streaming Works](#how-streaming-works)
7. [Key Files Reference](#key-files-reference)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BROWSER                                         │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ React Component (chat.tsx)                                           │    │
│  │                                                                       │    │
│  │  useChat({                                                           │    │
│  │    transport: new DefaultChatTransport({ api: "/api/chat" }),        │    │
│  │    onData: (dataPart) => { /* handle streaming events */ },          │    │
│  │  })                                                                  │    │
│  │                                                                       │    │
│  │  Returns: { messages, sendMessage, status, stop }                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                      │                                       │
│                                      │ POST /api/chat                        │
│                                      │ Body: { id, message, selectedModel }  │
│                                      ▼                                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       │ HTTP Request
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         NEXT.JS SERVER (port 3000/3001)                      │
│                                                                              │
│  next.config.ts:                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ async rewrites() {                                                   │    │
│  │   return [{                                                          │    │
│  │     source: "/api/chat",                                             │    │
│  │     destination: "http://127.0.0.1:8000/api/chat"  // Python backend│    │
│  │   }]                                                                 │    │
│  │ }                                                                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                      │                                       │
│                                      │ Proxied Request (same body)           │
│                                      ▼                                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       │ HTTP Request to localhost:8000
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FASTAPI SERVER (port 8000)                           │
│                                                                              │
│  backend/src/app.py:                                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ @app.post("/api/chat")                                               │    │
│  │ async def chat_stream(request: StreamingChatRequest):                │    │
│  │     messages = [request.message.model_dump()]                        │    │
│  │     return create_streaming_response(messages)                       │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                      │                                       │
│                                      ▼                                       │
│  backend/src/stream.py:                                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ def stream_langgraph_response(messages):                             │    │
│  │     yield format_sse({"type": "start", ...})                         │    │
│  │     for event in chatbot_graph.stream(...):                          │    │
│  │         yield format_sse({"type": "text-delta", "delta": chunk})     │    │
│  │     yield format_sse({"type": "finish", ...})                        │    │
│  │     yield "data: [DONE]\n\n"                                         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                      │                                       │
│                                      ▼                                       │
│  backend/src/graph.py:                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ llm = ChatVertexAI(model="gemini-2.5-flash", project=..., location=.)│    │
│  │                                                                       │    │
│  │ graph: START → chatbot_node → END                                    │    │
│  │                                                                       │    │
│  │ def chatbot_node(state):                                             │    │
│  │     response = llm.invoke(state["messages"])                         │    │
│  │     return {"messages": [response]}                                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                      │                                       │
│                                      │ gRPC to Vertex AI                     │
│                                      ▼                                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    GOOGLE VERTEX AI (europe-west2)                           │
│                                                                              │
│  Gemini 2.5 Flash model processes the request                               │
│  Returns response (currently non-streaming from Vertex)                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## The Vercel AI SDK Data Stream Protocol

The protocol uses **Server-Sent Events (SSE)** - a standard for streaming text data over HTTP.

### SSE Format

Each event is a line starting with `data: ` followed by JSON, ending with `\n\n`:

```
data: {"type":"start","messageId":"msg-abc123"}\n\n
data: {"type":"text-delta","id":"text-1","delta":"Hello"}\n\n
data: [DONE]\n\n
```

### Event Types

| Event | When Sent | Payload |
|-------|-----------|---------|
| `start` | Beginning of response | `{"type":"start","messageId":"msg-xxx"}` |
| `text-start` | Before first text chunk | `{"type":"text-start","id":"text-1"}` |
| `text-delta` | Each text chunk | `{"type":"text-delta","id":"text-1","delta":"Hello "}` |
| `text-end` | After last text chunk | `{"type":"text-end","id":"text-1"}` |
| `tool-input-start` | Tool call begins | `{"type":"tool-input-start","toolCallId":"..","toolName":".."}` |
| `tool-input-delta` | Tool args streaming | `{"type":"tool-input-delta","toolCallId":"..","inputTextDelta":".."}` |
| `tool-input-available` | Tool args complete | `{"type":"tool-input-available","toolCallId":"..","input":{...}}` |
| `tool-output-available` | Tool result ready | `{"type":"tool-output-available","toolCallId":"..","output":{...}}` |
| `finish` | Response complete | `{"type":"finish","messageMetadata":{"finishReason":"stop"}}` |
| `[DONE]` | Stream terminated | Literal string `[DONE]` |

### Required HTTP Headers

```python
response.headers["x-vercel-ai-ui-message-stream"] = "v1"  # Protocol version
response.headers["x-vercel-ai-protocol"] = "data"         # Protocol type
response.headers["Cache-Control"] = "no-cache"            # Prevent caching
response.headers["Connection"] = "keep-alive"             # Keep connection open
response.headers["X-Accel-Buffering"] = "no"              # Disable nginx buffering
```

### Event Lifecycle (Simple Text Response)

```
1. Client sends POST /api/chat
2. Server opens SSE connection
3. Server emits:
   ├── start          → Frontend creates new message placeholder
   ├── text-start     → Frontend knows text is coming
   ├── text-delta*    → Frontend appends each chunk to message
   ├── text-end       → Frontend knows text is complete
   ├── finish         → Frontend updates message metadata
   └── [DONE]         → Frontend closes connection
```

### Event Lifecycle (With Tool Calls)

```
1. Client sends POST /api/chat
2. Server emits:
   ├── start
   ├── tool-input-start     → Frontend shows "Calling tool..."
   ├── tool-input-delta*    → Frontend shows tool arguments building
   ├── tool-input-available → Frontend shows complete tool input
   ├── tool-output-available→ Frontend shows tool result
   ├── text-start           → LLM responds with tool results
   ├── text-delta*
   ├── text-end
   ├── finish
   └── [DONE]
```

---

## Frontend Flow

### 1. useChat Hook (chat.tsx)

```typescript
const {
  messages,      // Array of chat messages
  sendMessage,   // Function to send a message
  status,        // "idle" | "submitted" | "streaming"
  stop,          // Function to cancel streaming
} = useChat({
  id: chatId,
  transport: new DefaultChatTransport({
    api: "/api/chat",
    prepareSendMessagesRequest(request) {
      return {
        body: {
          id: request.id,
          message: request.messages.at(-1),  // Only send latest message
          selectedChatModel: currentModelId,
        },
      };
    },
  }),
  onData: (dataPart) => {
    // Called for each SSE event
    // dataPart.type === "text-delta" | "tool-..." | etc.
  },
});
```

### 2. Request Body Format

```typescript
// What the frontend sends:
{
  "id": "chat-uuid-here",
  "message": {
    "role": "user",
    "parts": [
      { "type": "text", "text": "Hello, how are you?" }
    ]
  },
  "selectedChatModel": "chat-model"
}
```

### 3. Message Parts Structure

Messages can have multiple parts:

```typescript
interface MessagePart {
  type: "text" | "file" | "tool-{toolName}";

  // For text parts:
  text?: string;

  // For file parts:
  contentType?: string;
  url?: string;

  // For tool parts:
  toolCallId?: string;
  toolName?: string;
  state?: "input-available" | "output-available";
  input?: any;
  output?: any;
}
```

---

## Backend Flow

### 1. FastAPI Endpoint (app.py)

```python
@app.post("/api/chat")
async def chat_stream(request: StreamingChatRequest) -> StreamingResponse:
    # Extract message from request
    messages = [request.message.model_dump()]

    # Return streaming response with proper headers
    return create_streaming_response(messages)
```

### 2. Stream Generator (stream.py)

```python
def stream_langgraph_response(messages):
    message_id = f"msg-{uuid.uuid4().hex}"
    text_stream_id = "text-1"

    # 1. Emit start event
    yield format_sse({"type": "start", "messageId": message_id})

    # 2. Convert messages to LangGraph format
    langgraph_messages = convert_to_langgraph_messages(messages)

    # 3. Stream from LangGraph
    for event in chatbot_graph.stream(
        {"messages": langgraph_messages},
        stream_mode="messages",
    ):
        if isinstance(event[0], AIMessageChunk):
            content = event[0].content
            if content:
                if not text_started:
                    yield format_sse({"type": "text-start", "id": text_stream_id})
                    text_started = True
                yield format_sse({
                    "type": "text-delta",
                    "id": text_stream_id,
                    "delta": content,
                })

    # 4. Emit end events
    yield format_sse({"type": "text-end", "id": text_stream_id})
    yield format_sse({"type": "finish", "messageMetadata": {"finishReason": "stop"}})
    yield "data: [DONE]\n\n"
```

### 3. LangGraph Graph (graph.py)

```python
class ChatState(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]

def create_chatbot_graph():
    llm = ChatVertexAI(
        model="gemini-2.5-flash",
        project=os.getenv("GOOGLE_CLOUD_PROJECT"),
        location=os.getenv("GOOGLE_CLOUD_LOCATION"),
    )

    def chatbot_node(state: ChatState) -> ChatState:
        response = llm.invoke(state["messages"])
        return {"messages": [response]}

    graph = StateGraph(ChatState)
    graph.add_node("chatbot", chatbot_node)
    graph.add_edge(START, "chatbot")
    graph.add_edge("chatbot", END)

    return graph.compile()
```

---

## Message Format Conversion

### Frontend → Backend

```
Frontend (Vercel AI SDK)          →    Backend (LangGraph)
─────────────────────────────────────────────────────────
{                                       HumanMessage(
  role: "user",                           content="Hello"
  parts: [                              )
    { type: "text", text: "Hello" }
  ]
}
```

### Backend → Frontend

```
Backend (LangGraph)               →    Frontend (SSE Events)
─────────────────────────────────────────────────────────
AIMessage(                              data: {"type":"text-delta",
  content="Hi there!"                          "delta":"Hi there!"}
)
```

---

## How Streaming Works

### HTTP Level

1. **Request**: Normal POST with JSON body
2. **Response**: `Content-Type: text/event-stream`
3. **Connection**: Kept open until `[DONE]`
4. **Data**: Streamed as chunks, not buffered

### Browser Level

The `useChat` hook uses the Fetch API with streaming:

```typescript
const response = await fetch("/api/chat", {
  method: "POST",
  body: JSON.stringify(payload),
});

const reader = response.body.getReader();
const decoder = new TextDecoder();

while (true) {
  const { done, value } = await reader.read();
  if (done) break;

  const chunk = decoder.decode(value);
  // Parse SSE events from chunk
  // Update React state with new content
}
```

### Why SSE Instead of WebSockets?

| SSE | WebSockets |
|-----|------------|
| Simpler (HTTP-based) | More complex (separate protocol) |
| One-way (server → client) | Bidirectional |
| Auto-reconnect built-in | Manual reconnect needed |
| Works with HTTP/2 | Separate connection |
| Perfect for streaming LLM responses | Overkill for this use case |

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `pyproject.toml` | Python dependencies |
| `backend/src/graph.py` | LangGraph chatbot definition |
| `backend/src/stream.py` | SSE streaming + protocol conversion |
| `backend/src/app.py` | FastAPI endpoints |
| `frontend/next.config.ts` | API proxy rewrite |
| `frontend/components/chat.tsx` | React chat component |
| `frontend/lib/ai/models.ts` | Model definitions |
| `frontend/lib/ai/providers.ts` | Model provider (for local validation) |

---

## Current Limitations

1. **No conversation history**: Backend doesn't persist to PostgreSQL
2. **No tool support**: Stream adapter doesn't emit tool events yet
3. **Non-chunked from Vertex**: Gemini returns full response, not token-by-token
4. **Single message context**: Each request is stateless

---

## Next Steps

To add conversation history persistence:
- **Option A (Hybrid)**: Keep Next.js API route for DB ops, forward to Python for inference
- **Option B (Full Python)**: Add SQLAlchemy/asyncpg to Python backend

To add tool support:
- Extend `stream.py` to emit tool-* events
- Add tools to `graph.py` using `llm.bind_tools()`
