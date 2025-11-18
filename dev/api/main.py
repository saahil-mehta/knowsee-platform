"""
FastAPI Mock Server for GPT-OSS-120B Development
Provides streaming chat responses for local development
"""

import asyncio
import json
import os
import time
from collections.abc import AsyncGenerator
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

app = FastAPI(title="Knowsee Mock API", version="1.0.0")

# CORS configuration for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Request/Response Models
class Message(BaseModel):
    role: str  # "user" or "assistant"
    content: str
    timestamp: float | None = None


class ChatRequest(BaseModel):
    messages: list[Message]
    stream: bool = True
    temperature: float = 0.7
    max_tokens: int = 2048


class ChatResponse(BaseModel):
    id: str
    choices: list[dict]
    model: str = "gpt-oss-120b"
    created: int


# Configuration
MOCK_DELAY_MS = int(os.getenv("MOCK_DELAY_MS", "50"))  # Delay between tokens
STREAMING_ENABLED = os.getenv("STREAMING_ENABLED", "true").lower() == "true"


# Mock responses for different queries
MOCK_RESPONSES = {
    "default": """I'm a mock GPT-OSS-120B model running in your development environment.

This response is being streamed token-by-token to simulate real model behavior. You can configure the streaming delay in the .env file by adjusting MOCK_DELAY_MS.

In production, I'll be replaced with the actual GPT-OSS-120B model hosted on Vertex AI.""",
    "hello": "Hello! I'm the Knowsee chat assistant. How can I help you today?",
    "help": """I can assist you with various tasks:

1. Answer questions and provide information
2. Help with code and technical problems
3. Analyze documents you upload
4. Have conversations and remember context

What would you like to explore?""",
    "test": "Test successful! The streaming is working correctly. ✓",
}


def get_mock_response(user_message: str) -> str:
    """
    Return appropriate mock response based on user input
    """
    message_lower = user_message.lower().strip()

    if any(greeting in message_lower for greeting in ["hello", "hi", "hey"]):
        return MOCK_RESPONSES["hello"]
    elif "help" in message_lower:
        return MOCK_RESPONSES["help"]
    elif "test" in message_lower:
        return MOCK_RESPONSES["test"]
    else:
        return MOCK_RESPONSES["default"]


async def generate_stream_response(content: str) -> AsyncGenerator[str, None]:
    """
    Stream response token-by-token
    """
    request_id = f"mock-{int(time.time())}"

    # Split content into tokens (words and punctuation)
    tokens = []
    current_token = ""
    for char in content:
        current_token += char
        if char in [" ", "\n", ".", ",", "!", "?", ":", ";"]:
            tokens.append(current_token)
            current_token = ""
    if current_token:
        tokens.append(current_token)

    # Stream each token
    for i, token in enumerate(tokens):
        chunk = {
            "id": request_id,
            "object": "chat.completion.chunk",
            "created": int(time.time()),
            "model": "gpt-oss-120b-mock",
            "choices": [
                {
                    "index": 0,
                    "delta": {"content": token}
                    if i > 0
                    else {"role": "assistant", "content": token},
                    "finish_reason": None,
                }
            ],
        }

        yield f"data: {json.dumps(chunk)}\n\n"
        await asyncio.sleep(MOCK_DELAY_MS / 1000.0)

    # Send final chunk
    final_chunk = {
        "id": request_id,
        "object": "chat.completion.chunk",
        "created": int(time.time()),
        "model": "gpt-oss-120b-mock",
        "choices": [
            {
                "index": 0,
                "delta": {},
                "finish_reason": "stop",
            }
        ],
    }
    yield f"data: {json.dumps(final_chunk)}\n\n"
    yield "data: [DONE]\n\n"


@app.get("/")
async def root() -> dict[str, Any]:
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "Knowsee Mock API",
        "model": "gpt-oss-120b-mock",
        "streaming_enabled": STREAMING_ENABLED,
        "mock_delay_ms": MOCK_DELAY_MS,
    }


@app.get("/health")
async def health() -> dict[str, str]:
    """Health check for Docker"""
    return {"status": "healthy"}


@app.post("/v1/chat/completions")
async def chat_completions(request: ChatRequest) -> StreamingResponse | ChatResponse:
    """
    OpenAI-compatible chat completions endpoint
    Supports both streaming and non-streaming
    """
    if not request.messages:
        raise HTTPException(status_code=400, detail="Messages cannot be empty")

    # Get the last user message
    last_message = request.messages[-1]
    if last_message.role != "user":
        raise HTTPException(status_code=400, detail="Last message must be from user")

    # Generate response
    response_content = get_mock_response(last_message.content)

    # Return streaming response
    if request.stream and STREAMING_ENABLED:
        return StreamingResponse(
            generate_stream_response(response_content),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",  # Disable buffering in nginx
            },
        )

    # Return non-streaming response
    return ChatResponse(
        id=f"mock-{int(time.time())}",
        created=int(time.time()),
        model="gpt-oss-120b-mock",
        choices=[
            {
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": response_content,
                },
                "finish_reason": "stop",
            }
        ],
    )


@app.post("/v1/files/upload")
async def upload_file() -> dict[str, Any]:
    """
    Mock file upload endpoint
    """
    return {
        "id": f"file-mock-{int(time.time())}",
        "object": "file",
        "bytes": 1024,
        "created_at": int(time.time()),
        "filename": "mock-file.txt",
        "purpose": "assistants",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
