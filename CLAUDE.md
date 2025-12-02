# Project Details - Knowsee Platform - AI Context
A conversational AI platform with LangGraph agents (FastAPI backend) and Next.js chatbot frontend, deployed on Google Cloud Run.
 ## Architecture Overview
Browser → Next.js (:3000) → FastAPI (:8000) → LangGraph + Vertex AI (MaaS, currently 2.5 Flash)
                │                    │
            Auth.js              PostgreSQL

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `backend/src/` | FastAPI app, LangGraph agents, SQLAlchemy models |
| `frontend/` | Next.js 15 App Router, Vercel AI SDK, shadcn/ui |
| `terraform/` | IaC with environment modules (dev/staging/prod) |
| `tests/` | Backend pytest suite (unit + integration) |
| `docs/` | Architecture, observability, testing guides |

### Key Backend Files
- `app.py` - FastAPI routes, health checks, CORS
- `graph.py` - LangGraph state machine with ChatState, chatbot_node
- `stream.py` - Vercel AI SDK Data Stream Protocol (SSE)
- `db/models.py` - User, Chat, Message_v2, Vote_v2, Document, Suggestion
- `db/queries.py` - Async database operations

### Key Frontend Files
- `app/(auth)/` - Login, register, NextAuth config
- `app/(chat)/` - Chat pages and API routes
- `components/` - Chat, Artifact, CodeEditor, DataStreamHandler
- `lib/db/` - Drizzle queries mirroring backend SQLAlchemy

## Tech Stack
| Layer | Technologies |
|-------|--------------|
| Backend | FastAPI, LangGraph, LangChain, Vertex AI, SQLAlchemy 2.0, asyncpg |
| Frontend | Next.js 15, Vercel AI SDK 5, Auth.js, shadcn/ui, Tailwind CSS 4 |
| Database | PostgreSQL 16 with Alembic migrations |
| Infra | GCP Cloud Run, Artifact Registry, Terraform |
| Tooling | uv (Python), pnpm (Node), Ruff, Biome, Docker |

## Development Commands

**Always use Make targets** - never raw Docker/npm/uv commands. Unless absolutely necessary. Run `make help` to understand the commands.

## Guiding Principles
- Redundancy is your enemy - KISS, DRY, YAGNI
- Reliability and Simplicity are the mottos
- Root cause thinking - Find the simplest systems solution
- Small increments - One feature → implement → test → verify → build
- Project tooling - Always use make targets, not raw commands

## Code Style

  ### Python

  - Line length: 100
  - snake_case functions, PascalCase classes
  - Ruff for linting (E, F, I, W rules)
  - mypy for type checking

  ### TypeScript

  - Biome (ultracite) for formatting
  - camelCase variables, PascalCase components
  - Line length: 120

  ### Naming

  Proper descriptive names only:
  - NO: gdrive, cfg, mgr
  - YES: google_drive, config, manager

## Commit Policy
Use conventional commits (see .gitmessage.txt):
<type>(<scope>): <subject>

Types: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert
  - Subject in lowercase, imperative mood
  - Group commits by theme
  - Never co-author

## Output Policy
  - UK English spelling
  - No emojis
  - No unnecessary documentation
  - Always provide honest critical assessment under CRITICAL_ASSESSMENT

## Database Migrations

  cd backend && alembic revision -m "description"  # Create
  cd backend && alembic upgrade head               # Apply

  GCP Operations

  make gcp-login                    # Full authentication
  make gcp-switch PROFILE=<name>    # Switch project
  make gcp-status                   # Current config

## Knowledge Guidance

  ### Common Gotchas

  1. Test database - Integration tests need make test-db-up first (port 5433)
  2. Streaming - Chat API returns SSE, not JSON. Use appropriate parsers
  3. Auth flow - NextAuth validates against PostgreSQL via backend API
  4. JSONB columns - parts, attachments, lastContext are JSONB, handle serialisation
  5. Composite keys - Document table uses (id, createdAt) composite primary key

  ### Reference Documentation

  - README.md - Quick start and project overview
  - CONTRIBUTING.md - PR process and testing
  - docs/ARCH_FLOW.md - Request flow diagrams
  - docs/OBSERVABILITY.md - Logging, metrics, tracing
  - docs/TESTING.md - Test patterns and fixtures