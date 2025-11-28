"""Factory Boy factories for Knowsee Platform models.

These factories create test instances of database models.
Use them to generate realistic test data without hitting the database.
"""

from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

import factory

from backend.src.db.models import Chat, Document, Message, Stream, Suggestion, User, Vote


class UserFactory(factory.Factory):
    """Factory for creating User instances."""

    class Meta:
        model = User

    id = factory.LazyFunction(uuid4)
    email = factory.Sequence(lambda n: f"user{n}@example.com")
    password = factory.LazyFunction(lambda: "hashed_password")


class ChatFactory(factory.Factory):
    """Factory for creating Chat instances."""

    class Meta:
        model = Chat

    id = factory.LazyFunction(uuid4)
    createdAt = factory.LazyFunction(lambda: datetime.now(timezone.utc))
    title = factory.Sequence(lambda n: f"Test Chat {n}")
    userId = factory.LazyFunction(uuid4)
    visibility = "private"
    lastContext = None


class MessageFactory(factory.Factory):
    """Factory for creating Message instances."""

    class Meta:
        model = Message

    id = factory.LazyFunction(uuid4)
    chatId = factory.LazyFunction(uuid4)
    role = "user"
    parts = factory.LazyFunction(lambda: [{"type": "text", "text": "Test message"}])
    attachments = factory.LazyFunction(list)
    createdAt = factory.LazyFunction(lambda: datetime.now(timezone.utc))


class VoteFactory(factory.Factory):
    """Factory for creating Vote instances."""

    class Meta:
        model = Vote

    chatId = factory.LazyFunction(uuid4)
    messageId = factory.LazyFunction(uuid4)
    isUpvoted = True


class DocumentFactory(factory.Factory):
    """Factory for creating Document instances."""

    class Meta:
        model = Document

    id = factory.LazyFunction(uuid4)
    createdAt = factory.LazyFunction(lambda: datetime.now(timezone.utc))
    title = factory.Sequence(lambda n: f"Test Document {n}")
    content = "This is test document content."
    kind = "text"
    userId = factory.LazyFunction(uuid4)


class SuggestionFactory(factory.Factory):
    """Factory for creating Suggestion instances."""

    class Meta:
        model = Suggestion

    id = factory.LazyFunction(uuid4)
    documentId = factory.LazyFunction(uuid4)
    documentCreatedAt = factory.LazyFunction(lambda: datetime.now(timezone.utc))
    originalText = "Original text here"
    suggestedText = "Suggested replacement text"
    description = "Improvement suggestion"
    isResolved = False
    userId = factory.LazyFunction(uuid4)
    createdAt = factory.LazyFunction(lambda: datetime.now(timezone.utc))


class StreamFactory(factory.Factory):
    """Factory for creating Stream instances."""

    class Meta:
        model = Stream

    id = factory.LazyFunction(uuid4)
    chatId = factory.LazyFunction(uuid4)
    createdAt = factory.LazyFunction(lambda: datetime.now(timezone.utc))


def create_user_with_chat() -> tuple[User, Chat]:
    """Create a user with an associated chat."""
    user = UserFactory()
    chat = ChatFactory(userId=user.id)
    return user, chat


def create_chat_with_messages(num_messages: int = 3) -> tuple[Chat, list[Message]]:
    """Create a chat with multiple messages."""
    chat = ChatFactory()
    messages = [
        MessageFactory(
            chatId=chat.id,
            role="user" if i % 2 == 0 else "assistant",
        )
        for i in range(num_messages)
    ]
    return chat, messages


def create_message_parts(text: str, with_reasoning: bool = False) -> list[dict[str, Any]]:
    """Create message parts for testing."""
    parts: list[dict[str, Any]] = [{"type": "text", "text": text}]
    if with_reasoning:
        parts.insert(0, {"type": "reasoning", "reasoning": "Thinking about the response..."})
    return parts
