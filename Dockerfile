# ==============================================================================
# Knowsee Platform - Backend Dockerfile
# ==============================================================================
# Multi-stage build for FastAPI + LangGraph backend using uv
# Target: Google Cloud Run (linux/amd64)
# ==============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build dependencies with uv
# -----------------------------------------------------------------------------
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS builder

WORKDIR /app

# Copy dependency files first for better caching
COPY pyproject.toml uv.lock ./

# Install dependencies (frozen = use exact versions from lockfile)
RUN uv sync --frozen --no-dev --no-install-project

# Copy backend source code (including entrypoint script)
COPY backend/ backend/

# Install the project itself
RUN uv sync --frozen --no-dev

# Make entrypoint executable
RUN chmod +x backend/entrypoint.sh

# -----------------------------------------------------------------------------
# Stage 2: Production runtime
# -----------------------------------------------------------------------------
FROM python:3.11-slim-bookworm AS runtime

# Build arguments for versioning
ARG COMMIT_SHA="unknown"
ARG AGENT_VERSION="0.0.0"

# Labels for container metadata
LABEL org.opencontainers.image.source="https://github.com/knowsee/knowsee-platform"
LABEL org.opencontainers.image.version="${AGENT_VERSION}"
LABEL org.opencontainers.image.revision="${COMMIT_SHA}"

WORKDIR /app

# Install runtime dependencies (curl for health checks)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Copy backend source (includes entrypoint.sh)
COPY --from=builder /app/backend /app/backend

# Copy alembic configuration and pyproject for migrations
COPY --from=builder /app/pyproject.toml /app/

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV COMMIT_SHA=${COMMIT_SHA}
ENV AGENT_VERSION=${AGENT_VERSION}

# Cloud Run uses PORT environment variable
ENV PORT=8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port
EXPOSE ${PORT}

# Use entrypoint script to run migrations then start server
CMD ["/app/backend/entrypoint.sh"]
