# Knowsee Platform

Unified workspace that pairs the **sagent** ADK RAG agent with a polished conversational UI so the frontend, agent backend, ingestion pipeline, and infrastructure live in one repo.

## Overview
- **Backend (`app/`)** – Google ADK (Agent Development Kit) powered FastAPI stack for retrieval-augmented generation with Vertex AI integration, agent orchestration, and streaming responses.
- **Frontend** – AG-UI + CopilotKit integration (to be implemented) for production-grade chat interface with native ADK protocol support.
- **Infrastructure (`terraform/`)** – Shared modules and environment folders (`staging`, `prod`) managing Cloud Run, Vertex AI connections, and IAM via Terraform.
- **Data (`data_ingestion/`)** – Pipelines that push curated docs into Vertex AI Search for grounding.

`GEMINI.md` contains context for AI copilots, and the intro notebooks under `notebooks/` walk through agent prototyping + evaluation.

## Architecture Decision: Why AG-UI + CopilotKit

### The Problem with Generic UI Frameworks

Initially, we attempted to use **assistant-ui** with a custom translation layer to connect to our ADK backend. This approach revealed fundamental architectural incompatibilities:

**Protocol Mismatch:**
- ADK uses a native SSE (Server-Sent Events) protocol optimized for agent communication
- assistant-ui expects the Data Stream Protocol (different message format, state management, and tool calling conventions)
- Required a 380-line translation layer (`frontend/app/api/chat/route.ts`) manually converting between formats

**State Management Conflict:**
- ADK manages conversation state server-side via Vertex AI Agent Engines
- assistant-ui manages state client-side in React
- Created race conditions where both systems claimed authority over conversation history, leading to "Invalid Session resource name" errors

**Session Lifecycle Issues:**
- ADK expects sessions to be created via Agent Engine API before first message
- assistant-ui generates random UUIDs and assumes stateless backend
- No way to properly initialize sessions without deep modifications to both sides

**Developer Experience:**
- Required React/TypeScript/Tailwind expertise to customize
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
- Customizable via props, not deep React code

**Proper State Synchronization:**
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
├── deployment/terraform/dev    # Lightweight dev project bootstrap
├── dev/                        # Docker-compose stack + mock API
├── notebooks/                  # Evaluation + prototyping notebooks
├── terraform/                  # IaC (modules, infra, environments/{staging,prod})
├── tests/                      # Backend unit + integration suites
├── Makefile                    # Unified automation entrypoint
└── README.md                   # This file
```

**Note:** Frontend directory removed pending AG-UI + CopilotKit implementation. Use ADK's built-in dev-ui at `http://localhost:8000/dev-ui` for testing.

## Prerequisites
- **Node.js 24+** (required for AG-UI + CopilotKit when implemented)
- Python 3.11+ and [uv](https://docs.astral.sh/uv/getting-started/installation/) (auto-installed by `make install`)
- Docker & Docker Compose v2
- Google Cloud SDK (configured with the desired project)
- Terraform ≥ 1.6
- Make, curl, and bash (default on macOS/Linux)

## Quick Start

### Backend Development
1. **Install Python dependencies**
   ```bash
   make install  # uv sync
   ```

2. **Run the ADK playground (Streamlit) during agent development**
   ```bash
   make playground  # http://localhost:8501
   ```

3. **Run FastAPI backend with built-in dev UI**
   ```bash
   make local-backend  # http://localhost:8000
   # Access dev UI: http://localhost:8000/dev-ui
   ```

4. **Check quality gates before committing**
   ```bash
   make backend-lint  # codespell, ruff, mypy
   make backend-test  # unit + integration tests
   ```

### Frontend (Coming Soon: AG-UI + CopilotKit)

The polished chat interface will be implemented using AG-UI + CopilotKit. For now, use:
- **Built-in ADK Dev UI:** `http://localhost:8000/dev-ui` (full agent testing interface)
- **API Endpoint:** `http://localhost:8000/run_sse` (SSE streaming for custom clients)

## Key Make Targets
| Target | Description |
| ------ | ----------- |
| `install` | Install uv if missing, sync Python deps |
| `playground` | Launch ADK Streamlit playground on port 8501 |
| `local-backend` | Start FastAPI locally with hot reload on `localhost:8000` |
| `fs` | Start backend, wait for readiness (use when frontend is implemented) |
| `backend-lint` | Run codespell, Ruff, Mypy |
| `backend-test` | Run unit + integration tests |
| `data-ingestion` | Submit the Vertex AI data ingestion pipeline |
| `setup-dev-env` | Provision minimal dev infra via `deployment/terraform/dev` |
| `deploy` | Deploy backend to Cloud Run |
| `fmt`, `validate`, `clean` | Terraform hygiene commands |
| `staging` / `prod` | Run `init → plan → apply → output` for each environment |

Run `make help` anytime to see the full catalog.

## Development Workflows

### ADK Agent (`app/`, `data_ingestion/`)
- Modify `app/agent.py` to change retrieval or response logic. The FastAPI adapter lives in `app/fast_api_app.py`.
- Use `make local-backend` for a tight loop or `make playground` for a UI-driven testing surface.
- Update embeddings or corpora, then execute `make data-ingestion` to push fresh docs into Vertex AI Search (requires `gcloud auth login` and proper IAM).
- Backend QA: `make backend-test` (unit + integration) and `make backend-lint` (codespell, Ruff, Mypy).

**Current Agent Capabilities:**
- RAG retrieval via Vertex AI Search + Vector Search
- Document re-ranking with Vertex AI Rank API
- Streaming responses with Gemini 2.0 Flash
- Tool calling with `retrieve_docs` function
- Session management via Vertex AI Agent Engines

### Dockerized Stack (`dev/`)
- `make dev-up` / `make dev-down` build and orchestrate the mock API and Redis services.
- `make dev-logs` tails combined container logs; `make dev-health` pings the FastAPI endpoint until healthy.
- Customize services via `dev/docker-compose.yml` and the FastAPI code under `dev/api/`.

## Data & Infrastructure

### Terraform Environments
- Root modules live under `terraform/modules`, while reusable definitions (networking, IAM, infra) sit in `terraform/infra` and `terraform/permissions`.
- Environment-specific state and vars are kept in `terraform/environments/staging|prod`. Copy `terraform.tfvars.example` if you need a new workspace.
- Typical flow:
  ```bash
  make staging-plan      # only plan
  make staging           # init → plan → apply → output
  make staging-destroy   # tear down staging
  ```
- `make fmt` and `make validate` keep the configurations clean before pushing.

### Data Ingestion Pipeline
- The pipeline defined in `data_ingestion_pipeline/submit_pipeline.py` writes to `gs://<project>-sagent-rag` and expects a service account named `sagent-rag@<project>.iam.gserviceaccount.com`.
- Ensure the `DATA_STORE_ID` and region flags match your Vertex AI Search deployment before running `make data-ingestion`.

### Developer Sandbox Project
- `make setup-dev-env` boots the minimal GCP resources (datastore, service accounts, secrets) defined in `deployment/terraform/dev`. Supply overrides in `deployment/terraform/dev/vars/env.tfvars`.

## Deployment

### Backend to Cloud Run
```bash
gcloud config set project <your-project>
make deploy    # optional: make deploy IAP=true PORT=8080
```

The backend includes:
- FastAPI app with ADK integration
- OpenTelemetry tracing to Cloud Trace
- Structured logging to Cloud Logging
- GCS artifact storage
- Vertex AI Agent Engines session management

### Frontend (When Implemented)
Will deploy as a separate Cloud Run service using AG-UI + CopilotKit stack. The architecture will be:
- Next.js server for SSR
- AG-UI runtime handling ADK communication
- CopilotKit components for UI
- Environment variables for ADK backend URL

## Monitoring & Observability
- OpenTelemetry traces/logs are emitted from `app/` to Cloud Trace and Logging, with persistent storage in BigQuery.
- The Looker Studio dashboard template (https://lookerstudio.google.com/reporting/46b35167-b38b-4e44-bd37-701ef4307418/page/tEnnC) visualizes the events; follow the dashboard "Setup Instructions" tab to point it at your dataset.

## Current State & Roadmap

### ✅ Completed
- ADK agent with RAG retrieval and re-ranking
- FastAPI backend with streaming SSE responses
- Vertex AI Search integration
- Built-in ADK dev UI for testing
- Infrastructure as code (Terraform)
- Data ingestion pipeline
- Monitoring and observability

### 🚧 In Progress
- AG-UI + CopilotKit frontend integration
- Custom tool UI components for `retrieve_docs`

### 📋 Planned
- Multi-turn conversation improvements
- Custom themes and branding
- User authentication and authorization
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

### OpenAPI Schema Generation Errors
The ADK backend contains Pydantic models with `httpx.Client` fields that cannot be serialized to JSON schema. This doesn't affect functionality—the `/openapi.json` endpoint fails, but all other endpoints work correctly. Makefile health checks use `/` instead.
