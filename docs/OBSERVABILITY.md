# Observability Guide

This document covers logging, metrics, tracing, and error handling for the Knowsee Platform.

## Overview

The observability stack consists of:
- **Structured Logging** - JSON-formatted logs via structlog
- **Metrics** - Prometheus metrics via FastAPI Instrumentator
- **Tracing** - OpenTelemetry for distributed tracing (optional)
- **Error Handling** - Typed exceptions with error codes

## Quick Start

```python
from backend.src.observability import get_logger, setup_logging

# Initialise logging (call once at app startup)
setup_logging()

# Get a logger
logger = get_logger(__name__)
logger.info("Processing request", user_id="123", action="chat")
```

## Structured Logging

### Configuration

Logging is configured via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_LEVEL` | `INFO` | Log level (DEBUG, INFO, WARNING, ERROR) |
| `LOG_FORMAT` | `json` | Format (`json` for production, anything else for console) |

### Usage

```python
from backend.src.observability import get_logger, bind_context, clear_context

logger = get_logger(__name__)

# Basic logging
logger.info("User logged in", user_id="123")
logger.warning("Rate limit approaching", remaining=5)
logger.error("Database connection failed", error=str(e))

# Context binding (persists across logs in same request)
bind_context(request_id="abc-123", user_id="456")
logger.info("Processing")  # Includes request_id and user_id
logger.info("Complete")    # Also includes request_id and user_id
clear_context()            # Clean up at request end
```

### Log Output

**JSON format** (production):
```json
{
  "event": "Processing request",
  "logger": "backend.src.app",
  "level": "info",
  "timestamp": "2024-01-15T10:30:00.000000Z",
  "request_id": "abc-123",
  "user_id": "456"
}
```

**Console format** (development):
```
2024-01-15 10:30:00 [info     ] Processing request    request_id=abc-123 user_id=456
```

## Metrics

### Built-in Metrics

The FastAPI Instrumentator automatically exposes:
- `http_requests_total` - Total HTTP requests by method/path/status
- `http_request_duration_seconds` - Request latency histogram
- `http_requests_inprogress` - Currently processing requests

### Custom Metrics

```python
from backend.src.observability.metrics import (
    track_llm_request,
    track_db_query,
    record_chat_message,
)

# Decorator for LLM calls
@track_llm_request(provider="vertex_ai", model="gemini-2.5-flash")
async def call_llm(prompt: str) -> str:
    ...

# Decorator for database queries
@track_db_query(operation="select", table="Chat")
async def get_chat(chat_id: UUID) -> Chat:
    ...

# Manual metric recording
record_chat_message(role="user", user_type="registered")
```

### Metrics Endpoint

Metrics are exposed at `/metrics` in Prometheus format:

```bash
curl http://localhost:8000/metrics
```

### Disabling Metrics

```bash
METRICS_ENABLED=false
```

## Health Checks

Three health endpoints are available:

| Endpoint | Purpose | Checks |
|----------|---------|--------|
| `/health` | General health | App is running |
| `/health/live` | Kubernetes liveness | App is running (fast) |
| `/health/ready` | Kubernetes readiness | Database connectivity |

### Response Format

```json
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Unhealthy Response

```json
{
  "status": "unhealthy",
  "database": "disconnected",
  "error": "Connection timeout",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Error Handling

### Exception Hierarchy

```
KnowseeError (base)
  ├── DatabaseError (503)
  ├── LLMError (502)
  │   └── VertexAIError (502)
  ├── ValidationError (400)
  ├── RateLimitError (429)
  ├── NotFoundError (404)
  ├── AuthenticationError (401)
  └── AuthorisationError (403)
```

### Usage

```python
from backend.src.observability import (
    DatabaseError,
    VertexAIError,
    RateLimitError,
    NotFoundError,
)

# Raise typed exceptions
raise NotFoundError("Chat not found", details={"chat_id": str(chat_id)})

raise RateLimitError(
    "Daily message limit exceeded",
    retry_after=3600,  # Adds Retry-After header
)

raise DatabaseError("Connection pool exhausted")
```

### Error Response Format

All exceptions are converted to consistent JSON:

```json
{
  "error": "not_found",
  "message": "Chat not found",
  "details": {
    "chat_id": "abc-123"
  },
  "request_id": "req-456"
}
```

## Resilience

### LLM Retry Logic

LLM calls use tenacity for retry with exponential backoff:

```python
# Configuration via environment
LLM_TIMEOUT_SECONDS=30
LLM_MAX_RETRIES=3
```

Retry behaviour:
- Max attempts: 3 (configurable)
- Backoff: Exponential with jitter (1s initial, 10s max)
- Retries on: `ConnectionError`, `TimeoutError`
- Logs each retry attempt

### Database Resilience

Database connections include:
- Connection pool timeout: 30s
- Statement timeout: 30s (prevents runaway queries)
- Health check with 2s timeout

## Middleware

The `RequestLoggingMiddleware` automatically:
1. Generates or extracts `X-Request-ID` header
2. Binds request context (method, path, request_id)
3. Logs request start and completion
4. Measures request duration
5. Clears context after request

### Setup

```python
from backend.src.observability.middleware import setup_observability

app = FastAPI()
setup_observability(app)  # Configures logging, metrics, middleware
```

## OpenTelemetry Tracing (Optional)

Enable distributed tracing for production:

```bash
OTEL_ENABLED=true
OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4317
OTEL_SERVICE_NAME=knowsee-backend
```

Tracing instruments:
- FastAPI requests
- SQLAlchemy queries
- HTTP client calls

## Best Practices

### Logging

1. **Use structured fields** instead of string interpolation:
   ```python
   # Good
   logger.info("User action", user_id=user_id, action="login")

   # Bad
   logger.info(f"User {user_id} performed login")
   ```

2. **Log at appropriate levels**:
   - `DEBUG`: Detailed debugging info
   - `INFO`: Normal operations
   - `WARNING`: Potential issues
   - `ERROR`: Failures requiring attention

3. **Include correlation IDs** for request tracing

### Metrics

1. **Label cardinality**: Keep label values bounded (no user IDs in labels)
2. **Histogram buckets**: Choose buckets that match expected distributions
3. **Naming**: Follow Prometheus conventions (`snake_case`, units in name)

### Error Handling

1. **Use typed exceptions** for known error conditions
2. **Include context** in error details
3. **Don't expose internal errors** to users (generic 500 message)
