"""Integration tests for API routes with real database.

These tests use the test database to verify end-to-end functionality
of the API endpoints.
"""

from contextlib import asynccontextmanager
from datetime import datetime, timezone
from unittest.mock import patch
from uuid import uuid4

import pytest
from httpx import ASGITransport, AsyncClient

from backend.src.app import app
from backend.src.db.config import get_db

# Skip all tests if test database is not available
pytestmark = pytest.mark.asyncio


@pytest.fixture
async def integration_client(test_session):
    """Create a test client that uses the test database session.

    Patches get_session to return the test session, ensuring all route
    database operations use the same session as the test fixtures.
    """

    async def mock_get_db():
        yield test_session

    app.dependency_overrides[get_db] = mock_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
    app.dependency_overrides.clear()


class TestHealthEndpointsIntegration:
    """Integration tests for health check endpoints."""

    async def test_liveness_returns_healthy(self, integration_client):
        """Test /health returns healthy status."""
        response = await integration_client.get("/health")

        assert response.status_code == 200
        assert response.json()["status"] == "healthy"

    async def test_live_returns_healthy(self, integration_client):
        """Test /health/live returns healthy status."""
        response = await integration_client.get("/health/live")

        assert response.status_code == 200
        assert response.json()["status"] == "healthy"


class TestUserRoutesIntegration:
    """Integration tests for user endpoints."""

    async def test_create_and_get_user(self, integration_client):
        """Test creating and retrieving a user."""
        email = f"test-{uuid4()}@example.com"
        password = "testpassword123"

        # Create user
        response = await integration_client.post(
            "/api/db/users",
            params={"email": email, "password": password},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["email"] == email
        assert "id" in data

        # Get user
        response = await integration_client.get(
            "/api/db/users",
            params={"email": email},
        )

        assert response.status_code == 200
        users = response.json()
        assert len(users) == 1
        assert users[0]["email"] == email

    async def test_get_nonexistent_user(self, integration_client):
        """Test getting a user that doesn't exist."""
        response = await integration_client.get(
            "/api/db/users",
            params={"email": "nonexistent@example.com"},
        )

        assert response.status_code == 200
        assert response.json() == []


class TestChatRoutesIntegration:
    """Integration tests for chat endpoints."""

    async def test_create_and_get_chat(self, integration_client):
        """Test creating and retrieving a chat."""
        # First create a user
        user_email = f"chatuser-{uuid4()}@example.com"
        user_response = await integration_client.post(
            "/api/db/users",
            params={"email": user_email, "password": "password"},
        )
        user_id = user_response.json()["id"]

        # Create chat
        chat_id = str(uuid4())
        response = await integration_client.post(
            "/api/db/chats",
            json={
                "id": chat_id,
                "userId": user_id,
                "title": "Test Chat",
                "visibility": "private",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == chat_id
        assert data["title"] == "Test Chat"
        assert data["visibility"] == "private"

        # Get chat by ID
        response = await integration_client.get(f"/api/db/chats/{chat_id}")

        assert response.status_code == 200
        chat = response.json()
        assert chat["id"] == chat_id
        assert chat["title"] == "Test Chat"

    async def test_get_chats_by_user_with_pagination(self, integration_client):
        """Test paginated chat retrieval."""
        # Create user
        user_email = f"paginationuser-{uuid4()}@example.com"
        user_response = await integration_client.post(
            "/api/db/users",
            params={"email": user_email, "password": "password"},
        )
        user_id = user_response.json()["id"]

        # Create multiple chats
        chat_ids = []
        for i in range(5):
            chat_id = str(uuid4())
            chat_ids.append(chat_id)
            await integration_client.post(
                "/api/db/chats",
                json={
                    "id": chat_id,
                    "userId": user_id,
                    "title": f"Chat {i}",
                    "visibility": "private",
                },
            )

        # Get chats with limit
        response = await integration_client.get(
            "/api/db/chats",
            params={"userId": user_id, "limit": 3},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["chats"]) == 3
        assert data["hasMore"] is True

    async def test_delete_chat(self, integration_client):
        """Test deleting a chat."""
        # Create user and chat
        user_email = f"deleteuser-{uuid4()}@example.com"
        user_response = await integration_client.post(
            "/api/db/users",
            params={"email": user_email, "password": "password"},
        )
        user_id = user_response.json()["id"]

        chat_id = str(uuid4())
        await integration_client.post(
            "/api/db/chats",
            json={
                "id": chat_id,
                "userId": user_id,
                "title": "To Delete",
                "visibility": "private",
            },
        )

        # Delete chat
        response = await integration_client.delete(f"/api/db/chats/{chat_id}")
        assert response.status_code == 200

        # Verify deleted
        response = await integration_client.get(f"/api/db/chats/{chat_id}")
        assert response.status_code == 200
        assert response.json() is None


class TestMessageRoutesIntegration:
    """Integration tests for message endpoints."""

    async def test_save_and_get_messages(self, integration_client):
        """Test saving and retrieving messages."""
        # Create user and chat
        user_email = f"msguser-{uuid4()}@example.com"
        user_response = await integration_client.post(
            "/api/db/users",
            params={"email": user_email, "password": "password"},
        )
        user_id = user_response.json()["id"]

        chat_id = str(uuid4())
        await integration_client.post(
            "/api/db/chats",
            json={
                "id": chat_id,
                "userId": user_id,
                "title": "Message Test",
                "visibility": "private",
            },
        )

        # Save messages
        now = datetime.now(timezone.utc).isoformat()
        messages = [
            {
                "id": str(uuid4()),
                "chatId": chat_id,
                "role": "user",
                "parts": [{"type": "text", "text": "Hello"}],
                "attachments": [],
                "createdAt": now,
            },
            {
                "id": str(uuid4()),
                "chatId": chat_id,
                "role": "assistant",
                "parts": [{"type": "text", "text": "Hi there!"}],
                "attachments": [],
                "createdAt": now,
            },
        ]

        response = await integration_client.post("/api/db/messages", json=messages)

        assert response.status_code == 200
        saved = response.json()
        assert len(saved) == 2

        # Get messages
        response = await integration_client.get(f"/api/db/messages/{chat_id}")

        assert response.status_code == 200
        retrieved = response.json()
        assert len(retrieved) == 2
        assert retrieved[0]["role"] == "user"
        assert retrieved[1]["role"] == "assistant"


class TestVoteRoutesIntegration:
    """Integration tests for vote endpoints."""

    async def test_vote_on_message(self, integration_client):
        """Test voting on a message."""
        # Create user, chat, and message
        user_email = f"voteuser-{uuid4()}@example.com"
        user_response = await integration_client.post(
            "/api/db/users",
            params={"email": user_email, "password": "password"},
        )
        user_id = user_response.json()["id"]

        chat_id = str(uuid4())
        await integration_client.post(
            "/api/db/chats",
            json={
                "id": chat_id,
                "userId": user_id,
                "title": "Vote Test",
                "visibility": "private",
            },
        )

        message_id = str(uuid4())
        now = datetime.now(timezone.utc).isoformat()
        await integration_client.post(
            "/api/db/messages",
            json=[
                {
                    "id": message_id,
                    "chatId": chat_id,
                    "role": "assistant",
                    "parts": [{"type": "text", "text": "Response"}],
                    "attachments": [],
                    "createdAt": now,
                }
            ],
        )

        # Vote up
        response = await integration_client.patch(
            "/api/db/votes",
            json={"chatId": chat_id, "messageId": message_id, "type": "up"},
        )

        assert response.status_code == 200
        assert response.json()["success"] is True

        # Get votes
        response = await integration_client.get(f"/api/db/votes/{chat_id}")

        assert response.status_code == 200
        votes = response.json()
        assert len(votes) == 1
        assert votes[0]["isUpvoted"] is True

        # Change vote to down
        response = await integration_client.patch(
            "/api/db/votes",
            json={"chatId": chat_id, "messageId": message_id, "type": "down"},
        )

        assert response.status_code == 200

        # Verify vote changed
        response = await integration_client.get(f"/api/db/votes/{chat_id}")
        votes = response.json()
        assert votes[0]["isUpvoted"] is False
