"""FastAPI application exposing the LangGraph chatbot."""

from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from langchain_core.messages import AIMessage, HumanMessage
from pydantic import BaseModel

from backend.src.api import router as db_router
from backend.src.graph import chatbot_graph
from backend.src.stream import create_streaming_response

app = FastAPI(
    title="Knowsee Chatbot API",
    description="Simple LangGraph chatbot powered by Gemini 2.5 Flash",
    version="0.1.0",
)

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
    message: ChatMessage
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


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy"}


@app.post("/api/chat")
async def chat_stream(request: StreamingChatRequest) -> StreamingResponse:
    """Process a chat message and stream the response.

    This endpoint implements the Vercel AI SDK Data Stream Protocol.

    Args:
        request: Chat request from the frontend.

    Returns:
        StreamingResponse with SSE-formatted events.
    """
    # Convert the message to the format expected by the stream handler
    messages = [request.message.model_dump()]

    return create_streaming_response(messages)


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

        return SimpleChatResponse(response=ai_messages[-1].content)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing request: {str(e)}") from e
