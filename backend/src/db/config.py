"""Database configuration for async SQLAlchemy with PostgreSQL."""

import asyncio
import os
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

load_dotenv()

# Convert postgres:// to postgresql+asyncpg:// for async driver
_postgres_url = os.getenv("POSTGRES_URL", "")
DATABASE_URL = _postgres_url.replace("postgres://", "postgresql+asyncpg://").replace(
    "postgresql://", "postgresql+asyncpg://"
)

# Configuration from environment
DB_POOL_TIMEOUT = int(os.getenv("DB_POOL_TIMEOUT", "30"))
DB_HEALTH_CHECK_TIMEOUT = float(os.getenv("DB_HEALTH_CHECK_TIMEOUT", "2.0"))

# Create async engine with connection pooling
engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    pool_timeout=DB_POOL_TIMEOUT,
)

# Session factory
async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


@asynccontextmanager
async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """Provide a transactional scope around a series of operations.

    Usage:
        async with get_session() as session:
            result = await session.execute(query)
            # auto-commits on success, auto-rollbacks on exception
    """
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def check_db_health(timeout: float | None = None) -> dict[str, str | bool]:
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
            import time

            start = time.perf_counter()

            async with async_session_factory() as session:
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
