"""Shared pytest fixtures for Knowsee Platform tests."""

import os
from collections.abc import AsyncGenerator
from datetime import datetime, timezone
from typing import Any
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from backend.src.db.models import Base

# Test database URL (use environment variable or default to test DB)
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test:test@localhost:5433/test_knowsee",
)


@pytest.fixture
def anyio_backend() -> str:
    """Use asyncio as the async backend."""
    return "asyncio"


@pytest.fixture
def mock_uuid() -> str:
    """Provide a consistent UUID for testing."""
    return "12345678-1234-1234-1234-123456789012"


@pytest.fixture
def mock_datetime() -> datetime:
    """Provide a consistent datetime for testing."""
    return datetime(2024, 1, 15, 12, 0, 0, tzinfo=timezone.utc)


@pytest.fixture
def mock_session() -> AsyncMock:
    """Create a mock async database session for unit tests.

    Use this when you want to test functions in isolation without
    hitting a real database.
    """
    session = AsyncMock(spec=AsyncSession)
    session.execute = AsyncMock()
    session.commit = AsyncMock()
    session.rollback = AsyncMock()
    session.refresh = AsyncMock()
    session.add = MagicMock()
    session.delete = AsyncMock()
    return session


@pytest.fixture
async def test_engine():
    """Create a test database engine.

    Use this for integration tests that need a real database.
    """
    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        pool_pre_ping=True,
        pool_size=2,
        max_overflow=3,
        pool_timeout=10,
    )

    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    # Drop all tables after tests
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest.fixture
async def test_session(test_engine) -> AsyncGenerator[AsyncSession, None]:
    """Create a test database session for integration tests.

    Each test gets a fresh session with automatic rollback.
    """
    async_session_factory = async_sessionmaker(
        test_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    async with async_session_factory() as session:
        yield session
        await session.rollback()


@pytest.fixture
async def test_client() -> AsyncGenerator[AsyncClient, None]:
    """Create an async HTTP test client for API testing.

    This uses the FastAPI app directly via ASGI transport.
    """
    from backend.src.app import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.fixture
def sample_user_data() -> dict[str, Any]:
    """Sample user data for testing."""
    return {
        "id": uuid4(),
        "email": "test@example.com",
        "password": "hashed_password_here",
    }


@pytest.fixture
def sample_chat_data(sample_user_data: dict[str, Any]) -> dict[str, Any]:
    """Sample chat data for testing."""
    return {
        "id": uuid4(),
        "createdAt": datetime.now(timezone.utc),
        "title": "Test Chat",
        "userId": sample_user_data["id"],
        "visibility": "private",
    }


@pytest.fixture
def sample_message_data(sample_chat_data: dict[str, Any]) -> dict[str, Any]:
    """Sample message data for testing."""
    return {
        "id": uuid4(),
        "chatId": sample_chat_data["id"],
        "role": "user",
        "parts": [{"type": "text", "text": "Hello, world!"}],
        "attachments": [],
        "createdAt": datetime.now(timezone.utc),
    }


@pytest.fixture
def mock_llm_response() -> dict[str, Any]:
    """Mock LLM response for testing graph functions."""
    return {
        "content": "This is a mock response from the LLM.",
        "role": "assistant",
        "finish_reason": "stop",
    }
