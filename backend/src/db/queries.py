"""Database query functions mirroring frontend/lib/db/queries.ts.

All functions are async and use SQLAlchemy with asyncpg.
Each function mirrors the exact behavior of its Drizzle counterpart.
"""

from datetime import datetime, timedelta
from typing import Any
from uuid import UUID

import bcrypt
from sqlalchemy import and_, asc, delete, desc, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from backend.src.db.models import Chat, Document, Message, Stream, Suggestion, User, Vote

# ==============================================================================
# USER QUERIES
# ==============================================================================


async def get_user(session: AsyncSession, email: str) -> list[User]:
    """Get user by email. Returns list for compatibility with Drizzle behavior."""
    result = await session.execute(select(User).where(User.email == email))
    return list(result.scalars().all())


async def create_user(session: AsyncSession, email: str, password: str) -> User:
    """Create a new user with hashed password."""
    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=10))
    user = User(email=email, password=hashed.decode("utf-8"))
    session.add(user)
    await session.flush()
    return user


async def create_guest_user(session: AsyncSession) -> dict[str, Any]:
    """Create a guest user with random credentials."""
    import uuid

    email = f"guest-{int(datetime.now().timestamp() * 1000)}"
    password = str(uuid.uuid4())
    user = await create_user(session, email, password)
    return {"id": user.id, "email": user.email}


# ==============================================================================
# CHAT QUERIES
# ==============================================================================


async def save_chat(
    session: AsyncSession,
    id: UUID,
    user_id: UUID,
    title: str,
    visibility: str = "private",
) -> Chat:
    """Create a new chat."""
    chat = Chat(
        id=id,
        createdAt=datetime.utcnow(),
        userId=user_id,
        title=title,
        visibility=visibility,
    )
    session.add(chat)
    await session.flush()
    return chat


async def get_chat_by_id(session: AsyncSession, id: UUID) -> Chat | None:
    """Get a single chat by ID."""
    result = await session.execute(select(Chat).where(Chat.id == id))
    return result.scalar_one_or_none()


async def get_chats_by_user_id(
    session: AsyncSession,
    user_id: UUID,
    limit: int = 10,
    starting_after: UUID | None = None,
    ending_before: UUID | None = None,
) -> dict[str, Any]:
    """Get paginated chats for a user using cursor-based pagination."""
    extended_limit = limit + 1

    # Base query
    query = select(Chat).where(Chat.userId == user_id).order_by(desc(Chat.createdAt))

    # Apply cursor-based pagination
    if starting_after:
        ref_result = await session.execute(select(Chat.createdAt).where(Chat.id == starting_after))
        ref_created_at = ref_result.scalar_one_or_none()
        if ref_created_at:
            query = query.where(Chat.createdAt > ref_created_at)
    elif ending_before:
        ref_result = await session.execute(select(Chat.createdAt).where(Chat.id == ending_before))
        ref_created_at = ref_result.scalar_one_or_none()
        if ref_created_at:
            query = query.where(Chat.createdAt < ref_created_at)

    result = await session.execute(query.limit(extended_limit))
    chats = list(result.scalars().all())

    has_more = len(chats) > limit

    return {
        "chats": chats[:limit] if has_more else chats,
        "hasMore": has_more,
    }


async def delete_chat_by_id(session: AsyncSession, id: UUID) -> Chat | None:
    """Delete a chat and all related data (votes, messages, streams)."""
    # Delete related data first (cascade manually for safety)
    await session.execute(delete(Vote).where(Vote.chatId == id))
    await session.execute(delete(Message).where(Message.chatId == id))
    await session.execute(delete(Stream).where(Stream.chatId == id))

    # Delete and return the chat
    result = await session.execute(delete(Chat).where(Chat.id == id).returning(Chat))
    return result.scalar_one_or_none()


async def delete_all_chats_by_user_id(session: AsyncSession, user_id: UUID) -> dict[str, int]:
    """Delete all chats for a user."""
    # Get all chat IDs first
    result = await session.execute(select(Chat.id).where(Chat.userId == user_id))
    chat_ids = [row[0] for row in result.all()]

    if not chat_ids:
        return {"deletedCount": 0}

    # Delete related data
    await session.execute(delete(Vote).where(Vote.chatId.in_(chat_ids)))
    await session.execute(delete(Message).where(Message.chatId.in_(chat_ids)))
    await session.execute(delete(Stream).where(Stream.chatId.in_(chat_ids)))

    # Delete chats
    result = await session.execute(delete(Chat).where(Chat.userId == user_id).returning(Chat.id))
    deleted = list(result.all())

    return {"deletedCount": len(deleted)}


async def update_chat_visibility_by_id(
    session: AsyncSession, chat_id: UUID, visibility: str
) -> None:
    """Update chat visibility (public/private)."""
    await session.execute(update(Chat).where(Chat.id == chat_id).values(visibility=visibility))


async def update_chat_last_context_by_id(
    session: AsyncSession, chat_id: UUID, context: dict[str, Any]
) -> None:
    """Update chat's last context (usage stats)."""
    await session.execute(update(Chat).where(Chat.id == chat_id).values(lastContext=context))


# ==============================================================================
# MESSAGE QUERIES
# ==============================================================================


async def save_messages(session: AsyncSession, messages: list[dict[str, Any]]) -> list[Message]:
    """Save multiple messages at once."""
    db_messages = [
        Message(
            id=msg.get("id"),
            chatId=msg["chatId"],
            role=msg["role"],
            parts=msg["parts"],
            attachments=msg.get("attachments", []),
            createdAt=msg.get("createdAt", datetime.utcnow()),
        )
        for msg in messages
    ]
    session.add_all(db_messages)
    await session.flush()
    return db_messages


async def get_messages_by_chat_id(session: AsyncSession, chat_id: UUID) -> list[Message]:
    """Get all messages for a chat, ordered by creation time."""
    result = await session.execute(
        select(Message).where(Message.chatId == chat_id).order_by(asc(Message.createdAt))
    )
    return list(result.scalars().all())


async def get_message_by_id(session: AsyncSession, id: UUID) -> list[Message]:
    """Get message by ID. Returns list for compatibility."""
    result = await session.execute(select(Message).where(Message.id == id))
    return list(result.scalars().all())


async def delete_messages_by_chat_id_after_timestamp(
    session: AsyncSession, chat_id: UUID, timestamp: datetime
) -> None:
    """Delete messages after a given timestamp (for undo/regenerate)."""
    # Get message IDs to delete
    result = await session.execute(
        select(Message.id).where(and_(Message.chatId == chat_id, Message.createdAt >= timestamp))
    )
    message_ids = [row[0] for row in result.all()]

    if message_ids:
        # Delete votes first
        await session.execute(
            delete(Vote).where(and_(Vote.chatId == chat_id, Vote.messageId.in_(message_ids)))
        )
        # Delete messages
        await session.execute(delete(Message).where(Message.id.in_(message_ids)))


async def get_message_count_by_user_id(
    session: AsyncSession, user_id: UUID, difference_in_hours: int
) -> int:
    """Get count of user messages within a time window (for rate limiting)."""
    cutoff = datetime.utcnow() - timedelta(hours=difference_in_hours)

    result = await session.execute(
        select(func.count(Message.id))
        .select_from(Message)
        .join(Chat, Message.chatId == Chat.id)
        .where(
            and_(
                Chat.userId == user_id,
                Message.createdAt >= cutoff,
                Message.role == "user",
            )
        )
    )
    return result.scalar() or 0


# ==============================================================================
# VOTE QUERIES
# ==============================================================================


async def vote_message(
    session: AsyncSession, chat_id: UUID, message_id: UUID, vote_type: str
) -> None:
    """Create or update a vote on a message."""
    is_upvoted = vote_type == "up"

    # Check for existing vote
    result = await session.execute(select(Vote).where(Vote.messageId == message_id))
    existing = result.scalar_one_or_none()

    if existing:
        # Update existing vote
        await session.execute(
            update(Vote)
            .where(and_(Vote.messageId == message_id, Vote.chatId == chat_id))
            .values(isUpvoted=is_upvoted)
        )
    else:
        # Create new vote
        vote = Vote(chatId=chat_id, messageId=message_id, isUpvoted=is_upvoted)
        session.add(vote)
        await session.flush()


async def get_votes_by_chat_id(session: AsyncSession, chat_id: UUID) -> list[Vote]:
    """Get all votes for a chat."""
    result = await session.execute(select(Vote).where(Vote.chatId == chat_id))
    return list(result.scalars().all())


# ==============================================================================
# DOCUMENT QUERIES
# ==============================================================================


async def save_document(
    session: AsyncSession,
    id: UUID,
    title: str,
    kind: str,
    content: str,
    user_id: UUID,
) -> list[Document]:
    """Create a new document version."""
    doc = Document(
        id=id,
        createdAt=datetime.utcnow(),
        title=title,
        kind=kind,
        content=content,
        userId=user_id,
    )
    session.add(doc)
    await session.flush()
    return [doc]


async def get_documents_by_id(session: AsyncSession, id: UUID) -> list[Document]:
    """Get all versions of a document, ordered by creation time."""
    result = await session.execute(
        select(Document).where(Document.id == id).order_by(asc(Document.createdAt))
    )
    return list(result.scalars().all())


async def get_document_by_id(session: AsyncSession, id: UUID) -> Document | None:
    """Get the latest version of a document."""
    result = await session.execute(
        select(Document).where(Document.id == id).order_by(desc(Document.createdAt)).limit(1)
    )
    return result.scalar_one_or_none()


async def delete_documents_by_id_after_timestamp(
    session: AsyncSession, id: UUID, timestamp: datetime
) -> list[Document]:
    """Delete document versions after a timestamp."""
    # Delete related suggestions first
    await session.execute(
        delete(Suggestion).where(
            and_(
                Suggestion.documentId == id,
                Suggestion.documentCreatedAt > timestamp,
            )
        )
    )

    # Delete and return documents
    result = await session.execute(
        delete(Document)
        .where(and_(Document.id == id, Document.createdAt > timestamp))
        .returning(Document)
    )
    return list(result.scalars().all())


# ==============================================================================
# SUGGESTION QUERIES
# ==============================================================================


async def save_suggestions(
    session: AsyncSession, suggestions: list[dict[str, Any]]
) -> list[Suggestion]:
    """Save multiple suggestions at once."""
    db_suggestions = [
        Suggestion(
            id=s.get("id"),
            documentId=s["documentId"],
            documentCreatedAt=s["documentCreatedAt"],
            originalText=s["originalText"],
            suggestedText=s["suggestedText"],
            description=s.get("description"),
            isResolved=s.get("isResolved", False),
            userId=s["userId"],
            createdAt=s.get("createdAt", datetime.utcnow()),
        )
        for s in suggestions
    ]
    session.add_all(db_suggestions)
    await session.flush()
    return db_suggestions


async def get_suggestions_by_document_id(
    session: AsyncSession, document_id: UUID
) -> list[Suggestion]:
    """Get all suggestions for a document."""
    result = await session.execute(select(Suggestion).where(Suggestion.documentId == document_id))
    return list(result.scalars().all())


# ==============================================================================
# STREAM QUERIES
# ==============================================================================


async def create_stream_id(session: AsyncSession, stream_id: UUID, chat_id: UUID) -> Stream:
    """Create a new stream record."""
    stream = Stream(id=stream_id, chatId=chat_id, createdAt=datetime.utcnow())
    session.add(stream)
    await session.flush()
    return stream


async def get_stream_ids_by_chat_id(session: AsyncSession, chat_id: UUID) -> list[UUID]:
    """Get all stream IDs for a chat, ordered by creation time."""
    result = await session.execute(
        select(Stream.id).where(Stream.chatId == chat_id).order_by(asc(Stream.createdAt))
    )
    return [row[0] for row in result.all()]
