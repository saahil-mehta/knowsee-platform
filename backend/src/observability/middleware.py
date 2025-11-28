"""Observability middleware for FastAPI.

Provides request logging, context binding, and error handling.
"""

import time
import uuid
from typing import Any

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint

from backend.src.observability.exceptions import KnowseeError
from backend.src.observability.logging import bind_context, clear_context, get_logger

logger = get_logger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware for logging HTTP requests and responses."""

    async def dispatch(
        self,
        request: Request,
        call_next: RequestResponseEndpoint,
    ) -> Response:
        # Generate request ID
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))

        # Bind context for all logs in this request
        bind_context(
            request_id=request_id,
            method=request.method,
            path=request.url.path,
        )

        # Record start time
        start_time = time.perf_counter()

        try:
            # Log request start
            logger.info(
                "Request started",
                query_params=dict(request.query_params),
            )

            # Process request
            response = await call_next(request)

            # Calculate duration
            duration = time.perf_counter() - start_time

            # Log request completion
            logger.info(
                "Request completed",
                status_code=response.status_code,
                duration_ms=round(duration * 1000, 2),
            )

            # Add request ID to response headers
            response.headers["X-Request-ID"] = request_id

            return response

        except Exception as exc:
            duration = time.perf_counter() - start_time
            logger.exception(
                "Request failed",
                error=str(exc),
                duration_ms=round(duration * 1000, 2),
            )
            raise

        finally:
            # Clear context after request
            clear_context()


def setup_exception_handlers(app: FastAPI) -> None:
    """Set up exception handlers for the FastAPI application.

    Converts exceptions to consistent JSON error responses.
    """

    @app.exception_handler(KnowseeError)
    async def knowsee_error_handler(
        request: Request,
        exc: KnowseeError,
    ) -> JSONResponse:
        """Handle KnowseeError exceptions."""
        logger.warning(
            "Application error",
            error_code=exc.code,
            error_message=exc.message,
            status_code=exc.status_code,
            details=exc.details,
        )

        response_data: dict[str, Any] = exc.to_dict()
        response_data["request_id"] = request.headers.get("X-Request-ID")

        response = JSONResponse(
            status_code=exc.status_code,
            content=response_data,
        )

        # Add Retry-After header for rate limit errors
        if hasattr(exc, "retry_after") and exc.retry_after:  # type: ignore[union-attr]
            response.headers["Retry-After"] = str(exc.retry_after)  # type: ignore[union-attr]

        return response

    @app.exception_handler(Exception)
    async def generic_error_handler(
        request: Request,
        exc: Exception,
    ) -> JSONResponse:
        """Handle unexpected exceptions."""
        logger.exception(
            "Unhandled exception",
            error_type=type(exc).__name__,
            error_message=str(exc),
        )

        return JSONResponse(
            status_code=500,
            content={
                "error": "internal_error",
                "message": "An unexpected error occurred",
                "request_id": request.headers.get("X-Request-ID"),
            },
        )


def setup_observability(app: FastAPI) -> None:
    """Set up all observability features for the FastAPI application.

    This is a convenience function that sets up:
    - Request logging middleware
    - Exception handlers
    - Prometheus metrics

    Usage:
        from backend.src.observability.middleware import setup_observability

        app = FastAPI()
        setup_observability(app)
    """
    from backend.src.observability.logging import setup_logging
    from backend.src.observability.metrics import setup_metrics

    # Set up structured logging
    setup_logging()

    # Add request logging middleware
    app.add_middleware(RequestLoggingMiddleware)

    # Set up exception handlers
    setup_exception_handlers(app)

    # Set up Prometheus metrics
    setup_metrics(app)

    logger.info("Observability configured successfully")
