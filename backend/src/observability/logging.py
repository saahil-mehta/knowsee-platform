"""Structured logging configuration using structlog.

Provides JSON-formatted logs with context binding for request tracing.
"""

import logging
import os
import sys
from typing import Any, cast

import structlog


def setup_logging(
    level: str | None = None,
    json_format: bool | None = None,
) -> None:
    """Configure structured logging for the application.

    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR). Defaults to LOG_LEVEL env var or INFO.
        json_format: Whether to use JSON format. Defaults to LOG_FORMAT env var == "json".
    """
    log_level = level or os.getenv("LOG_LEVEL", "INFO").upper()
    use_json = json_format if json_format is not None else os.getenv("LOG_FORMAT", "json") == "json"

    # Set up standard library logging
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=getattr(logging, log_level),
    )

    # Configure structlog processors
    shared_processors: list[structlog.typing.Processor] = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.UnicodeDecoder(),
    ]

    if use_json:
        # JSON format for production
        shared_processors.append(structlog.processors.format_exc_info)
        renderer: structlog.typing.Processor = structlog.processors.JSONRenderer()
    else:
        # Console format for development
        renderer = structlog.dev.ConsoleRenderer(colors=True)

    structlog.configure(
        processors=[
            *shared_processors,
            structlog.stdlib.ProcessorFormatter.wrap_for_formatter,
        ],
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    # Configure formatter for stdlib handlers
    formatter = structlog.stdlib.ProcessorFormatter(
        foreign_pre_chain=shared_processors,
        processors=[
            structlog.stdlib.ProcessorFormatter.remove_processors_meta,
            renderer,
        ],
    )

    # Apply formatter to root logger handler
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(handler)
    root_logger.setLevel(getattr(logging, log_level))

    # Reduce noise from third-party libraries
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)


def get_logger(name: str | None = None) -> structlog.stdlib.BoundLogger:
    """Get a structured logger instance.

    Args:
        name: Logger name (typically __name__). Defaults to "knowsee".

    Returns:
        A bound logger instance with context support.

    Usage:
        logger = get_logger(__name__)
        logger.info("Processing request", user_id="123", action="chat")

        # With context binding
        log = logger.bind(request_id="abc123")
        log.info("Request started")
        log.info("Request completed")  # Also includes request_id
    """
    return cast(structlog.stdlib.BoundLogger, structlog.get_logger(name or "knowsee"))


def bind_context(**context: Any) -> None:
    """Bind context variables that will be included in all subsequent logs.

    Useful for adding request-scoped context like user_id, trace_id, etc.

    Usage:
        bind_context(user_id="123", request_id="abc")
        logger.info("Message")  # Will include user_id and request_id
    """
    structlog.contextvars.bind_contextvars(**context)


def clear_context() -> None:
    """Clear all bound context variables.

    Should be called at the end of each request to prevent context leakage.
    """
    structlog.contextvars.clear_contextvars()
