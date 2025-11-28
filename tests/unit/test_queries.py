"""Unit tests for database query functions."""

from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

import pytest

from backend.src.db.models import Chat, Message, User, Vote
from backend.src.db.queries import (
    create_user,
    delete_chat_by_id,
    get_chat_by_id,
    get_chats_by_user_id,
    get_message_by_id,
    get_message_count_by_user_id,
    get_messages_by_chat_id,
    get_user,
    get_votes_by_chat_id,
    save_chat,
    save_messages,
    vote_message,
)


class TestUserQueries:
    """Tests for user-related query functions."""

    @pytest.mark.asyncio
    async def test_get_user_found(self, mock_session: AsyncMock) -> None:
        """Test getting a user that exists."""
        # Set up mock return value
        mock_user = User(id=uuid4(), email="test@example.com", password="hashed")
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [mock_user]
        mock_session.execute.return_value = mock_result

        result = await get_user(mock_session, "test@example.com")

        assert len(result) == 1
        assert result[0].email == "test@example.com"
        mock_session.execute.assert_called_once()

    @pytest.mark.asyncio
    async def test_get_user_not_found(self, mock_session: AsyncMock) -> None:
        """Test getting a user that doesn't exist."""
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = []
        mock_session.execute.return_value = mock_result

        result = await get_user(mock_session, "nonexistent@example.com")

        assert len(result) == 0

    @pytest.mark.asyncio
    async def test_create_user(self, mock_session: AsyncMock) -> None:
        """Test creating a new user."""
        with patch("backend.src.db.queries.bcrypt") as mock_bcrypt:
            mock_bcrypt.hashpw.return_value = b"hashed_password"
            mock_bcrypt.gensalt.return_value = b"salt"

            result = await create_user(mock_session, "new@example.com", "password123")

            assert result.email == "new@example.com"
            assert result.password == "hashed_password"
            mock_session.add.assert_called_once()
            mock_session.flush.assert_called_once()


class TestChatQueries:
    """Tests for chat-related query functions."""

    @pytest.mark.asyncio
    async def test_save_chat(self, mock_session: AsyncMock) -> None:
        """Test saving a new chat."""
        chat_id = uuid4()
        user_id = uuid4()

        result = await save_chat(
            mock_session,
            id=chat_id,
            user_id=user_id,
            title="Test Chat",
            visibility="private",
        )

        assert result.id == chat_id
        assert result.userId == user_id
        assert result.title == "Test Chat"
        assert result.visibility == "private"
        mock_session.add.assert_called_once()
        mock_session.flush.assert_called_once()

    @pytest.mark.asyncio
    async def test_get_chat_by_id_found(self, mock_session: AsyncMock) -> None:
        """Test getting a chat that exists."""
        chat_id = uuid4()
        mock_chat = Chat(
            id=chat_id,
            createdAt=datetime.now(timezone.utc),
            title="Test",
            userId=uuid4(),
            visibility="private",
        )
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_chat
        mock_session.execute.return_value = mock_result

        result = await get_chat_by_id(mock_session, chat_id)

        assert result is not None
        assert result.id == chat_id

    @pytest.mark.asyncio
    async def test_get_chat_by_id_not_found(self, mock_session: AsyncMock) -> None:
        """Test getting a chat that doesn't exist."""
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_session.execute.return_value = mock_result

        result = await get_chat_by_id(mock_session, uuid4())

        assert result is None

    @pytest.mark.asyncio
    async def test_get_chats_by_user_id(self, mock_session: AsyncMock) -> None:
        """Test getting paginated chats for a user."""
        user_id = uuid4()
        mock_chats = [
            Chat(
                id=uuid4(),
                createdAt=datetime.now(timezone.utc),
                title=f"Chat {i}",
                userId=user_id,
                visibility="private",
            )
            for i in range(3)
        ]
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = mock_chats
        mock_session.execute.return_value = mock_result

        result = await get_chats_by_user_id(mock_session, user_id, limit=10)

        assert "chats" in result
        assert "hasMore" in result
        assert len(result["chats"]) == 3
        assert result["hasMore"] is False

    @pytest.mark.asyncio
    async def test_get_chats_by_user_id_has_more(self, mock_session: AsyncMock) -> None:
        """Test pagination when there are more chats."""
        user_id = uuid4()
        # Return 11 chats when limit is 10 (indicates more available)
        mock_chats = [
            Chat(
                id=uuid4(),
                createdAt=datetime.now(timezone.utc),
                title=f"Chat {i}",
                userId=user_id,
                visibility="private",
            )
            for i in range(11)
        ]
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = mock_chats
        mock_session.execute.return_value = mock_result

        result = await get_chats_by_user_id(mock_session, user_id, limit=10)

        assert len(result["chats"]) == 10
        assert result["hasMore"] is True

    @pytest.mark.asyncio
    async def test_delete_chat_by_id(self, mock_session: AsyncMock) -> None:
        """Test deleting a chat and its related data."""
        chat_id = uuid4()
        mock_chat = Chat(
            id=chat_id,
            createdAt=datetime.now(timezone.utc),
            title="To Delete",
            userId=uuid4(),
            visibility="private",
        )
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_chat
        mock_session.execute.return_value = mock_result

        result = await delete_chat_by_id(mock_session, chat_id)

        # Should execute 4 times: delete votes, messages, streams, and chat
        assert mock_session.execute.call_count == 4
        assert result is not None


class TestMessageQueries:
    """Tests for message-related query functions."""

    @pytest.mark.asyncio
    async def test_save_messages(self, mock_session: AsyncMock) -> None:
        """Test saving multiple messages."""
        chat_id = uuid4()
        messages = [
            {
                "chatId": chat_id,
                "role": "user",
                "parts": [{"type": "text", "text": "Hello"}],
            },
            {
                "chatId": chat_id,
                "role": "assistant",
                "parts": [{"type": "text", "text": "Hi there!"}],
            },
        ]

        result = await save_messages(mock_session, messages)

        assert len(result) == 2
        assert result[0].role == "user"
        assert result[1].role == "assistant"
        mock_session.add_all.assert_called_once()
        mock_session.flush.assert_called_once()

    @pytest.mark.asyncio
    async def test_get_messages_by_chat_id(self, mock_session: AsyncMock) -> None:
        """Test getting messages for a chat."""
        chat_id = uuid4()
        mock_messages = [
            Message(
                id=uuid4(),
                chatId=chat_id,
                role="user",
                parts=[{"type": "text", "text": "Hello"}],
                attachments=[],
                createdAt=datetime.now(timezone.utc),
            ),
            Message(
                id=uuid4(),
                chatId=chat_id,
                role="assistant",
                parts=[{"type": "text", "text": "Hi!"}],
                attachments=[],
                createdAt=datetime.now(timezone.utc),
            ),
        ]
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = mock_messages
        mock_session.execute.return_value = mock_result

        result = await get_messages_by_chat_id(mock_session, chat_id)

        assert len(result) == 2
        assert result[0].role == "user"
        assert result[1].role == "assistant"

    @pytest.mark.asyncio
    async def test_get_message_by_id(self, mock_session: AsyncMock) -> None:
        """Test getting a message by ID."""
        message_id = uuid4()
        mock_message = Message(
            id=message_id,
            chatId=uuid4(),
            role="user",
            parts=[{"type": "text", "text": "Hello"}],
            attachments=[],
            createdAt=datetime.now(timezone.utc),
        )
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [mock_message]
        mock_session.execute.return_value = mock_result

        result = await get_message_by_id(mock_session, message_id)

        assert len(result) == 1
        assert result[0].id == message_id

    @pytest.mark.asyncio
    async def test_get_message_count_by_user_id(self, mock_session: AsyncMock) -> None:
        """Test counting messages for rate limiting."""
        user_id = uuid4()
        mock_result = MagicMock()
        mock_result.scalar.return_value = 15
        mock_session.execute.return_value = mock_result

        result = await get_message_count_by_user_id(mock_session, user_id, 24)

        assert result == 15


class TestVoteQueries:
    """Tests for vote-related query functions."""

    @pytest.mark.asyncio
    async def test_vote_message_new_upvote(self, mock_session: AsyncMock) -> None:
        """Test creating a new upvote."""
        chat_id = uuid4()
        message_id = uuid4()

        # No existing vote
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_session.execute.return_value = mock_result

        await vote_message(mock_session, chat_id, message_id, "up")

        mock_session.add.assert_called_once()
        mock_session.flush.assert_called_once()

    @pytest.mark.asyncio
    async def test_vote_message_update_existing(self, mock_session: AsyncMock) -> None:
        """Test updating an existing vote."""
        chat_id = uuid4()
        message_id = uuid4()
        existing_vote = Vote(chatId=chat_id, messageId=message_id, isUpvoted=True)

        # Return existing vote
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = existing_vote
        mock_session.execute.return_value = mock_result

        await vote_message(mock_session, chat_id, message_id, "down")

        # Should execute twice: select and update
        assert mock_session.execute.call_count == 2
        mock_session.add.assert_not_called()

    @pytest.mark.asyncio
    async def test_get_votes_by_chat_id(self, mock_session: AsyncMock) -> None:
        """Test getting votes for a chat."""
        chat_id = uuid4()
        mock_votes = [
            Vote(chatId=chat_id, messageId=uuid4(), isUpvoted=True),
            Vote(chatId=chat_id, messageId=uuid4(), isUpvoted=False),
        ]
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = mock_votes
        mock_session.execute.return_value = mock_result

        result = await get_votes_by_chat_id(mock_session, chat_id)

        assert len(result) == 2
        assert result[0].isUpvoted is True
        assert result[1].isUpvoted is False
