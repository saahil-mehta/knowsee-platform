"""FastAPI routes for database operations.

All endpoints are under /api/db/ prefix.
These endpoints are called by the Next.js frontend.
"""

from datetime import datetime
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Query
from pydantic import BaseModel, ConfigDict

from backend.src.db import queries
from backend.src.db.config import get_session

router = APIRouter(prefix="/api/db", tags=["database"])


# ==============================================================================
# PYDANTIC MODELS
# ==============================================================================


class UserResponse(BaseModel):
    """User response model."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: str
    password: str | None = None


class ChatCreate(BaseModel):
    """Chat creation request."""

    id: UUID
    userId: UUID
    title: str
    visibility: str = "private"


class ChatResponse(BaseModel):
    """Chat response model."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    createdAt: datetime
    title: str
    userId: UUID
    visibility: str
    lastContext: dict[str, Any] | None = None


class ChatsResponse(BaseModel):
    """Paginated chats response."""

    chats: list[ChatResponse]
    hasMore: bool


class MessageCreate(BaseModel):
    """Message creation request."""

    id: UUID | None = None
    chatId: UUID
    role: str
    parts: list[Any]
    attachments: list[Any] = []
    createdAt: datetime | None = None


class MessageResponse(BaseModel):
    """Message response model."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    chatId: UUID
    role: str
    parts: list[Any]
    attachments: list[Any]
    createdAt: datetime


class VoteRequest(BaseModel):
    """Vote request model."""

    chatId: UUID
    messageId: UUID
    type: str  # "up" or "down"


class VoteResponse(BaseModel):
    """Vote response model."""

    model_config = ConfigDict(from_attributes=True)

    chatId: UUID
    messageId: UUID
    isUpvoted: bool


class DocumentCreate(BaseModel):
    """Document creation request."""

    id: UUID
    title: str
    kind: str
    content: str
    userId: UUID


class DocumentResponse(BaseModel):
    """Document response model."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    createdAt: datetime
    title: str
    content: str | None
    kind: str
    userId: UUID


class SuggestionCreate(BaseModel):
    """Suggestion creation request."""

    id: UUID | None = None
    documentId: UUID
    documentCreatedAt: datetime
    originalText: str
    suggestedText: str
    description: str | None = None
    isResolved: bool = False
    userId: UUID
    createdAt: datetime | None = None


class SuggestionResponse(BaseModel):
    """Suggestion response model."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    documentId: UUID
    documentCreatedAt: datetime
    originalText: str
    suggestedText: str
    description: str | None
    isResolved: bool
    userId: UUID
    createdAt: datetime


class StreamCreate(BaseModel):
    """Stream creation request."""

    streamId: UUID
    chatId: UUID


class SuccessResponse(BaseModel):
    """Generic success response."""

    success: bool = True


class CountResponse(BaseModel):
    """Count response model."""

    count: int


class DeletedCountResponse(BaseModel):
    """Deleted count response."""

    deletedCount: int


# ==============================================================================
# USER ENDPOINTS
# ==============================================================================


@router.get("/users", response_model=list[UserResponse])
async def get_user(email: str = Query(..., description="User email")):
    """Get user by email."""
    async with get_session() as session:
        users = await queries.get_user(session, email)
        return users


@router.post("/users", response_model=UserResponse)
async def create_user(email: str = Query(...), password: str = Query(...)):
    """Create a new user."""
    async with get_session() as session:
        user = await queries.create_user(session, email, password)
        return user


@router.post("/users/guest", response_model=UserResponse)
async def create_guest_user():
    """Create a guest user."""
    async with get_session() as session:
        return await queries.create_guest_user(session)


# ==============================================================================
# CHAT ENDPOINTS
# ==============================================================================


@router.post("/chats", response_model=ChatResponse)
async def save_chat(chat: ChatCreate):
    """Create a new chat."""
    async with get_session() as session:
        result = await queries.save_chat(session, chat.id, chat.userId, chat.title, chat.visibility)
        return result


@router.get("/chats/{chat_id}", response_model=ChatResponse | None)
async def get_chat_by_id(chat_id: UUID):
    """Get a chat by ID."""
    async with get_session() as session:
        chat = await queries.get_chat_by_id(session, chat_id)
        if not chat:
            return None
        return chat


@router.get("/chats", response_model=ChatsResponse)
async def get_chats_by_user_id(
    userId: UUID = Query(...),
    limit: int = Query(10),
    starting_after: UUID | None = Query(None),
    ending_before: UUID | None = Query(None),
):
    """Get paginated chats for a user."""
    async with get_session() as session:
        result = await queries.get_chats_by_user_id(
            session, userId, limit, starting_after, ending_before
        )
        return result


@router.delete("/chats/{chat_id}", response_model=ChatResponse | None)
async def delete_chat_by_id(chat_id: UUID):
    """Delete a chat and all related data."""
    async with get_session() as session:
        return await queries.delete_chat_by_id(session, chat_id)


@router.delete("/chats/user/{user_id}", response_model=DeletedCountResponse)
async def delete_all_chats_by_user_id(user_id: UUID):
    """Delete all chats for a user."""
    async with get_session() as session:
        return await queries.delete_all_chats_by_user_id(session, user_id)


@router.patch("/chats/{chat_id}/visibility", response_model=SuccessResponse)
async def update_chat_visibility(chat_id: UUID, visibility: str = Query(...)):
    """Update chat visibility."""
    async with get_session() as session:
        await queries.update_chat_visibility_by_id(session, chat_id, visibility)
        return {"success": True}


@router.patch("/chats/{chat_id}/context", response_model=SuccessResponse)
async def update_chat_last_context(chat_id: UUID, context: dict[str, Any]):
    """Update chat's last context."""
    async with get_session() as session:
        await queries.update_chat_last_context_by_id(session, chat_id, context)
        return {"success": True}


# ==============================================================================
# MESSAGE ENDPOINTS
# ==============================================================================


@router.post("/messages", response_model=list[MessageResponse])
async def save_messages(messages: list[MessageCreate]):
    """Save multiple messages."""
    async with get_session() as session:
        return await queries.save_messages(session, [m.model_dump() for m in messages])


@router.get("/messages/{chat_id}", response_model=list[MessageResponse])
async def get_messages_by_chat_id(chat_id: UUID):
    """Get all messages for a chat."""
    async with get_session() as session:
        return await queries.get_messages_by_chat_id(session, chat_id)


@router.get("/messages/single/{message_id}", response_model=list[MessageResponse])
async def get_message_by_id(message_id: UUID):
    """Get a message by ID."""
    async with get_session() as session:
        return await queries.get_message_by_id(session, message_id)


@router.delete("/messages/{chat_id}", response_model=SuccessResponse)
async def delete_messages_after_timestamp(chat_id: UUID, timestamp: datetime = Query(...)):
    """Delete messages after a timestamp."""
    async with get_session() as session:
        await queries.delete_messages_by_chat_id_after_timestamp(session, chat_id, timestamp)
        return {"success": True}


@router.get("/messages/count/{user_id}", response_model=CountResponse)
async def get_message_count(user_id: UUID, hours: int = Query(24)):
    """Get message count for rate limiting."""
    async with get_session() as session:
        count = await queries.get_message_count_by_user_id(session, user_id, hours)
        return {"count": count}


# ==============================================================================
# VOTE ENDPOINTS
# ==============================================================================


@router.patch("/votes", response_model=SuccessResponse)
async def vote_message(vote: VoteRequest):
    """Vote on a message."""
    async with get_session() as session:
        await queries.vote_message(session, vote.chatId, vote.messageId, vote.type)
        return {"success": True}


@router.get("/votes/{chat_id}", response_model=list[VoteResponse])
async def get_votes_by_chat_id(chat_id: UUID):
    """Get all votes for a chat."""
    async with get_session() as session:
        return await queries.get_votes_by_chat_id(session, chat_id)


# ==============================================================================
# DOCUMENT ENDPOINTS
# ==============================================================================


@router.post("/documents", response_model=list[DocumentResponse])
async def save_document(doc: DocumentCreate):
    """Create a new document."""
    async with get_session() as session:
        return await queries.save_document(
            session, doc.id, doc.title, doc.kind, doc.content, doc.userId
        )


@router.get("/documents/{doc_id}", response_model=list[DocumentResponse])
async def get_documents_by_id(doc_id: UUID):
    """Get all versions of a document."""
    async with get_session() as session:
        return await queries.get_documents_by_id(session, doc_id)


@router.get("/documents/{doc_id}/latest", response_model=DocumentResponse | None)
async def get_document_by_id(doc_id: UUID):
    """Get the latest version of a document."""
    async with get_session() as session:
        return await queries.get_document_by_id(session, doc_id)


@router.delete("/documents/{doc_id}", response_model=list[DocumentResponse])
async def delete_documents_after_timestamp(doc_id: UUID, timestamp: datetime = Query(...)):
    """Delete document versions after a timestamp."""
    async with get_session() as session:
        return await queries.delete_documents_by_id_after_timestamp(session, doc_id, timestamp)


# ==============================================================================
# SUGGESTION ENDPOINTS
# ==============================================================================


@router.post("/suggestions", response_model=list[SuggestionResponse])
async def save_suggestions(suggestions: list[SuggestionCreate]):
    """Save multiple suggestions."""
    async with get_session() as session:
        return await queries.save_suggestions(session, [s.model_dump() for s in suggestions])


@router.get("/suggestions/{document_id}", response_model=list[SuggestionResponse])
async def get_suggestions_by_document_id(document_id: UUID):
    """Get all suggestions for a document."""
    async with get_session() as session:
        return await queries.get_suggestions_by_document_id(session, document_id)


# ==============================================================================
# STREAM ENDPOINTS
# ==============================================================================


@router.post("/streams", response_model=SuccessResponse)
async def create_stream_id(stream: StreamCreate):
    """Create a stream record."""
    async with get_session() as session:
        await queries.create_stream_id(session, stream.streamId, stream.chatId)
        return {"success": True}


@router.get("/streams/{chat_id}", response_model=list[UUID])
async def get_stream_ids_by_chat_id(chat_id: UUID):
    """Get all stream IDs for a chat."""
    async with get_session() as session:
        return await queries.get_stream_ids_by_chat_id(session, chat_id)
