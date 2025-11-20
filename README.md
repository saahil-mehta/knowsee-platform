# Knowsee Platform

Unified workspace that pairs the **sagent** ADK RAG agent with a polished conversational UI so the frontend, agent backend, ingestion pipeline, and infrastructure live in one repo.

## Overview
- **Backend (`app/`)** – Google ADK (Agent Development Kit) powered FastAPI stack for retrieval-augmented generation with Vertex AI integration, agent orchestration, and streaming responses.
- **Frontend (`frontend/`)** – Next.js application with AG-UI + CopilotKit integration for production-grade chat interface with native ADK protocol support.
- **Infrastructure (`terraform/`)** – Modular Terraform managing Cloud Run, Vertex AI connections, and IAM across four environments (cicd, dev, staging, prod).
- **Data (`data_ingestion/`)** – Pipelines that push curated docs into Vertex AI Search for grounding.

`GEMINI.md` contains context for AI copilots, and the intro notebooks under `notebooks/` walk through agent prototyping + evaluation.

## Architecture Decision: Why AG-UI + CopilotKit

### The Problem with Generic UI Frameworks

Initially, we attempted to use **assistant-ui** with a custom translation layer to connect to our ADK backend. This approach revealed fundamental architectural incompatibilities:

**Protocol Mismatch:**
- ADK uses a native SSE (Server-Sent Events) protocol optimised for agent communication
- assistant-ui expects the Data Stream Protocol (different message format, state management, and tool calling conventions)
- Required a 380-line translation layer (`frontend/app/api/chat/route.ts`) manually converting between formats

**State Management Conflict:**
- ADK manages conversation state server-side via Vertex AI Agent Engines
- assistant-ui manages state client-side in React
- Created race conditions where both systems claimed authority over conversation history, leading to "Invalid Session resource name" errors

**Session Lifecycle Issues:**
- ADK expects sessions to be created via Agent Engine API before first message
- assistant-ui generates random UUIDs and assumes stateless backend
- No way to properly initialise sessions without deep modifications to both sides

**Developer Experience:**
- Required React/TypeScript/Tailwind expertise to customise
- 2,500+ lines of boilerplate UI code to maintain
- Every ADK protocol update required translation layer changes

### Why AG-UI + CopilotKit is the Solution

**Native ADK Integration:**
- AG-UI is Google's official protocol for connecting ADK agents to frontends
- Announced September 2024 as the recommended approach for ADK UIs
- Uses `ag-ui-adk` Python adapter that wraps ADK agents with zero translation

**Production-Ready Components:**
- CopilotKit provides polished React components (`<CopilotSidebar>`, `<CopilotChat>`)
- Built-in dark mode, animations, accessibility
- Customisable via props, not deep React code

**Proper State Synchronisation:**
- `useCoAgent` hook automatically syncs frontend/backend state
- ADK manages sessions correctly via Agent Engine API
- No race conditions or session errors

**Generative UI Support:**
- Tools can render custom React components via `render` prop
- Example: `retrieve_docs` can show formatted document cards instead of raw text

**Minimal Code:**
- ~100 lines vs 2,500+ lines with assistant-ui
- Backend: Wrap agent with `ADKAgent()`, add to FastAPI
- Frontend: `<CopilotKit>` provider + `<CopilotSidebar>` component

**Example:**
```python
# Backend: app/fast_api_app.py
from ag_ui_adk import ADKAgent, add_adk_fastapi_endpoint

adk_agent = ADKAgent(
    adk_agent=root_agent,  # Your existing agent!
    app_name="app"
)
add_adk_fastapi_endpoint(app, adk_agent, path="/copilot")
```

```typescript
// Frontend: Simple integration
<CopilotKit runtimeUrl="/api/copilotkit" agent="knowsee_agent">
  <CopilotSidebar defaultOpen={true} />
</CopilotKit>
```

## Project Structure
```
knowsee-platform/
├── app/                        # ADK agent application (FastAPI, agent logic)
│   ├── agent.py                # RAG agent with retrieve_docs tool
│   ├── fast_api_app.py         # FastAPI + ADK integration
│   ├── retrievers.py           # Vertex AI Search retriever
│   └── app_utils/              # GCS, tracing, typing utilities
├── data_ingestion/             # Vertex AI data ingestion pipeline
├── frontend/                   # Next.js app with AG-UI + CopilotKit
│   ├── src/                    # React components and pages
│   ├── Dockerfile              # Production build
│   └── Dockerfile.local        # Local development build
├── local/                      # Docker Compose for local development
│   └── docker-compose.sagent.yml  # Backend + frontend stack
├── notebooks/                  # Evaluation + prototyping notebooks
├── terraform/                  # Infrastructure as code
│   ├── modules/                # Reusable Terraform modules
│   ├── infra/                  # Shared infrastructure definitions
│   └── environments/           # Environment-specific configs
│       ├── cicd/               # CI/CD runner project
│       ├── dev/                # Development cloud environment
│       ├── staging/            # Staging (mirrors prod)
│       └── prod/               # Production
├── tests/                      # Backend unit + integration suites
├── Makefile                    # Unified automation entrypoint
└── README.md                   # This file
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- **Complete GCP setup guide** (Knowsee project access, personal projects, multiple profiles)
- Development workflow and best practices
- Code quality guidelines
- Pull request process

## Prerequisites
- **Node.js 24+** (required for AG-UI + CopilotKit)
- Python 3.11+ and [uv](https://docs.astral.sh/uv/getting-started/installation/) (auto-installed by `make install`)
- Docker & Docker Compose v2
- Google Cloud SDK - see [CONTRIBUTING.md](CONTRIBUTING.md#gcp-profile-management) for setup
- Terraform ≥ 1.6
- Make, curl, and bash (default on macOS/Linux)

## Quick Start

```bash
# Install dependencies
make install

# Run the ADK playground for agent development
make playground  # http://localhost:8501

# Or run backend locally with built-in dev UI
make local-backend  # http://localhost:8000/dev-ui

# Full local stack (backend + frontend)
make local  # http://localhost:3000

# See all available commands
make help
```

## Key Make Targets

### Development
| Target | Description |
| ------ | ----------- |
| `make install` | Install uv (if missing) and sync Python + frontend dependencies |
| `make playground` | Launch ADK Streamlit playground on port 8501 |
| `make local-backend` | Start FastAPI backend locally with hot reload on `localhost:8000` |
| `make local` | Start full local stack (backend + frontend) via Docker Compose |
| `make local-down` | Stop local stack |
| `make local-logs` | Stream combined logs from local stack |
| `make local-logs-backend` | Stream backend logs only |
| `make local-logs-frontend` | Stream frontend logs only |

### Quality & Testing
| Target | Description |
| ------ | ----------- |
| `make backend-lint` | Run codespell, Ruff, Mypy on backend code |
| `make backend-test` | Run unit + integration tests |
| `make frontend-lint` | Run ESLint on frontend code |
| `make frontend-test` | Run frontend tests |
| `make frontend-typecheck` | Run TypeScript type checking |
| `make check` / `make ci` | Run full test suite (lint + typecheck + test + build) |

### Docker Build & Deploy
| Target | Description |
| ------ | ----------- |
| `make build-backend ENV=<env>` | Build and push backend Docker image |
| `make build-frontend ENV=<env>` | Build and push frontend Docker image |
| `make deploy-backend ENV=<env>` | Deploy backend to Cloud Run |
| `make deploy-frontend ENV=<env>` | Deploy frontend to Cloud Run |
| `make release-backend ENV=<env>` | Build, push, and deploy backend (all-in-one) |
| `make release-frontend ENV=<env>` | Build, push, and deploy frontend (all-in-one) |
| `make release-all ENV=<env>` | Release both backend and frontend |

**Note:** `ENV` must be one of: `dev`, `staging`, `prod`

### Terraform
| Target | Description |
| ------ | ----------- |
| `make <env>-init` | Initialise Terraform for environment (cicd, dev, staging, prod) |
| `make <env>-plan` | Plan infrastructure changes |
| `make <env>-apply` | Apply infrastructure changes |
| `make <env>-output` | Show Terraform outputs |
| `make <env>-destroy` | Destroy infrastructure (use with caution!) |
| `make <env>` | Full deploy: init → plan → apply → output |
| `make fmt` | Format all Terraform files |
| `make validate` | Validate Terraform configurations |
| `make clean` | Clean Terraform cache files |

### GCP Profile Management
| Target | Description |
| ------ | ----------- |
| `make gcp-switch PROFILE=<name>` | Switch GCP profile and update .env |
| `make gcp-login` | Full GCP authentication (CLI + ADC) |
| `make gcp-status` | Show current GCP profile and project |
| `make gcp-setup` | Get started with GCP (setup help) |

### Data Pipeline
| Target | Description |
| ------ | ----------- |
| `make data-ingestion` | Submit Vertex AI data ingestion pipeline |

Run `make help` anytime to see the full catalogue.

## Development Workflows

### Backend Development (ADK Agent)

The backend is a FastAPI application powered by Google's Agent Development Kit (ADK).

**Core files:**
- `app/agent.py` - RAG agent definition with `retrieve_docs` tool
- `app/fast_api_app.py` - FastAPI server with ADK integration
- `app/retrievers.py` - Vertex AI Search retriever logic
- `app/app_utils/` - Utilities for GCS, tracing, and typing

**Development loop:**
1. **Quick iteration:** `make local-backend` for hot-reload FastAPI server
2. **UI-driven testing:** `make playground` for Streamlit-based agent playground
3. **Local testing:** Modify `app/agent.py`, save, and test immediately
4. **Quality checks:** `make backend-lint` and `make backend-test` before committing

**Current agent capabilities:**
- RAG retrieval via Vertex AI Search + Vector Search
- Document re-ranking with Vertex AI Rank API
- Streaming responses with Gemini 2.0 Flash
- Tool calling with `retrieve_docs` function
- Session management via Vertex AI Agent Engines

### Frontend Development (AG-UI + CopilotKit)

The frontend is a Next.js application using AG-UI for native ADK integration and CopilotKit for polished UI components.

**Core files:**
- `frontend/src/` - React components and pages
- `frontend/Dockerfile` - Production build (multi-stage)
- `frontend/Dockerfile.local` - Local development build

**Development loop:**
1. **Local development:** `make local` runs full stack via Docker Compose
2. **Frontend only:** `cd frontend && npm run dev` for Next.js hot reload
3. **Type checking:** `make frontend-typecheck` to catch TypeScript errors
4. **Linting:** `make frontend-lint` to enforce code style
5. **Testing:** `make frontend-test` to run test suite

### Local Full Stack Development

The `local/` directory contains Docker Compose configuration for running the entire stack locally.

**Architecture:**
- **Backend container:** Runs the ADK agent backend (FastAPI)
- **Frontend container:** Runs the Next.js frontend (AG-UI + CopilotKit)
- **Network:** Both containers communicate via `sagent-stack` network
- **Credentials:** Mounts your `~/.config/gcloud` for Vertex AI access

**Commands:**
```bash
# Start everything
make local

# View logs
make local-logs                 # Combined
make local-logs-backend         # Backend only
make local-logs-frontend        # Frontend only

# Stop everything
make local-down

# Restart services
make local-restart

# Check status
make local-status
```

**Ports:**
- Frontend: `http://localhost:3000`
- Backend: `http://localhost:8000`
- Backend Dev UI: `http://localhost:8000/dev-ui`

### Data Ingestion Pipeline

Update the knowledge base by ingesting documents into Vertex AI Search.

**Requirements:**
- `gcloud auth login` (authenticated CLI)
- Proper IAM permissions (Vertex AI user, storage admin)
- Service account: `sagent-rag@<project>.iam.gserviceaccount.com`

**Run:**
```bash
make data-ingestion
```

This submits the pipeline defined in `data_ingestion_pipeline/submit_pipeline.py`, which:
1. Reads documents from local storage
2. Processes and chunks them
3. Uploads to Vertex AI Search datastore
4. Creates embeddings for vector search

### Infrastructure Management

All infrastructure is managed via Terraform with separate environments.

**Environment structure:**
- **cicd** - CI/CD runner project (GitHub Actions, Artifact Registry)
- **dev** - Development cloud environment (for testing before staging)
- **staging** - Pre-production (mirrors prod configuration)
- **prod** - Production environment

**Typical workflow:**
```bash
# Deploy to dev first
make dev-plan          # Review changes
make dev-apply         # Apply changes
make dev-output        # View outputs

# Test in dev, then promote to staging
make staging

# Finally deploy to production
make prod
```

**Infrastructure includes:**
- Cloud Run services (backend + frontend)
- Vertex AI Discovery Engine (datastore + search engine)
- Service accounts with proper IAM bindings
- Storage buckets (RAG pipeline, logs)
- BigQuery datasets (telemetry, feedback)
- Log sinks to BigQuery
- Artifact Registry (Docker images)
- GitHub Workload Identity Federation (for CI/CD)

See `terraform/README.md` for detailed documentation on the infrastructure architecture.

## Deployment

### Building and Deploying Services

**Option 1: Full release (build + push + deploy)**
```bash
# Deploy backend to dev
make release-backend ENV=dev

# Deploy frontend to dev
make release-frontend ENV=dev

# Deploy both
make release-all ENV=dev
```

**Option 2: Step-by-step**
```bash
# Build and push images
make build-backend ENV=dev
make build-frontend ENV=dev

# Deploy to Cloud Run
make deploy-backend ENV=dev
make deploy-frontend ENV=dev
```

**Option 3: Infrastructure only**
```bash
# Just apply Terraform changes (assumes images already built)
make dev-apply
```

### Deployment Architecture

**Backend (Cloud Run):**
- FastAPI app with ADK integration
- OpenTelemetry tracing to Cloud Trace
- Structured logging to Cloud Logging
- GCS artifact storage
- Vertex AI Agent Engines session management
- Service account: `knowsee-<env>-app@<project>.iam.gserviceaccount.com`

**Frontend (Cloud Run):**
- Next.js server for SSR
- AG-UI runtime handling ADK communication
- CopilotKit components for UI
- Environment variables for backend URL
- Service account: `knowsee-<env>-app@<project>.iam.gserviceaccount.com`

## Monitoring & Observability

- OpenTelemetry traces/logs are emitted from `app/` to Cloud Trace and Logging, with persistent storage in BigQuery.
- The Looker Studio dashboard template (https://lookerstudio.google.com/reporting/46b35167-b38b-4e44-bd37-701ef4307418/page/tEnnC) visualises the events; follow the dashboard "Setup Instructions" tab to point it at your dataset.

## Current State & Roadmap

### ✅ Completed
- ADK agent with RAG retrieval and re-ranking
- FastAPI backend with streaming SSE responses
- Vertex AI Search integration
- Next.js frontend with AG-UI + CopilotKit
- Built-in ADK dev UI for testing
- Infrastructure as code (Terraform)
- Data ingestion pipeline
- Monitoring and observability
- Local development stack (Docker Compose)

### 🚧 In Progress
- Custom tool UI components for `retrieve_docs`
- Enhanced conversation history UI

### 📋 Planned
- Multi-turn conversation improvements
- Custom themes and branding
- User authentication and authorisation
- Conversation history persistence
- Analytics dashboard

## Additional Tips
- Keep `GEMINI.md` updated so AI assistants understand custom commands, secrets, and architecture.
- Notebooks under `notebooks/` demonstrate evaluation harnesses; start with the intro notebook to benchmark prompt changes before redeploying.
- When adding new infrastructure, mirror the `staging` folder first, validate, then promote to `prod` via the same Make targets for consistency.
- For frontend development, reference the AG-UI starter kit at `/Users/saahil/Documents/GitHub/with-adk` (Node 24 required).

## Troubleshooting

### "Invalid Session resource name" Error
This was the core issue with assistant-ui. AG-UI resolves this by properly managing sessions via the ADK adapter.

### Node Version Issues
AG-UI + CopilotKit require Node 24+. Install via:
```bash
brew install node@24
brew link node@24 --force
echo 'export PATH="/opt/homebrew/opt/node@24/bin:$PATH"' >> ~/.zshrc
```

### Local Stack Not Starting
```bash
# Check if ports are already in use
lsof -ti:3000 -ti:8000

# Rebuild containers
make local-down
docker system prune -f
make local
```

### GCP Authentication Issues
```bash
# Full authentication flow
make gcp-login

# Check current status
make gcp-status

# Switch to correct profile
make gcp-switch PROFILE=<your-profile>
```

### OpenAPI Schema Generation Errors
The ADK backend contains Pydantic models with `httpx.Client` fields that cannot be serialised to JSON schema. This doesn't affect functionality—the `/openapi.json` endpoint fails, but all other endpoints work correctly. Makefile health checks use `/` instead.
