"""Vercel AI SDK Data Stream Protocol implementation for LangGraph.

Uses async astream_events() for proper event handling and tool visibility.
"""

import uuid
from collections.abc import AsyncGenerator
from typing import Any

from fastapi.responses import StreamingResponse
from langchain_core.messages import BaseMessage, HumanMessage

from backend.src.graph import chatbot_graph
from backend.src.protocol import (
    AISDK_V5_HEADERS,
    create_done_marker,
    create_error_event,
    create_finish_event,
    create_finish_step_event,
    create_start_event,
    create_start_step_event,
    create_text_delta,
    create_text_end,
    create_text_start,
)


async def stream_langgraph_response(
    messages: list[dict[str, Any]],
) -> AsyncGenerator[str, None]:
    """Stream LangGraph responses using Vercel AI SDK Data Stream Protocol v5.

    Uses astream_events() for proper event handling, enabling:
    - Incremental text streaming
    - Tool call visibility (for future agents)
    - Usage metadata extraction

    Args:
        messages: List of message dicts with 'role' and 'content'/'parts'.

    Yields:
        SSE formatted strings for the Vercel AI SDK.
    """
    message_id = f"msg-{uuid.uuid4().hex}"
    step_id = f"step-{uuid.uuid4().hex}"
    text_id = f"text-{uuid.uuid4().hex}"

    text_started = False
    usage = {"promptTokens": 0, "completionTokens": 0}

    # Convert messages to LangGraph format
    langgraph_messages = convert_to_langgraph_messages(messages)

    # Emit start events
    yield create_start_event(message_id)
    yield create_start_step_event(step_id)

    try:
        async for event in chatbot_graph.astream_events(
            {"messages": langgraph_messages},
            version="v2",
        ):
            event_type = event.get("event", "")

            # Handle text streaming from chat model
            if event_type == "on_chat_model_stream":
                chunk = event.get("data", {}).get("chunk")
                if chunk:
                    content = _extract_content(chunk)
                    if content:
                        if not text_started:
                            yield create_text_start(text_id)
                            text_started = True
                        yield create_text_delta(text_id, content)

            # Extract usage from chat model end
            elif event_type == "on_chat_model_end":
                output = event.get("data", {}).get("output")
                if output and hasattr(output, "usage_metadata"):
                    meta = output.usage_metadata
                    if isinstance(meta, dict):
                        usage["promptTokens"] = meta.get("input_tokens", 0)
                        usage["completionTokens"] = meta.get("output_tokens", 0)
                    else:
                        usage["promptTokens"] = getattr(meta, "input_tokens", 0)
                        usage["completionTokens"] = getattr(meta, "output_tokens", 0)

        # End text stream if started
        if text_started:
            yield create_text_end(text_id)

        # Emit finish events
        yield create_finish_step_event("stop", usage)
        yield create_finish_event("stop", usage)

    except Exception as e:
        # Handle errors gracefully
        if not text_started:
            yield create_text_start(text_id)
        yield create_text_delta(text_id, f"Error: {e!s}")
        yield create_text_end(text_id)
        yield create_error_event(str(e))
        yield create_finish_step_event("error", usage)
        yield create_finish_event("error", usage)

    # Signal end of stream
    yield create_done_marker()


def _extract_content(chunk: Any) -> str:
    """Extract text content from a LangChain message chunk."""
    if isinstance(chunk, dict):
        content = chunk.get("content", "")
    else:
        content = getattr(chunk, "content", "")

    if isinstance(content, str):
        return content

    # Handle complex content (list of parts)
    if hasattr(content, "__iter__") and not isinstance(content, str):
        text_parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                text_parts.append(item.get("text", ""))
        return "".join(text_parts)

    return ""


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


async def create_streaming_response(
    messages: list[dict[str, Any]],
) -> StreamingResponse:
    """Create a FastAPI StreamingResponse with proper headers.

    Args:
        messages: List of message dicts from the frontend.

    Returns:
        StreamingResponse configured for Vercel AI SDK v5.
    """
    return StreamingResponse(
        stream_langgraph_response(messages),
        media_type="text/event-stream",
        headers=AISDK_V5_HEADERS,
    )
