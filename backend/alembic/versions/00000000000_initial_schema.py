"""Initial schema - create all tables.

Revision ID: 00000000000
Revises:
Create Date: 2024-11-28

Creates all tables required by the Knowsee Platform:
- User: Authentication
- Chat: Chat sessions
- Message_v2: Chat messages
- Vote_v2: Message votes
- Document: Artifacts with composite PK
- Suggestion: Document edit suggestions
- Stream: Streaming sessions
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "00000000000"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # User table
    op.create_table(
        "User",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(64), nullable=False),
        sa.Column("password", sa.String(64), nullable=True),
    )

    # Chat table
    op.create_table(
        "Chat",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("createdAt", sa.DateTime(timezone=True), nullable=False),
        sa.Column("title", sa.Text, nullable=False),
        sa.Column("userId", postgresql.UUID(as_uuid=True), sa.ForeignKey("User.id"), nullable=False),
        sa.Column("visibility", sa.String, nullable=False, server_default="private"),
        sa.Column("lastContext", postgresql.JSONB, nullable=True),
    )

    # Message_v2 table
    op.create_table(
        "Message_v2",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("chatId", postgresql.UUID(as_uuid=True), sa.ForeignKey("Chat.id"), nullable=False),
        sa.Column("role", sa.String, nullable=False),
        sa.Column("parts", postgresql.JSONB, nullable=False),
        sa.Column("attachments", postgresql.JSONB, nullable=False),
        sa.Column("createdAt", sa.DateTime(timezone=True), nullable=False),
    )

    # Vote_v2 table (composite PK)
    op.create_table(
        "Vote_v2",
        sa.Column("chatId", postgresql.UUID(as_uuid=True), sa.ForeignKey("Chat.id"), primary_key=True),
        sa.Column("messageId", postgresql.UUID(as_uuid=True), sa.ForeignKey("Message_v2.id"), primary_key=True),
        sa.Column("isUpvoted", sa.Boolean, nullable=False),
    )

    # Document table (composite PK)
    op.create_table(
        "Document",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("createdAt", sa.DateTime(timezone=True), primary_key=True),
        sa.Column("title", sa.Text, nullable=False),
        sa.Column("content", sa.Text, nullable=True),
        sa.Column("text", sa.String, nullable=False, server_default="text"),  # kind column named "text"
        sa.Column("userId", postgresql.UUID(as_uuid=True), sa.ForeignKey("User.id"), nullable=False),
    )

    # Suggestion table
    op.create_table(
        "Suggestion",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("documentId", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("documentCreatedAt", sa.DateTime(timezone=True), nullable=False),
        sa.Column("originalText", sa.Text, nullable=False),
        sa.Column("suggestedText", sa.Text, nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("isResolved", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("userId", postgresql.UUID(as_uuid=True), sa.ForeignKey("User.id"), nullable=False),
        sa.Column("createdAt", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["documentId", "documentCreatedAt"],
            ["Document.id", "Document.createdAt"],
        ),
    )

    # Stream table
    op.create_table(
        "Stream",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("chatId", postgresql.UUID(as_uuid=True), sa.ForeignKey("Chat.id"), nullable=False),
        sa.Column("createdAt", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("Stream")
    op.drop_table("Suggestion")
    op.drop_table("Document")
    op.drop_table("Vote_v2")
    op.drop_table("Message_v2")
    op.drop_table("Chat")
    op.drop_table("User")
