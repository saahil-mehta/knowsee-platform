# Testing Guide

This document covers the testing infrastructure for the Knowsee Platform, including backend unit/integration tests, frontend E2E tests, and CI/CD workflows.

## Quick Start

```bash
# Run all backend tests (requires test database)
make test-db-up
make backend-test
make test-db-down

# Run frontend tests
make frontend-test

# Run full CI check locally
make check
```

## Test Structure

```
tests/
  __init__.py
  conftest.py              # Shared pytest fixtures
  factories.py             # Factory Boy model factories
  unit/
    __init__.py
    test_health.py         # Health check endpoint tests
    test_queries.py        # Database query function tests
    test_stream.py         # SSE streaming tests
  integration/
    __init__.py
    test_db.py             # Real database round-trip tests
    test_routes.py         # API route tests (some skipped)

frontend/tests/
  fixtures.ts              # Playwright test fixtures
  helpers.ts               # Test utilities
  setup.ts                 # Test setup configuration
  pages/
    auth.ts                # Auth page object
    chat.ts                # Chat page object
    artifact.ts            # Artifact page object
  e2e/
    chat.test.ts           # Chat functionality tests
    session.test.ts        # Session/auth tests
    artifacts.test.ts      # Artifact feature tests
    reasoning.test.ts      # Reasoning display tests
  routes/
    chat.test.ts           # Chat API route tests
    document.test.ts       # Document API tests
  unit/
    utils.test.ts          # Utility function tests
```

## Backend Testing

### Unit Tests

Unit tests mock external dependencies and test functions in isolation.

```bash
# Run unit tests only
make backend-test-unit

# Run with coverage
make backend-test-cov
```

**Key fixtures** (`tests/conftest.py`):
- `mock_session` - Mocked async SQLAlchemy session
- `test_client` - HTTPX async test client for FastAPI
- `sample_user_data`, `sample_chat_data` - Test data fixtures

**Factories** (`tests/factories.py`):
```python
from tests.factories import UserFactory, ChatFactory, MessageFactory

# Create test instances
user = UserFactory()
chat = ChatFactory(userId=user.id)
messages = MessageFactory.create_batch(3, chatId=chat.id)
```

### Integration Tests

Integration tests use a real PostgreSQL database running in Docker.

```bash
# Start test database (port 5433)
make test-db-up

# Run integration tests
make backend-test-int

# Stop and clean up
make test-db-down
```

**Test database configuration**:
- Port: 5433 (to avoid conflicts with dev database on 5432)
- Database: `test_knowsee`
- User/Password: `test/test`
- Uses `tmpfs` for RAM-backed storage (fast, ephemeral)

**Environment variable**:
```bash
TEST_DATABASE_URL=postgresql+asyncpg://test:test@localhost:5433/test_knowsee
```

### Writing New Backend Tests

1. **Unit tests** - Mock the database session:
```python
@pytest.mark.asyncio
async def test_my_function(mock_session: AsyncMock) -> None:
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = [expected_data]
    mock_session.execute.return_value = mock_result

    result = await my_function(mock_session, param)

    assert result == expected_data
    mock_session.execute.assert_called_once()
```

2. **Integration tests** - Use the real test session:
```python
@pytest.mark.asyncio
async def test_database_operation(test_session) -> None:
    # Create test data
    user = await queries.create_user(test_session, "test@example.com", "pass")
    await test_session.commit()

    # Test retrieval
    users = await queries.get_user(test_session, "test@example.com")
    assert len(users) == 1
```

## Frontend Testing

### Unit Tests (Vitest)

```bash
make frontend-test-unit
```

Located in `frontend/tests/unit/`. Uses Vitest with React Testing Library.

### E2E Tests (Playwright)

```bash
# Run all E2E tests
make frontend-test-e2e

# Run specific test file
cd frontend && pnpm test:e2e chat.test.ts
```

**Page Objects** (`frontend/tests/pages/`):
- `ChatPage` - Chat interaction methods
- `ArtifactPage` - Artifact interaction methods
- `AuthPage` - Authentication methods

**Test IDs**: Components use `data-testid` attributes for reliable selection:
```tsx
<button data-testid="send-button">Send</button>
```

### Writing New E2E Tests

```typescript
import { expect, test } from "../fixtures";
import { ChatPage } from "../pages/chat";

test.describe("My feature", () => {
  let chatPage: ChatPage;

  test.beforeEach(async ({ page }) => {
    chatPage = new ChatPage(page);
    await chatPage.createNewChat();
  });

  test("should do something", async () => {
    await chatPage.sendUserMessage("Hello");
    await chatPage.isGenerationComplete();

    const message = await chatPage.getRecentAssistantMessage();
    expect(message.content).toContain("expected text");
  });
});
```

## CI/CD Workflows

### GitHub Actions

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `backend-lint.yml` | Push to `backend/**` | Ruff, mypy, codespell |
| `backend-test.yml` | Push to `backend/**`, `tests/**` | pytest with Postgres service |
| `lint.yml` | Push to `frontend/**` | ESLint, Prettier |
| `playwright.yml` | Push to `frontend/**` | E2E tests |
| `ci.yml` | Push/PR to `main` | Orchestrates all checks |

### Running CI Locally

```bash
# Full CI pipeline
make check

# Individual checks
make backend-lint
make backend-test
make frontend-lint
make frontend-test
```

## Test Database Docker Compose

`docker-compose.test.yml`:
```yaml
services:
  test-db:
    image: postgres:16-alpine
    container_name: knowsee-test-db
    environment:
      POSTGRES_DB: test_knowsee
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    ports:
      - "5433:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U test -d test_knowsee"]
      interval: 5s
      timeout: 5s
      retries: 5
    tmpfs:
      - /var/lib/postgresql/data  # RAM-backed for speed
```

## Coverage

Generate coverage reports:

```bash
# Backend coverage
make backend-test-cov
# Opens htmlcov/index.html

# View in terminal
uv run pytest tests/ --cov=backend/src --cov-report=term-missing
```

## Troubleshooting

### Test database connection issues

```bash
# Check if container is running
docker ps | grep knowsee-test-db

# Check container logs
docker logs knowsee-test-db

# Verify connectivity
docker exec knowsee-test-db pg_isready -U test -d test_knowsee
```

### Async event loop conflicts

Route integration tests may fail with "Task got Future attached to a different loop". This occurs because FastAPI's `get_session()` creates database connections in a different event loop than pytest-asyncio fixtures.

**Solution**: Use direct database tests (`test_db.py`) which provide equivalent coverage, or implement FastAPI dependency overrides.

### Playwright browser issues

```bash
# Reinstall browsers
cd frontend && pnpm exec playwright install --with-deps chromium
```

## Environment Variables for Testing

| Variable | Default | Description |
|----------|---------|-------------|
| `TEST_DATABASE_URL` | `postgresql+asyncpg://test:test@localhost:5433/test_knowsee` | Test database connection |
| `LOG_LEVEL` | `INFO` | Logging verbosity |
| `METRICS_ENABLED` | `true` | Prometheus metrics |
