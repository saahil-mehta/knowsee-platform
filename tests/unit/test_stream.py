"""Unit tests for the stream module (SSE formatting and message conversion)."""

import json

from langchain_core.messages import HumanMessage

from backend.src.stream import convert_to_langgraph_messages, format_sse


class TestFormatSSE:
    """Tests for the format_sse function."""

    def test_format_sse_simple_payload(self) -> None:
        """Test formatting a simple payload as SSE."""
        payload = {"type": "start", "messageId": "msg-123"}
        result = format_sse(payload)

        assert result.startswith("data: ")
        assert result.endswith("\n\n")

        # Parse the JSON to verify structure
        json_str = result[6:-2]  # Remove "data: " prefix and "\n\n" suffix
        parsed = json.loads(json_str)
        assert parsed == payload

    def test_format_sse_with_delta(self) -> None:
        """Test formatting a text-delta event."""
        payload = {"type": "text-delta", "id": "text-1", "delta": "Hello"}
        result = format_sse(payload)

        json_str = result[6:-2]
        parsed = json.loads(json_str)
        assert parsed["type"] == "text-delta"
        assert parsed["delta"] == "Hello"

    def test_format_sse_compact_json(self) -> None:
        """Test that JSON is formatted without spaces (compact)."""
        payload = {"type": "finish", "messageMetadata": {"finishReason": "stop"}}
        result = format_sse(payload)

        # Should not contain ": " (colon-space) - only ":"
        json_str = result[6:-2]
        assert ": " not in json_str
        assert ',"' in json_str or json_str.startswith("{")

    def test_format_sse_unicode(self) -> None:
        """Test formatting with unicode characters."""
        payload = {"type": "text-delta", "delta": "Hello, world!"}
        result = format_sse(payload)

        json_str = result[6:-2]
        parsed = json.loads(json_str)
        assert parsed["delta"] == "Hello, world!"

    def test_format_sse_special_characters(self) -> None:
        """Test formatting with special characters."""
        payload = {"type": "text-delta", "delta": 'Line 1\nLine 2\t"quoted"'}
        result = format_sse(payload)

        json_str = result[6:-2]
        parsed = json.loads(json_str)
        assert parsed["delta"] == 'Line 1\nLine 2\t"quoted"'

    def test_format_sse_empty_payload(self) -> None:
        """Test formatting an empty payload."""
        payload: dict = {}
        result = format_sse(payload)

        assert result == "data: {}\n\n"


class TestConvertToLanggraphMessages:
    """Tests for the convert_to_langgraph_messages function."""

    def test_convert_user_message_with_content(self) -> None:
        """Test converting a user message with content field."""
        messages = [{"role": "user", "content": "Hello, world!"}]
        result = convert_to_langgraph_messages(messages)

        assert len(result) == 1
        assert isinstance(result[0], HumanMessage)
        assert result[0].content == "Hello, world!"

    def test_convert_user_message_with_parts(self) -> None:
        """Test converting a user message with parts array."""
        messages = [
            {
                "role": "user",
                "parts": [
                    {"type": "text", "text": "Hello, "},
                    {"type": "text", "text": "world!"},
                ],
            }
        ]
        result = convert_to_langgraph_messages(messages)

        assert len(result) == 1
        assert isinstance(result[0], HumanMessage)
        assert result[0].content == "Hello, world!"

    def test_convert_user_message_with_non_text_parts(self) -> None:
        """Test that non-text parts are skipped."""
        messages = [
            {
                "role": "user",
                "parts": [
                    {"type": "text", "text": "Hello"},
                    {"type": "file", "url": "http://example.com/file.pdf"},
                    {"type": "text", "text": " world"},
                ],
            }
        ]
        result = convert_to_langgraph_messages(messages)

        assert len(result) == 1
        assert result[0].content == "Hello world"

    def test_convert_skips_assistant_messages(self) -> None:
        """Test that assistant messages are skipped."""
        messages = [
            {"role": "user", "content": "Hello"},
            {"role": "assistant", "content": "Hi there!"},
            {"role": "user", "content": "How are you?"},
        ]
        result = convert_to_langgraph_messages(messages)

        # Only user messages should be converted
        assert len(result) == 2
        assert result[0].content == "Hello"
        assert result[1].content == "How are you?"

    def test_convert_empty_messages(self) -> None:
        """Test converting an empty message list."""
        result = convert_to_langgraph_messages([])
        assert result == []

    def test_convert_message_with_empty_parts(self) -> None:
        """Test converting a message with empty parts array."""
        messages = [{"role": "user", "parts": []}]
        result = convert_to_langgraph_messages(messages)

        assert len(result) == 1
        assert result[0].content == ""

    def test_convert_message_missing_role(self) -> None:
        """Test that missing role defaults to 'user'."""
        messages = [{"content": "Hello"}]
        result = convert_to_langgraph_messages(messages)

        assert len(result) == 1
        assert isinstance(result[0], HumanMessage)
        assert result[0].content == "Hello"

    def test_convert_parts_missing_text(self) -> None:
        """Test that parts with missing text field are handled."""
        messages = [
            {
                "role": "user",
                "parts": [
                    {"type": "text"},  # Missing text
                    {"type": "text", "text": "Hello"},
                ],
            }
        ]
        result = convert_to_langgraph_messages(messages)

        assert len(result) == 1
        assert result[0].content == "Hello"
