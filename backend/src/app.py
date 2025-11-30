"""FastAPI application exposing the LangGraph chatbot."""

from typing import Any, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from langchain_core.messages import AIMessage, HumanMessage
from pydantic import BaseModel

from backend.src.api import router as db_router
from backend.src.db.config import check_db_health
from backend.src.graph import chatbot_graph, generate_title
from backend.src.observability.middleware import setup_observability
from backend.src.stream import create_streaming_response

app = FastAPI(
    title="Knowsee Chatbot API",
    description="Simple LangGraph chatbot powered by Vertex AI",
    version="0.1.0",
)

# Set up observability (logging, metrics, exception handlers)
setup_observability(app)

# CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include database API routes
app.include_router(db_router)


# Models for Vercel AI SDK compatibility
class MessagePart(BaseModel):
    """A part of a message (text, file, tool, etc.)."""

    type: str
    text: Optional[str] = None
    # Allow additional fields for tool parts, files, etc.

    class Config:
        extra = "allow"


class ChatMessage(BaseModel):
    """A chat message from the frontend."""

    role: str
    content: Optional[str] = None
    parts: Optional[list[MessagePart]] = None

    class Config:
        extra = "allow"


class StreamingChatRequest(BaseModel):
    """Request model for streaming chat endpoint (Vercel AI SDK format)."""

    id: str
    messages: list[ChatMessage]
    selectedChatModel: Optional[str] = None
    selectedVisibilityType: Optional[str] = None

    class Config:
        extra = "allow"


class SimpleChatRequest(BaseModel):
    """Request model for simple chat endpoint."""

    message: str


class SimpleChatResponse(BaseModel):
    """Response model for simple chat endpoint."""

    response: str


class TitleRequest(BaseModel):
    """Request model for title generation endpoint."""

    message: str


class TitleResponse(BaseModel):
    """Response model for title generation endpoint."""

    title: str


@app.get("/health")
async def health_liveness() -> dict[str, str]:
    """Liveness probe - checks if the application is running.

    This is a fast check with no external dependencies.
    Use for Kubernetes liveness probes.
    """
    return {"status": "healthy"}


@app.get("/health/live")
async def health_live() -> dict[str, str]:
    """Alias for liveness probe (Kubernetes convention)."""
    return {"status": "healthy"}


@app.get("/health/ready")
async def health_readiness() -> JSONResponse:
    """Readiness probe - checks if the application can serve traffic.

    Verifies:
    - Database connectivity with timeout

    Returns 200 if ready, 503 if not ready.
    """
    checks: dict[str, Any] = {}

    # Check database
    db_health = await check_db_health()
    checks["database"] = db_health

    # Determine overall status
    all_healthy = all(
        check.get("healthy", False) for check in checks.values() if isinstance(check, dict)
    )

    status_code = 200 if all_healthy else 503
    status = "ready" if all_healthy else "not_ready"

    return JSONResponse(
        status_code=status_code,
        content={
            "status": status,
            "checks": checks,
        },
    )


@app.post("/api/chat")
async def chat_stream(request: StreamingChatRequest) -> StreamingResponse:
    """Process a chat message and stream the response.

    This endpoint implements the Vercel AI SDK Data Stream Protocol v5.

    Args:
        request: Chat request from the frontend.

    Returns:
        StreamingResponse with SSE-formatted events.
    """
    # Convert messages to the format expected by the stream handler
    messages = [msg.model_dump() for msg in request.messages]

    return await create_streaming_response(messages)


@app.post("/chat", response_model=SimpleChatResponse)
async def chat_simple(request: SimpleChatRequest) -> SimpleChatResponse:
    """Process a chat message and return the response (non-streaming).

    Args:
        request: Chat request containing the user message.

    Returns:
        SimpleChatResponse with the AI-generated response.
    """
    try:
        result = chatbot_graph.invoke({"messages": [HumanMessage(content=request.message)]})

        ai_messages = [msg for msg in result["messages"] if isinstance(msg, AIMessage)]

        if not ai_messages:
            raise HTTPException(status_code=500, detail="No response generated")

        # Handle content which can be str or list
        content = ai_messages[-1].content
        response_text = content if isinstance(content, str) else str(content)
        return SimpleChatResponse(response=response_text)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing request: {str(e)}") from e


@app.post("/api/title", response_model=TitleResponse)
async def generate_chat_title(request: TitleRequest) -> TitleResponse:
    """Generate a title for a chat based on the first message.

    Args:
        request: Title request containing the user message.

    Returns:
        TitleResponse with the generated title.
    """
    title = await generate_title(request.message)
    return TitleResponse(title=title)
