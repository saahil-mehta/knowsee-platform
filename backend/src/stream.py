"""Vercel AI SDK Data Stream Protocol implementation for LangGraph."""

import json
import uuid
from typing import Any, Generator

from fastapi.responses import StreamingResponse
from langchain_core.messages import AIMessageChunk, BaseMessage, HumanMessage

from backend.src.graph import chatbot_graph


def format_sse(payload: dict) -> str:
    """Format a payload as a Server-Sent Event."""
    return f"data: {json.dumps(payload, separators=(',', ':'))}\n\n"


def stream_langgraph_response(
    messages: list[dict[str, Any]],
) -> Generator[str, None, None]:
    """Stream LangGraph responses using Vercel AI SDK Data Stream Protocol.

    Args:
        messages: List of message dicts with 'role' and 'content'/'parts'.

    Yields:
        SSE formatted strings for the Vercel AI SDK.
    """
    message_id = f"msg-{uuid.uuid4().hex}"
    text_stream_id = "text-1"
    text_started = False

    # Emit start event
    yield format_sse({"type": "start", "messageId": message_id})

    # Convert messages to LangGraph format
    langgraph_messages = convert_to_langgraph_messages(messages)

    # Stream from LangGraph
    accumulated_content = ""

    try:
        for event in chatbot_graph.stream(
            {"messages": langgraph_messages},
            stream_mode="messages",
        ):
            # event is a tuple of (message_chunk, metadata)
            if isinstance(event, tuple) and len(event) >= 1:
                message_chunk = event[0]

                if isinstance(message_chunk, AIMessageChunk):
                    content = message_chunk.content

                    # Handle content which can be str or list
                    if content:
                        content_str = content if isinstance(content, str) else str(content)
                        if not text_started:
                            yield format_sse({"type": "text-start", "id": text_stream_id})
                            text_started = True

                        yield format_sse(
                            {
                                "type": "text-delta",
                                "id": text_stream_id,
                                "delta": content_str,
                            }
                        )
                        accumulated_content += content_str

        # End text stream
        if text_started:
            yield format_sse({"type": "text-end", "id": text_stream_id})

        # Emit finish event
        yield format_sse(
            {
                "type": "finish",
                "messageMetadata": {
                    "finishReason": "stop",
                },
            }
        )

    except Exception as e:
        # Handle errors gracefully
        if not text_started:
            yield format_sse({"type": "text-start", "id": text_stream_id})

        yield format_sse(
            {
                "type": "text-delta",
                "id": text_stream_id,
                "delta": f"Error: {str(e)}",
            }
        )
        yield format_sse({"type": "text-end", "id": text_stream_id})
        yield format_sse(
            {
                "type": "finish",
                "messageMetadata": {"finishReason": "error"},
            }
        )

    # Signal end of stream
    yield "data: [DONE]\n\n"


def convert_to_langgraph_messages(messages: list[dict[str, Any]]) -> list[BaseMessage]:
    """Convert frontend message format to LangGraph messages.

    Args:
        messages: List of message dicts from the frontend.

    Returns:
        List of LangChain BaseMessage objects.
    """
    langgraph_messages: list[BaseMessage] = []

    for msg in messages:
        role = msg.get("role", "user")
        content = ""

        # Extract content from parts or content field
        if "parts" in msg and msg["parts"]:
            for part in msg["parts"]:
                if part.get("type") == "text":
                    content += part.get("text", "")
        elif "content" in msg:
            content = msg["content"]

        if role == "user":
            langgraph_messages.append(HumanMessage(content=content))
        # Skip assistant messages for now (we're generating new ones)

    return langgraph_messages


def create_streaming_response(messages: list[dict[str, Any]]) -> StreamingResponse:
    """Create a FastAPI StreamingResponse with proper headers.

    Args:
        messages: List of message dicts from the frontend.

    Returns:
        StreamingResponse configured for Vercel AI SDK.
    """
    response = StreamingResponse(
        stream_langgraph_response(messages),
        media_type="text/event-stream",
    )

    # Set required headers for Vercel AI SDK
    response.headers["x-vercel-ai-ui-message-stream"] = "v1"
    response.headers["x-vercel-ai-protocol"] = "data"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Connection"] = "keep-alive"
    response.headers["X-Accel-Buffering"] = "no"

    return response
