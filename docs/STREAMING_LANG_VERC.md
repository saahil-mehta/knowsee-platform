
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