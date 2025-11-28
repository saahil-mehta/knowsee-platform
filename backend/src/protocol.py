"""AI SDK v5 Protocol formatting for streaming responses.

Lifted and simplified from langchain_aisdk_adapter.
Implements the Vercel AI SDK UI Message Stream Protocol v1.
"""

import json
from typing import Any


def format_sse(payload: dict[str, Any]) -> str:
    """Format a payload as a Server-Sent Event for AI SDK v5."""
    return f"data: {json.dumps(payload, separators=(',', ':'), ensure_ascii=False)}\n\n"


def create_start_event(message_id: str) -> str:
    """Create stream start event."""
    return format_sse({"type": "start", "messageId": message_id})


def create_start_step_event(step_id: str) -> str:
    """Create step start event."""
    return format_sse({"type": "start-step", "messageId": step_id})


def create_text_start(text_id: str) -> str:
    """Create text stream start event."""
    return format_sse({"type": "text-start", "id": text_id})


def create_text_delta(text_id: str, delta: str) -> str:
    """Create text delta event."""
    return format_sse({"type": "text-delta", "id": text_id, "delta": delta})


def create_text_end(text_id: str) -> str:
    """Create text stream end event."""
    return format_sse({"type": "text-end", "id": text_id})


def create_finish_step_event(
    finish_reason: str = "stop",
    usage: dict[str, int] | None = None,
) -> str:
    """Create step finish event."""
    return format_sse(
        {
            "type": "finish-step",
            "finishReason": finish_reason,
            "usage": usage or {"promptTokens": 0, "completionTokens": 0},
            "isContinued": False,
        }
    )


def create_finish_event(
    finish_reason: str = "stop",
    usage: dict[str, int] | None = None,
) -> str:
    """Create stream finish event."""
    return format_sse(
        {
            "type": "finish",
            "finishReason": finish_reason,
            "usage": usage or {"promptTokens": 0, "completionTokens": 0},
        }
    )


def create_error_event(error_text: str) -> str:
    """Create error event."""
    return format_sse({"type": "error", "errorText": error_text})


def create_done_marker() -> str:
    """Create stream termination marker."""
    return "data: [DONE]\n\n"


# Tool-related events for future use
def create_tool_input_start(tool_call_id: str, tool_name: str) -> str:
    """Create tool input start event."""
    return format_sse(
        {
            "type": "tool-input-start",
            "toolCallId": tool_call_id,
            "toolName": tool_name,
        }
    )


def create_tool_input_delta(tool_call_id: str, delta: str) -> str:
    """Create tool input delta event."""
    return format_sse(
        {
            "type": "tool-input-delta",
            "toolCallId": tool_call_id,
            "inputTextDelta": delta,
        }
    )


def create_tool_input_available(
    tool_call_id: str,
    tool_name: str,
    tool_input: Any,
) -> str:
    """Create tool input available event."""
    return format_sse(
        {
            "type": "tool-input-available",
            "toolCallId": tool_call_id,
            "toolName": tool_name,
            "input": tool_input,
        }
    )


def create_tool_output_available(tool_call_id: str, output: Any) -> str:
    """Create tool output available event."""
    return format_sse(
        {
            "type": "tool-output-available",
            "toolCallId": tool_call_id,
            "output": output,
        }
    )


# Response headers for AI SDK v5
AISDK_V5_HEADERS = {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
    "X-Accel-Buffering": "no",
    "x-vercel-ai-ui-message-stream": "v1",
}
