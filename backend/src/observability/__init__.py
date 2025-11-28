"""Observability module for Knowsee Platform.

Provides structured logging, Prometheus metrics, OpenTelemetry tracing,
and standardised error handling.
"""

from backend.src.observability.exceptions import (
    DatabaseError,
    KnowseeError,
    LLMError,
    RateLimitError,
    ValidationError,
    VertexAIError,
)
from backend.src.observability.logging import get_logger, setup_logging
from backend.src.observability.metrics import setup_metrics

__all__ = [
    # Logging
    "get_logger",
    "setup_logging",
    # Metrics
    "setup_metrics",
    # Exceptions
    "KnowseeError",
    "DatabaseError",
    "LLMError",
    "VertexAIError",
    "ValidationError",
    "RateLimitError",
]
