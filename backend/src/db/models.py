"""SQLAlchemy models matching the Drizzle ORM schema exactly.

Table mapping:
- User -> "User"
- Chat -> "Chat"
- Message -> "Message_v2"
- Vote -> "Vote_v2"
- Document -> "Document" (composite PK: id, createdAt)
- Suggestion -> "Suggestion"
- Stream -> "Stream"
"""

from datetime import datetime
from typing import Any
from uuid import uuid4

from sqlalchemy import Boolean, DateTime, ForeignKey, ForeignKeyConstraint, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""

    pass


class User(Base):
    """User table for authentication."""

    __tablename__ = "User"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(64), nullable=False)
    password: Mapped[str | None] = mapped_column(String(64), nullable=True)

    # Relationships
    chats: Mapped[list["Chat"]] = relationship(back_populates="user", lazy="selectin")
    documents: Mapped[list["Document"]] = relationship(back_populates="user", lazy="selectin")
    suggestions: Mapped[list["Suggestion"]] = relationship(back_populates="user", lazy="selectin")


class Chat(Base):
    """Chat session table."""

    __tablename__ = "Chat"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    createdAt: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    userId: Mapped[UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("User.id"), nullable=False)
    visibility: Mapped[str] = mapped_column(String, nullable=False, default="private")
    lastContext: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)

    # Relationships
    user: Mapped["User"] = relationship(back_populates="chats", lazy="selectin")
    messages: Mapped[list["Message"]] = relationship(
        back_populates="chat", cascade="all, delete-orphan", lazy="selectin"
    )
    votes: Mapped[list["Vote"]] = relationship(
        back_populates="chat", cascade="all, delete-orphan", lazy="selectin"
    )
    streams: Mapped[list["Stream"]] = relationship(
        back_populates="chat", cascade="all, delete-orphan", lazy="selectin"
    )


class Message(Base):
    """Message table (v2) for chat messages."""

    __tablename__ = "Message_v2"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    chatId: Mapped[UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("Chat.id"), nullable=False)
    role: Mapped[str] = mapped_column(String, nullable=False)
    parts: Mapped[Any] = mapped_column(JSONB, nullable=False)
    attachments: Mapped[Any] = mapped_column(JSONB, nullable=False)
    createdAt: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    # Relationships
    chat: Mapped["Chat"] = relationship(back_populates="messages", lazy="selectin")
    votes: Mapped[list["Vote"]] = relationship(back_populates="message", lazy="selectin")


class Vote(Base):
    """Vote table (v2) for message voting."""

    __tablename__ = "Vote_v2"

    chatId: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("Chat.id"), primary_key=True
    )
    messageId: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("Message_v2.id"), primary_key=True
    )
    isUpvoted: Mapped[bool] = mapped_column(Boolean, nullable=False)

    # Relationships
    chat: Mapped["Chat"] = relationship(back_populates="votes", lazy="selectin")
    message: Mapped["Message"] = relationship(back_populates="votes", lazy="selectin")


class Document(Base):
    """Document table for artifacts with composite primary key."""

    __tablename__ = "Document"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    createdAt: Mapped[datetime] = mapped_column(DateTime, primary_key=True)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    content: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Note: Drizzle schema defines this as varchar("text", ...) so the DB column is "text"
    kind: Mapped[str] = mapped_column("text", String, nullable=False, default="text")
    userId: Mapped[UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("User.id"), nullable=False)

    # Relationships
    user: Mapped["User"] = relationship(back_populates="documents", lazy="selectin")
    suggestions: Mapped[list["Suggestion"]] = relationship(
        back_populates="document",
        foreign_keys="[Suggestion.documentId, Suggestion.documentCreatedAt]",
        lazy="selectin",
    )


class Suggestion(Base):
    """Suggestion table for document edit suggestions."""

    __tablename__ = "Suggestion"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    documentId: Mapped[UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    documentCreatedAt: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    originalText: Mapped[str] = mapped_column(Text, nullable=False)
    suggestedText: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    isResolved: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    userId: Mapped[UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("User.id"), nullable=False)
    createdAt: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    # Composite foreign key constraint
    __table_args__ = (
        ForeignKeyConstraint(
            ["documentId", "documentCreatedAt"],
            ["Document.id", "Document.createdAt"],
        ),
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="suggestions", lazy="selectin")
    document: Mapped["Document"] = relationship(
        back_populates="suggestions",
        foreign_keys=[documentId, documentCreatedAt],
        lazy="selectin",
    )


class Stream(Base):
    """Stream table for tracking streaming sessions."""

    __tablename__ = "Stream"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    chatId: Mapped[UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("Chat.id"), nullable=False)
    createdAt: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    # Relationships
    chat: Mapped["Chat"] = relationship(back_populates="streams", lazy="selectin")
