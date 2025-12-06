"""Database configuration for async SQLAlchemy with PostgreSQL."""

import asyncio
import os
import time
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from functools import lru_cache

from dotenv import load_dotenv
from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

load_dotenv()

# Configuration from environment
DB_POOL_TIMEOUT = int(os.getenv("DB_POOL_TIMEOUT", "30"))
DB_HEALTH_CHECK_TIMEOUT = float(os.getenv("DB_HEALTH_CHECK_TIMEOUT", "2.0"))


def get_database_url() -> str:
    """Get the database URL, converting to async driver format."""
    postgres_url = os.getenv("POSTGRES_URL", "")
    return postgres_url.replace("postgres://", "postgresql+asyncpg://").replace(
        "postgresql://", "postgresql+asyncpg://"
    )


@lru_cache(maxsize=1)
def get_engine() -> AsyncEngine:
    """Create async engine lazily on first access.

    Uses lru_cache to ensure only one engine is created.
    """
    database_url = get_database_url()
    if not database_url:
        raise RuntimeError(
            "POSTGRES_URL environment variable not set. Set it to a PostgreSQL connection string."
        )
    return create_async_engine(
        database_url,
        echo=False,
        pool_pre_ping=True,
        pool_size=5,
        max_overflow=10,
        pool_timeout=DB_POOL_TIMEOUT,
    )


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    """Get the session factory, creating engine if needed."""
    return async_sessionmaker(
        get_engine(),
        class_=AsyncSession,
        expire_on_commit=False,
    )


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency for FastAPI routes.

    Yields a database session that commits on success and rolls back on exception.
    """
    session_factory = get_session_factory()
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


@asynccontextmanager
async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """Provide a transactional scope around a series of operations.

    Usage:
        async with get_session() as session:
            result = await session.execute(query)
            # auto-commits on success, auto-rollbacks on exception
    """
    async for session in get_db():
        yield session


async def check_db_health(timeout: float | None = None) -> dict[str, str | bool | float]:
    """Check database connectivity with a timeout.

    Args:
        timeout: Maximum time to wait for the health check (seconds).
                 Defaults to DB_HEALTH_CHECK_TIMEOUT.

    Returns:
        Dictionary with health status:
        - healthy: True if database is reachable
        - latency_ms: Round-trip time in milliseconds
        - error: Error message if unhealthy

    Raises:
        TimeoutError: If the health check exceeds the timeout.
    """
    check_timeout = timeout or DB_HEALTH_CHECK_TIMEOUT

    try:
        async with asyncio.timeout(check_timeout):
            start = time.perf_counter()

            session_factory = get_session_factory()
            async with session_factory() as session:
                await session.execute(text("SELECT 1"))

            latency_ms = round((time.perf_counter() - start) * 1000, 2)

            return {
                "healthy": True,
                "latency_ms": latency_ms,
            }

    except asyncio.TimeoutError:
        return {
            "healthy": False,
            "error": f"Database health check timed out after {check_timeout}s",
        }
    except Exception as e:
        return {
            "healthy": False,
            "error": str(e),
        }
