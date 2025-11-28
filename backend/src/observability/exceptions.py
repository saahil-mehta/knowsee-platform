"""Custom exceptions for Knowsee Platform.

Provides structured error handling with error codes and HTTP status codes.
These exceptions are caught by FastAPI exception handlers and converted
to consistent JSON error responses.
"""

from typing import Any


class KnowseeError(Exception):
    """Base exception for all Knowsee Platform errors.

    Attributes:
        code: Machine-readable error code (e.g., "database_error")
        message: Human-readable error message
        status_code: HTTP status code to return
        details: Optional additional error context
    """

    code: str = "internal_error"
    status_code: int = 500

    def __init__(
        self,
        message: str,
        *,
        code: str | None = None,
        status_code: int | None = None,
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(message)
        self.message = message
        if code is not None:
            self.code = code
        if status_code is not None:
            self.status_code = status_code
        self.details = details or {}

    def to_dict(self) -> dict[str, Any]:
        """Convert exception to dictionary for JSON response."""
        result: dict[str, Any] = {
            "error": self.code,
            "message": self.message,
        }
        if self.details:
            result["details"] = self.details
        return result


class DatabaseError(KnowseeError):
    """Database operation errors.

    Raised when database queries fail, connections timeout,
    or constraint violations occur.
    """

    code = "database_error"
    status_code = 503  # Service Unavailable


class LLMError(KnowseeError):
    """Base exception for LLM-related errors.

    Generic error for any LLM provider (Vertex AI, OpenAI, etc.).
    """

    code = "llm_error"
    status_code = 502  # Bad Gateway


class VertexAIError(LLMError):
    """Vertex AI specific errors.

    Raised when Vertex AI API calls fail, timeout,
    or return unexpected responses.
    """

    code = "vertex_ai_error"
    status_code = 502


class ValidationError(KnowseeError):
    """Request validation errors.

    Raised when request data fails validation checks.
    """

    code = "validation_error"
    status_code = 400  # Bad Request


class RateLimitError(KnowseeError):
    """Rate limit exceeded errors.

    Raised when a user exceeds their allowed request quota.
    """

    code = "rate_limit_exceeded"
    status_code = 429  # Too Many Requests

    def __init__(
        self,
        message: str = "Rate limit exceeded. Please try again later.",
        *,
        retry_after: int | None = None,
        **kwargs: Any,
    ) -> None:
        super().__init__(message, **kwargs)
        self.retry_after = retry_after
        if retry_after:
            self.details["retry_after_seconds"] = retry_after


class NotFoundError(KnowseeError):
    """Resource not found errors.

    Raised when a requested resource does not exist.
    """

    code = "not_found"
    status_code = 404


class AuthenticationError(KnowseeError):
    """Authentication errors.

    Raised when authentication fails or credentials are invalid.
    """

    code = "authentication_error"
    status_code = 401  # Unauthorised


class AuthorisationError(KnowseeError):
    """Authorisation errors.

    Raised when user lacks permission to perform an action.
    """

    code = "authorisation_error"
    status_code = 403  # Forbidden
