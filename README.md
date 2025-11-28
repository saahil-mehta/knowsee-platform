<p>
  <img src="assets/logos/links-line.png" alt="Knowsee Icon" width="48" align="left" style="margin-right: 12px;">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/knowsee-asset-dark/dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="assets/knowsee-asset-light/light.svg">
    <img alt="Knowsee Platform" src="assets/knowsee-asset-light/light.svg" width="200">
  </picture>
</p>

# Knowsee Platform

A production-ready conversational AI platform built with LangGraph and Vertex AI on Google Cloud. Features a Next.js chatbot interface powered by the Vercel AI SDK, with a FastAPI backend orchestrating LangGraph agents.

## Architecture

```
Browser (React) --> Next.js (:3000) --> FastAPI (:8000) --> LangGraph + Vertex AI
                        |                    |
                        v                    v
                    Auth.js              PostgreSQL
```

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | Next.js 15, Vercel AI SDK, shadcn/ui | Chat interface, authentication, SSR |
| Backend | FastAPI, LangGraph, Vertex AI | Agent orchestration, AI inference, streaming |
| Database | PostgreSQL, SQLAlchemy, Alembic | Persistence, migrations |
| Infrastructure | Terraform, Cloud Run, Artifact Registry | IaC, container deployment |

## Features

- **LangGraph Agents** - Stateful conversational agents with Vertex AI (Gemini)
- **Streaming Responses** - Real-time token streaming via Vercel AI SDK protocol
- **Multi-Environment** - Terraform-managed dev, staging, and production environments
- **Observability** - Structured logging, Prometheus metrics, OpenTelemetry tracing
- **Authentication** - Auth.js (NextAuth) with secure session management

## Prerequisites

- Python 3.11+
- Node.js 20+
- Docker and Docker Compose
- Google Cloud SDK (`gcloud`)
- Terraform 1.6+

### Tool Installation

```bash
# macOS (Homebrew)
brew install python@3.11 node pnpm docker terraform
brew install --cask google-cloud-sdk

# uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Quick Start

### 1. Clone and Install

```bash
git clone https://github.com/saahil-mehta/knowsee-platform.git
cd knowsee-platform
make install
```

### 2. Configure GCP

```bash
# First-time setup
gcloud auth login
gcloud auth application-default login

# Create and switch profile
gcloud config configurations create knowsee
gcloud config set project YOUR_PROJECT_ID
gcloud config set account your-email@domain.com

# Verify setup
make gcp-status
```

### 3. Environment Variables

Create `.env` in the project root:

```bash
GOOGLE_CLOUD_PROJECT=your-project-id
POSTGRES_URL=postgresql://postgres:postgres@localhost:5432/chatbot
```

### 4. Run Locally

```bash
# Option A: Full stack (recommended for new users)
make frontend          # Sets up PostgreSQL, prompts for test user credentials, starts Next.js on :3000
make local-backend     # In another terminal, starts FastAPI on :8000

# Option B: Docker Compose stack
make local             # Starts entire stack via Docker
make local-logs        # Stream logs
make local-down        # Stop stack
```

> **First-time setup**: `make frontend` automatically provisions the PostgreSQL database via Docker and prompts you to create a test user (email + password). This only happens on first run.

Visit [http://localhost:3000](http://localhost:3000) to access the chatbot.

## Development

### Make Commands

Run `make help` for all available commands. Key commands:

#### Development

| Command | Description |
|---------|-------------|
| `make install` | Install all dependencies (Python + Node) |
| `make local-backend` | Run FastAPI backend only (:8000) |
| `make frontend` | Set up database, create user, start Next.js (:3000) |

#### Quality

| Command | Description |
|---------|-------------|
| `make check` | Full CI pipeline (lint + typecheck + test + build) |
| `make lint` | Lint backend and frontend |
| `make test` | Run all tests |
| `make fmt` | Format all code (Python, TypeScript, Terraform) |

#### Deployment

| Command | Description |
|---------|-------------|
| `make release-all ENV=dev` | Build, push, and deploy both services |
| `make deploy-backend ENV=dev` | Deploy backend to Cloud Run |
| `make deploy-frontend ENV=dev` | Deploy frontend to Cloud Run |

#### Terraform

| Command | Description |
|---------|-------------|
| `make dev` | Full deploy to dev (init + plan + apply) |
| `make dev-plan` | Preview infrastructure changes |
| `make staging` | Deploy staging environment |
| `make prod` | Deploy production environment |

### Project Structure

```
knowsee-platform/
├── backend/
│   ├── src/
│   │   ├── app.py              # FastAPI application
│   │   ├── graph.py            # LangGraph agent definition
│   │   ├── stream.py           # Vercel AI SDK streaming protocol
│   │   ├── api/routes.py       # API endpoints
│   │   ├── db/                 # SQLAlchemy models and queries
│   │   └── observability/      # Logging, metrics, tracing
│   └── alembic/                # Database migrations
├── frontend/
│   ├── app/                    # Next.js App Router
│   ├── components/             # React components
│   ├── lib/                    # Utilities and API clients
│   └── tests/                  # Frontend tests
├── terraform/
│   ├── modules/                # Reusable Terraform modules
│   └── environments/           # Environment configurations
│       ├── cicd/               # CI/CD runner project
│       ├── dev/                # Development
│       ├── staging/            # Staging
│       └── prod/               # Production
├── tests/                      # Backend tests
├── docs/                       # Additional documentation
├── Makefile                    # Unified tooling
└── pyproject.toml              # Python project configuration
```

### Database Migrations

```bash
# Create a new migration
cd backend && alembic revision -m "description"

# Apply pending migrations
cd backend && alembic upgrade head

# Rollback one migration
cd backend && alembic downgrade -1
```

### GCP Profile Management

Manage multiple GCP projects seamlessly:

```bash
make gcp-switch PROFILE=knowsee-dev    # Switch to dev project
make gcp-switch PROFILE=knowsee-prod   # Switch to production
make gcp-login                          # Full re-authentication
make gcp-status                         # Show current configuration
```

See [docs/GCP_PROFILE_MANAGEMENT.md](docs/GCP_PROFILE_MANAGEMENT.md) for detailed guidance.

## Deployment

### Cloud Run Deployment

```bash
# 1. Deploy infrastructure (if not already done)
make dev

# 2. Build and deploy services
make release-all ENV=dev

# 3. Access via Cloud Run proxy (from Cloud Shell)
gcloud run services proxy knowsee-dev-frontend --port=8080 --region=europe-west2
```

### Environment Promotion

```
Local Docker --> Dev (Cloud) --> Staging --> Production
```

```bash
# Deploy to staging after dev testing
make release-all ENV=staging

# Deploy to production
make release-all ENV=prod
```

## Testing

```bash
# Run all tests
make check

# Backend only
make backend-test          # Unit + integration tests
make backend-test-unit     # Unit tests only
make backend-test-cov      # With coverage report

# Frontend only
make frontend-test         # Unit tests
make frontend-typecheck    # TypeScript checking
make frontend-lint         # Linting
```

### Test Database

```bash
make test-db-up            # Start test PostgreSQL
make backend-test-int      # Run integration tests
make test-db-down          # Stop test database
```

## Documentation

| Document | Description |
|----------|-------------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [docs/ARCH_FLOW.md](docs/ARCH_FLOW.md) | Architecture and request flows |
| [docs/GCP_PROFILE_MANAGEMENT.md](docs/GCP_PROFILE_MANAGEMENT.md) | GCP authentication guide |
| [docs/OBSERVABILITY.md](docs/OBSERVABILITY.md) | Logging, metrics, tracing setup |
| [docs/TESTING.md](docs/TESTING.md) | Testing strategy and patterns |
| [terraform/README.md](terraform/README.md) | Infrastructure documentation |

## Tech Stack

### Backend
- [FastAPI](https://fastapi.tiangolo.com/) - High-performance Python web framework
- [LangGraph](https://langchain-ai.github.io/langgraph/) - Stateful agent orchestration
- [LangChain](https://python.langchain.com/) - LLM application framework
- [Vertex AI](https://cloud.google.com/vertex-ai) - Google's managed AI platform
- [SQLAlchemy](https://www.sqlalchemy.org/) - Python SQL toolkit and ORM
- [Alembic](https://alembic.sqlalchemy.org/) - Database migrations

### Frontend
- [Next.js 15](https://nextjs.org/) - React framework with App Router
- [Vercel AI SDK](https://sdk.vercel.ai/) - AI streaming and chat utilities
- [Auth.js](https://authjs.dev/) - Authentication for Next.js
- [shadcn/ui](https://ui.shadcn.com/) - UI component library
- [Tailwind CSS](https://tailwindcss.com/) - Utility-first CSS

### Infrastructure
- [Google Cloud Platform](https://cloud.google.com/) - Cloud provider
- [Cloud Run](https://cloud.google.com/run) - Serverless containers
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [Docker](https://www.docker.com/) - Containerisation

### Tooling
- [uv](https://github.com/astral-sh/uv) - Fast Python package manager
- [pnpm](https://pnpm.io/) - Fast Node.js package manager
- [Ruff](https://github.com/astral-sh/ruff) - Python linting and formatting
- [Biome](https://biomejs.dev/) - Frontend linting and formatting

## Licence

[MIT](LICENSE)
