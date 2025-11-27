"""Prometheus metrics instrumentation for Knowsee Platform.

Provides automatic HTTP metrics and custom application metrics.
"""

import os
import time
from collections.abc import Callable
from functools import wraps
from typing import Any, TypeVar

from fastapi import FastAPI
from prometheus_client import Counter, Histogram

# Check if metrics are enabled
METRICS_ENABLED = os.getenv("METRICS_ENABLED", "true").lower() == "true"

# Custom metrics
LLM_REQUEST_DURATION = Histogram(
    "llm_request_duration_seconds",
    "Time spent on LLM API requests",
    ["provider", "model", "status"],
    buckets=(0.1, 0.5, 1.0, 2.5, 5.0, 10.0, 30.0, 60.0),
)

LLM_REQUEST_TOTAL = Counter(
    "llm_requests_total",
    "Total number of LLM API requests",
    ["provider", "model", "status"],
)

DB_QUERY_DURATION = Histogram(
    "db_query_duration_seconds",
    "Time spent on database queries",
    ["operation", "table"],
    buckets=(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0),
)

CHAT_MESSAGES_TOTAL = Counter(
    "chat_messages_total",
    "Total number of chat messages",
    ["role", "user_type"],
)

STREAM_DURATION = Histogram(
    "stream_duration_seconds",
    "Duration of streaming responses",
    ["status"],
    buckets=(1.0, 5.0, 10.0, 30.0, 60.0, 120.0),
)


def setup_metrics(app: FastAPI) -> None:
    """Set up Prometheus metrics instrumentation for FastAPI.

    Args:
        app: The FastAPI application instance.
    """
    if not METRICS_ENABLED:
        return

    from prometheus_fastapi_instrumentator import Instrumentator

    # Instrument the app with default HTTP metrics
    instrumentator = Instrumentator(
        should_group_status_codes=True,
        should_ignore_untemplated=True,
        should_respect_env_var=True,
        should_instrument_requests_inprogress=True,
        excluded_handlers=["/health", "/health/ready", "/health/live", "/metrics"],
        inprogress_name="http_requests_inprogress",
        inprogress_labels=True,
    )

    instrumentator.instrument(app).expose(app, endpoint="/metrics")


F = TypeVar("F", bound=Callable[..., Any])


def track_llm_request(
    provider: str = "vertex_ai",
    model: str = "gemini-2.5-flash",
) -> Callable[[F], F]:
    """Decorator to track LLM request metrics.

    Args:
        provider: LLM provider name (e.g., "vertex_ai", "openai")
        model: Model name (e.g., "gemini-2.5-flash")

    Usage:
        @track_llm_request(provider="vertex_ai", model="gemini-2.5-flash")
        async def call_llm(prompt: str) -> str:
            ...
    """

    def decorator(func: F) -> F:
        @wraps(func)
        async def async_wrapper(*args: Any, **kwargs: Any) -> Any:
            start_time = time.perf_counter()
            status = "success"
            try:
                result = await func(*args, **kwargs)
                return result
            except Exception:
                status = "error"
                raise
            finally:
                duration = time.perf_counter() - start_time
                LLM_REQUEST_DURATION.labels(
                    provider=provider,
                    model=model,
                    status=status,
                ).observe(duration)
                LLM_REQUEST_TOTAL.labels(
                    provider=provider,
                    model=model,
                    status=status,
                ).inc()

        @wraps(func)
        def sync_wrapper(*args: Any, **kwargs: Any) -> Any:
            start_time = time.perf_counter()
            status = "success"
            try:
                result = func(*args, **kwargs)
                return result
            except Exception:
                status = "error"
                raise
            finally:
                duration = time.perf_counter() - start_time
                LLM_REQUEST_DURATION.labels(
                    provider=provider,
                    model=model,
                    status=status,
                ).observe(duration)
                LLM_REQUEST_TOTAL.labels(
                    provider=provider,
                    model=model,
                    status=status,
                ).inc()

        import asyncio

        if asyncio.iscoroutinefunction(func):
            return async_wrapper  # type: ignore[return-value]
        return sync_wrapper  # type: ignore[return-value]

    return decorator


def track_db_query(operation: str, table: str) -> Callable[[F], F]:
    """Decorator to track database query metrics.

    Args:
        operation: Query operation type (e.g., "select", "insert", "update")
        table: Database table name

    Usage:
        @track_db_query(operation="select", table="Chat")
        async def get_chat(chat_id: UUID) -> Chat:
            ...
    """

    def decorator(func: F) -> F:
        @wraps(func)
        async def async_wrapper(*args: Any, **kwargs: Any) -> Any:
            start_time = time.perf_counter()
            try:
                return await func(*args, **kwargs)
            finally:
                duration = time.perf_counter() - start_time
                DB_QUERY_DURATION.labels(
                    operation=operation,
                    table=table,
                ).observe(duration)

        @wraps(func)
        def sync_wrapper(*args: Any, **kwargs: Any) -> Any:
            start_time = time.perf_counter()
            try:
                return func(*args, **kwargs)
            finally:
                duration = time.perf_counter() - start_time
                DB_QUERY_DURATION.labels(
                    operation=operation,
                    table=table,
                ).observe(duration)

        import asyncio

        if asyncio.iscoroutinefunction(func):
            return async_wrapper  # type: ignore[return-value]
        return sync_wrapper  # type: ignore[return-value]

    return decorator


def record_chat_message(role: str, user_type: str = "registered") -> None:
    """Record a chat message metric.

    Args:
        role: Message role ("user" or "assistant")
        user_type: Type of user ("guest" or "registered")
    """
    CHAT_MESSAGES_TOTAL.labels(role=role, user_type=user_type).inc()
