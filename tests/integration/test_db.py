"""Integration tests for database operations.

These tests verify database round-trips using the real test database.
"""

from uuid import uuid4

import pytest

from backend.src.db import queries

pytestmark = pytest.mark.asyncio


class TestUserDatabaseOperations:
    """Integration tests for user database operations."""

    async def test_create_user_persists_to_database(self, test_session):
        """Test that created users are persisted."""
        email = f"dbtest-{uuid4()}@example.com"
        password = "securepassword"

        user = await queries.create_user(test_session, email, password)
        await test_session.commit()

        # Verify user was created
        assert user.id is not None
        assert user.email == email
        assert user.password is not None
        assert user.password != password  # Should be hashed

    async def test_get_user_retrieves_from_database(self, test_session):
        """Test that users can be retrieved by email."""
        email = f"retrieve-{uuid4()}@example.com"

        # Create user directly
        await queries.create_user(test_session, email, "password")
        await test_session.commit()

        # Retrieve user
        users = await queries.get_user(test_session, email)

        assert len(users) == 1
        assert users[0].email == email

    async def test_create_guest_user(self, test_session):
        """Test creating a guest user."""
        result = await queries.create_guest_user(test_session)
        await test_session.commit()

        # create_guest_user returns a dict with id and email
        assert result["id"] is not None
        assert result["email"].startswith("guest-")


class TestChatDatabaseOperations:
    """Integration tests for chat database operations."""

    async def test_save_chat_persists_to_database(self, test_session):
        """Test that chats are persisted correctly."""
        # Create user first
        user = await queries.create_user(test_session, f"chat-{uuid4()}@test.com", "pass")
        await test_session.commit()

        chat_id = uuid4()
        chat = await queries.save_chat(
            test_session,
            id=chat_id,
            user_id=user.id,
            title="Integration Test Chat",
            visibility="private",
        )
        await test_session.commit()

        assert chat.id == chat_id
        assert chat.title == "Integration Test Chat"
        assert chat.visibility == "private"
        assert chat.userId == user.id

    async def test_get_chat_by_id(self, test_session):
        """Test retrieving a chat by ID."""
        user = await queries.create_user(test_session, f"getchat-{uuid4()}@test.com", "pass")
        chat_id = uuid4()
        await queries.save_chat(test_session, chat_id, user.id, "Test", "private")
        await test_session.commit()

        # Retrieve chat
        chat = await queries.get_chat_by_id(test_session, chat_id)

        assert chat is not None
        assert chat.id == chat_id
        assert chat.title == "Test"

    async def test_get_chat_by_id_returns_none_for_missing(self, test_session):
        """Test that missing chats return None."""
        chat = await queries.get_chat_by_id(test_session, uuid4())
        assert chat is None

    async def test_get_chats_by_user_id_with_pagination(self, test_session):
        """Test paginated chat retrieval."""
        user = await queries.create_user(test_session, f"paginate-{uuid4()}@test.com", "pass")
        await test_session.commit()

        # Create 5 chats
        for i in range(5):
            await queries.save_chat(test_session, uuid4(), user.id, f"Chat {i}", "private")
        await test_session.commit()

        # Get first page
        result = await queries.get_chats_by_user_id(test_session, user.id, limit=3)

        assert len(result["chats"]) == 3
        assert result["hasMore"] is True

        # Get all
        result = await queries.get_chats_by_user_id(test_session, user.id, limit=10)
        assert len(result["chats"]) == 5
        assert result["hasMore"] is False

    async def test_delete_chat_removes_chat_and_related_data(self, test_session):
        """Test that deleting a chat removes all related data."""
        user = await queries.create_user(test_session, f"delete-{uuid4()}@test.com", "pass")
        chat_id = uuid4()
        await queries.save_chat(test_session, chat_id, user.id, "To Delete", "private")

        # Add a message
        await queries.save_messages(
            test_session,
            [
                {
                    "chatId": chat_id,
                    "role": "user",
                    "parts": [{"type": "text", "text": "Hello"}],
                }
            ],
        )
        await test_session.commit()

        # Delete chat
        deleted = await queries.delete_chat_by_id(test_session, chat_id)
        await test_session.commit()

        assert deleted is not None

        # Verify deleted
        chat = await queries.get_chat_by_id(test_session, chat_id)
        assert chat is None

    async def test_update_chat_visibility(self, test_session):
        """Test updating chat visibility."""
        user = await queries.create_user(test_session, f"visibility-{uuid4()}@test.com", "pass")
        chat_id = uuid4()
        await queries.save_chat(test_session, chat_id, user.id, "Test", "private")
        await test_session.commit()

        # Update visibility
        await queries.update_chat_visibility_by_id(test_session, chat_id, "public")
        await test_session.commit()

        # Verify
        chat = await queries.get_chat_by_id(test_session, chat_id)
        assert chat.visibility == "public"


class TestMessageDatabaseOperations:
    """Integration tests for message database operations."""

    async def test_save_messages_persists_multiple(self, test_session):
        """Test saving multiple messages."""
        user = await queries.create_user(test_session, f"msg-{uuid4()}@test.com", "pass")
        chat_id = uuid4()
        await queries.save_chat(test_session, chat_id, user.id, "Test", "private")
        await test_session.commit()

        messages = [
            {
                "chatId": chat_id,
                "role": "user",
                "parts": [{"type": "text", "text": "Hello"}],
            },
            {
                "chatId": chat_id,
                "role": "assistant",
                "parts": [{"type": "text", "text": "Hi!"}],
            },
        ]

        saved = await queries.save_messages(test_session, messages)
        await test_session.commit()

        assert len(saved) == 2
        assert saved[0].role == "user"
        assert saved[1].role == "assistant"

    async def test_get_messages_by_chat_id(self, test_session):
        """Test retrieving messages by chat ID."""
        user = await queries.create_user(test_session, f"getmsg-{uuid4()}@test.com", "pass")
        chat_id = uuid4()
        await queries.save_chat(test_session, chat_id, user.id, "Test", "private")
        await queries.save_messages(
            test_session,
            [
                {"chatId": chat_id, "role": "user", "parts": [{"type": "text", "text": "One"}]},
                {
                    "chatId": chat_id,
                    "role": "assistant",
                    "parts": [{"type": "text", "text": "Two"}],
                },
            ],
        )
        await test_session.commit()

        messages = await queries.get_messages_by_chat_id(test_session, chat_id)

        assert len(messages) == 2

    async def test_get_message_count_by_user_id(self, test_session):
        """Test counting messages for rate limiting."""
        user = await queries.create_user(test_session, f"count-{uuid4()}@test.com", "pass")
        chat_id = uuid4()
        await queries.save_chat(test_session, chat_id, user.id, "Test", "private")

        # Add user messages
        await queries.save_messages(
            test_session,
            [
                {"chatId": chat_id, "role": "user", "parts": [{"type": "text", "text": "1"}]},
                {"chatId": chat_id, "role": "user", "parts": [{"type": "text", "text": "2"}]},
                {"chatId": chat_id, "role": "assistant", "parts": [{"type": "text", "text": "R"}]},
            ],
        )
        await test_session.commit()

        count = await queries.get_message_count_by_user_id(test_session, user.id, 24)

        # Should count only user messages
        assert count == 2


class TestVoteDatabaseOperations:
    """Integration tests for vote database operations."""

    async def test_vote_message_creates_vote(self, test_session):
        """Test creating a vote."""
        user = await queries.create_user(test_session, f"vote-{uuid4()}@test.com", "pass")
        chat_id = uuid4()
        await queries.save_chat(test_session, chat_id, user.id, "Test", "private")
        msgs = await queries.save_messages(
            test_session,
            [{"chatId": chat_id, "role": "assistant", "parts": [{"type": "text", "text": "R"}]}],
        )
        message_id = msgs[0].id
        await test_session.commit()

        # Vote
        await queries.vote_message(test_session, chat_id, message_id, "up")
        await test_session.commit()

        # Verify
        votes = await queries.get_votes_by_chat_id(test_session, chat_id)
        assert len(votes) == 1
        assert votes[0].isUpvoted is True

    async def test_vote_message_updates_existing_vote(self, test_session):
        """Test updating an existing vote."""
        user = await queries.create_user(test_session, f"updatevote-{uuid4()}@test.com", "pass")
        chat_id = uuid4()
        await queries.save_chat(test_session, chat_id, user.id, "Test", "private")
        msgs = await queries.save_messages(
            test_session,
            [{"chatId": chat_id, "role": "assistant", "parts": [{"type": "text", "text": "R"}]}],
        )
        message_id = msgs[0].id
        await test_session.commit()

        # Vote up then down
        await queries.vote_message(test_session, chat_id, message_id, "up")
        await test_session.commit()

        await queries.vote_message(test_session, chat_id, message_id, "down")
        await test_session.commit()

        # Verify vote changed
        votes = await queries.get_votes_by_chat_id(test_session, chat_id)
        assert len(votes) == 1
        assert votes[0].isUpvoted is False


class TestStreamDatabaseOperations:
    """Integration tests for stream database operations."""

    async def test_create_and_get_stream_ids(self, test_session):
        """Test creating and retrieving stream IDs."""
        user = await queries.create_user(test_session, f"stream-{uuid4()}@test.com", "pass")
        chat_id = uuid4()
        await queries.save_chat(test_session, chat_id, user.id, "Test", "private")
        await test_session.commit()

        # Create streams
        stream_id_1 = uuid4()
        stream_id_2 = uuid4()
        await queries.create_stream_id(test_session, stream_id_1, chat_id)
        await queries.create_stream_id(test_session, stream_id_2, chat_id)
        await test_session.commit()

        # Get stream IDs
        stream_ids = await queries.get_stream_ids_by_chat_id(test_session, chat_id)

        assert len(stream_ids) == 2
        assert stream_id_1 in stream_ids
        assert stream_id_2 in stream_ids
