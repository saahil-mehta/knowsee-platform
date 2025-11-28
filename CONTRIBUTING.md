# Contributing to Knowsee Platform

Thank you for your interest in contributing to Knowsee Platform. This document provides guidelines and workflows for contributing effectively.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style](#code-style)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)
- [Infrastructure Changes](#infrastructure-changes)

## Getting Started

### Prerequisites

Ensure you have the following installed:

- Python 3.11+
- Node.js 20+ with pnpm
- Docker and Docker Compose
- Google Cloud SDK (`gcloud`)
- Terraform 1.6+

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/your-org/knowsee-platform.git
cd knowsee-platform

# Install dependencies
make install

# Configure git hooks
git config commit.template .gitmessage.txt

# Set up GCP authentication
make gcp-login
make gcp-switch PROFILE=your-profile
```

### Environment Configuration

Create a `.env` file in the project root:

```bash
GOOGLE_CLOUD_PROJECT=your-project-id
POSTGRES_URL=postgresql://postgres:postgres@localhost:5432/chatbot
```

For frontend development, create `frontend/.env.local`:

```bash
BACKEND_URL=http://localhost:8000
AUTH_SECRET=your-auth-secret
```

## Development Workflow

### Running Locally

```bash
# Terminal 1: Start frontend with database
make frontend

# Terminal 2: Start backend
make local-backend
```

### Available Make Commands

Run `make help` for a complete list. Key commands:

| Command | Purpose |
|---------|---------|
| `make install` | Install all dependencies |
| `make fmt` | Format all code |
| `make lint` | Lint backend and frontend |
| `make check` | Full CI pipeline |
| `make test` | Run all tests |

### Branch Strategy

```
main
 └── feature/your-feature-name
 └── fix/bug-description
 └── refactor/what-changed
```

Create feature branches from `main`:

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

## Code Style

### Python (Backend)

We use [Ruff](https://github.com/astral-sh/ruff) for linting and formatting:

```bash
# Format code
uv run ruff format .

# Check and auto-fix linting issues
uv run ruff check --fix .

# Type checking
uv run mypy backend/src
```

Configuration is in `pyproject.toml`:

- Line length: 100 characters
- Target Python version: 3.11
- Import sorting: enabled

### TypeScript (Frontend)

We use [Biome](https://biomejs.dev/) via Ultracite for formatting:

```bash
# Format and lint
cd frontend && pnpm exec ultracite fix

# Type check
pnpm tsc --noEmit
```

### Terraform

```bash
# Format all Terraform files
terraform fmt -recursive terraform/
```

### Formatting Everything

```bash
# Format backend, frontend, and Terraform
make fmt
```

## Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/). Configure the commit template:

```bash
git config commit.template .gitmessage.txt
```

### Commit Format

```
<type>(<optional-scope>): <subject>

<optional body>
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Code style changes (formatting, no logic change) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Routine tasks, dependency updates |
| `ci` | CI/CD configuration changes |
| `build` | Build system or external dependency changes |
| `revert` | Revert a previous commit |

### Examples

```bash
# Feature
feat(backend): add retry logic to LangGraph agent

# Bug fix
fix(frontend): resolve hydration mismatch in chat component

# With scope
refactor(terraform): consolidate service account modules

# Documentation
docs: update deployment instructions in README
```

### Subject Rules

- Use lowercase
- Use imperative mood ("add" not "added" or "adds")
- No period at the end
- Keep under 72 characters

## Pull Request Process

### Before Submitting

1. **Run the full check suite**:
   ```bash
   make check
   ```

2. **Ensure tests pass**:
   ```bash
   make test
   ```

3. **Update documentation** if you changed:
   - Public APIs
   - Configuration options
   - Infrastructure
   - Make commands

4. **Rebase on main**:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

### PR Description Template

```markdown
## Summary

Brief description of changes.

## Changes

- Change 1
- Change 2

## Testing

- [ ] Unit tests pass (`make backend-test-unit`)
- [ ] Integration tests pass (`make backend-test-int`)
- [ ] Frontend tests pass (`make frontend-test`)
- [ ] Full check passes (`make check`)

## Related Issues

Closes #123
```

### Review Process

1. At least one approval required
2. All CI checks must pass
3. No unresolved conversations
4. Squash and merge preferred

## Testing

### Backend Tests

```bash
# All backend tests
make backend-test

# Unit tests only
make backend-test-unit

# Integration tests (requires test database)
make test-db-up
make backend-test-int
make test-db-down

# With coverage
make backend-test-cov
```

### Frontend Tests

```bash
# Unit tests
make frontend-test-unit

# Type checking
make frontend-typecheck

# Linting
make frontend-lint
```

### Full CI Pipeline

```bash
# Runs everything: lint, typecheck, test, build
make check
```

### Writing Tests

#### Backend (pytest)

```python
# tests/unit/test_example.py
import pytest
from backend.src.module import function_to_test

def test_function_returns_expected_value():
    result = function_to_test("input")
    assert result == "expected"

@pytest.mark.asyncio
async def test_async_function():
    result = await async_function()
    assert result is not None
```

#### Frontend (Vitest)

```typescript
// tests/unit/example.test.ts
import { describe, it, expect } from 'vitest'
import { functionToTest } from '@/lib/module'

describe('functionToTest', () => {
  it('returns expected value', () => {
    const result = functionToTest('input')
    expect(result).toBe('expected')
  })
})
```

## Infrastructure Changes

### Terraform Workflow

```bash
# 1. Make changes to terraform/ files

# 2. Format
terraform fmt -recursive terraform/

# 3. Validate
make dev-validate

# 4. Plan (review changes)
make dev-plan

# 5. Apply (after PR approval)
make dev-apply
```

### Environment Promotion

```
dev --> staging --> prod
```

1. Test changes in `dev` environment first
2. Deploy to `staging` for pre-production validation
3. Deploy to `prod` after staging verification

### Adding New Infrastructure

1. Create or update modules in `terraform/modules/`
2. Add configuration to `terraform/environments/<env>/infra/`
3. Reference in `terraform/environments/<env>/main.tf`
4. Update `terraform/README.md`
5. Test in dev before deploying to staging/prod

## GCP Profile Management

When working with multiple GCP projects:

```bash
# Switch profiles
make gcp-switch PROFILE=knowsee-dev
make gcp-switch PROFILE=knowsee-staging

# Re-authenticate (when credentials expire)
make gcp-login

# Check current configuration
make gcp-status
```

See [docs/GCP_PROFILE_MANAGEMENT.md](docs/GCP_PROFILE_MANAGEMENT.md) for detailed guidance.

## Getting Help

- Review existing [documentation](docs/)
- Check [issues](https://github.com/your-org/knowsee-platform/issues) for similar problems
- Open a new issue with a clear description

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow
