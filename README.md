# Knowsee

Production-ready RAG agent for document retrieval and question-answering. Built with Google ADK, Vertex AI Search, and CopilotKit frontend. Includes complete infrastructure automation, data ingestion pipeline, and deployment workflows.

Generated with [`googleCloudPlatform/agent-starter-pack`](https://github.com/GoogleCloudPlatform/agent-starter-pack) version `0.17.5`

## System Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│ Frontend Layer (Next.js + CopilotKit)                                    │
│ - Modern chat UI with real-time streaming                                │
│ - Dark mode, responsive design, OKLCH colour system                      │
│ - Deployed to Cloud Run or served locally                                │
└─────────────────┬────────────────────────────────────────────────────────┘
                  │ HTTP/WebSocket
┌─────────────────▼────────────────────────────────────────────────────────┐
│ API Layer (FastAPI + AG-UI Protocol)                                     │
│ - RESTful endpoints for agent interaction                                │
│ - CORS middleware for frontend access                                    │
│ - Health checks and monitoring                                           │
└─────────────────┬────────────────────────────────────────────────────────┘
                  │ Python SDK
┌─────────────────▼────────────────────────────────────────────────────────┐
│ Agent Layer (Google ADK)                                                 │
│ - Gemini 2.5 Pro for reasoning and response generation                   │
│ - Custom tools: retrieve_docs for RAG operations                         │
│ - Session management and conversation history                            │
└─────────────────┬────────────────────────────────────────────────────────┘
                  │ Retrieval Pipeline
┌─────────────────▼────────────────────────────────────────────────────────┐
│ Retrieval Layer                                                          │
│ - Vertex AI Search for semantic search over indexed documents            │
│ - text-embedding-005 for query and document embeddings                   │
│ - Vertex AI Rank API for re-ranking retrieved results                    │
└─────────────────┬────────────────────────────────────────────────────────┘
                  │ Document Index
┌─────────────────▼────────────────────────────────────────────────────────┐
│ Data Layer (Vertex AI Search Datastore)                                  │
│ - Structured and unstructured documents                                  │
│ - Managed by Vertex AI Pipelines for ingestion                           │
│ - Chunking, embedding, and import orchestrated via KFP                   │
└──────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
knowsee/
├── app/                         # Core application
│   ├── agent.py                 # ADK agent definition with retrieval tool
│   ├── api.py                   # FastAPI API wrapper (AG-UI protocol)
│   ├── agent_engine_app.py      # Agent Engine deployment logic
│   ├── retrievers.py            # Vertex AI Search retriever implementation
│   ├── templates.py             # Document formatting for LLM context
│   └── utils/                   # Tracing, GCS, deployment utilities
├── frontend/                    # Next.js chat interface
│   ├── src/app/                 # App Router pages and API routes
│   ├── src/components/          # shadcn/ui components (Composer, MessageBubble, etc.)
│   └── README.md                # Frontend architecture and component contracts
├── data_ingestion/              # Vertex AI Pipelines for document ingestion
│   ├── data_ingestion_pipeline/ # Pipeline components and orchestration
│   └── README.md                # Pipeline architecture and usage
├── deployment/                  # Infrastructure as code
│   ├── terraform/               # Terraform modules and configurations
│   │   ├── modules/             # Reusable modules (IAM, storage, Discovery Engine)
│   │   ├── infra/               # Resource definitions (service accounts, buckets)
│   │   ├── permissions/         # IAM binding definitions
│   │   └── vars/                # Environment-specific tfvars
│   └── README.md                # Deployment workflows and architecture
├── .github/workflows/           # CI/CD pipelines (GitHub Actions)
├── tests/                       # Unit, integration, and load tests
├── notebooks/                   # Jupyter notebooks for prototyping
├── Makefile                     # Task automation
├── pyproject.toml               # Python dependencies (uv)
├── GEMINI.md                    # AI-assisted development guide
├── AGENTS.md                    # Agent-specific documentation
└── CLAUDE.md                    # Claude-specific instructions
```

## Core Components

### Agent (`app/agent.py`)
- **Model**: Gemini 2.5 Pro (reasoning), Gemini 2.5 Flash (tools)
- **Tools**: `retrieve_docs` (Vertex AI Search + Rank API)
- **Embeddings**: text-embedding-005 (768 dimensions)
- **Retrieval**: Top-10 documents, re-ranked to top-5

### API Server (`app/api.py`)
- **Framework**: FastAPI with AG-UI protocol support
- **Endpoints**:
  - `/` - Agent interaction (AG-UI protocol)
  - `/health` - Health check
  - `/info` - Agent metadata
- **Features**: CORS middleware, session management, OpenTelemetry tracing

### Frontend (`frontend/`)
- **Stack**: Next.js 15, shadcn/ui, CopilotKit
- **Features**: Real-time streaming, dark mode, responsive design
- **Deployment**: Docker + Cloud Run ready
- See [frontend/README.md](frontend/README.md) for detailed architecture

### Data Ingestion Pipeline (`data_ingestion/`)
- **Orchestration**: Vertex AI Pipelines (Kubeflow)
- **Steps**: Load → Chunk → Embed → Import to Datastore
- **Scheduling**: Cron-based for periodic updates
- See [data_ingestion/README.md](data_ingestion/README.md) for details

### Infrastructure (`deployment/terraform/`)
- **Architecture**: Multi-project (CICD, Staging, Production)
- **Resources**: Service accounts, buckets, IAM bindings, Vertex AI datastores
- **Modules**: Unified buckets module, Discovery Engine, IAM
- See [deployment/README.md](deployment/README.md) for Terraform structure

## Requirements

- **uv**: Python package manager - [Install](https://docs.astral.sh/uv/getting-started/installation/)
- **Google Cloud SDK**: GCP CLI - [Install](https://cloud.google.com/sdk/docs/install)
- **Terraform**: Infrastructure as code - [Install](https://developer.hashicorp.com/terraform/downloads)
- **Node.js 18+**: For frontend - [Install](https://nodejs.org/)
- **make**: Build automation (pre-installed on Unix systems)

## Quick Start

### Local Development

```bash
# Install Python dependencies
make install

# Option 1: ADK built-in UI (quick testing)
make playground

# Option 2: Full-stack development (API + Frontend)
make install-frontend  # First time only
make dev               # Starts API (8000) and frontend (3000)
```

Access:
- Frontend: [http://localhost:3000](http://localhost:3000)
- API Docs: [http://localhost:8000/docs](http://localhost:8000/docs)
- API Health: [http://localhost:8000/health](http://localhost:8000/health)

### Cloud Deployment

```bash
# 1. Configure development environment
# Edit deployment/terraform/vars/dev.tfvars with your project ID

# 2. Deploy infrastructure
make setup-dev-env

# 3. Run data ingestion pipeline
make data-ingestion

# 4. Deploy agent to Agent Engine
gcloud config set project <your-project-id>
make backend
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `make install` | Install Python dependencies with uv |
| `make playground` | Launch ADK built-in UI for agent testing |
| `make api` | Start FastAPI API server (port 8000) |
| `make frontend` | Start Next.js frontend (port 3000) |
| `make dev` | Start both API and frontend concurrently |
| `make install-frontend` | Install frontend dependencies (Node.js) |
| `make backend` | Deploy agent to Vertex AI Agent Engine |
| `make setup-dev-env` | Provision GCP infrastructure with Terraform |
| `make data-ingestion` | Run Vertex AI Pipelines for document ingestion |
| `make test` | Run unit and integration tests |
| `make lint` | Run code quality checks (ruff, mypy, codespell) |
| `uv run jupyter lab` | Launch Jupyter for prototyping |

## Development Workflow

### 1. Prototype Agent Logic
- Edit `app/agent.py` to define tools, prompts, and reasoning flow
- Test with `make playground` for immediate feedback
- Use `notebooks/` for experimentation and evaluation

### 2. Integrate Frontend
- API auto-reloads on agent changes
- Frontend connects via AG-UI protocol
- Customise UI in `frontend/src/components/`

### 3. Configure Infrastructure
- Edit `deployment/terraform/vars/dev.tfvars` for environment settings
- Run `make setup-dev-env` to apply changes
- Infrastructure includes: buckets, service accounts, IAM bindings, datastores

### 4. Ingest Documents
- Place documents in configured GCS bucket
- Run `make data-ingestion` to trigger pipeline
- Monitor progress in Vertex AI Pipelines console

### 5. Deploy to Cloud
- **Dev/Test**: `make backend` deploys to Agent Engine in current project
- **Production**: Configure CI/CD pipelines in `.github/workflows/`
- **Frontend**: Deploy to Cloud Run via Docker (see [frontend/README.md](frontend/README.md))

## Frontend Architecture

Modern chat interface built with:
- **UI**: shadcn/ui (Radix primitives), OKLCH colour palette, Geist fonts
- **Agent**: CopilotKit headless hooks for streaming and tool rendering
- **State**: React Context + CopilotKit session management
- **Theme**: next-themes with system-aware dark mode
- **Animations**: Motion library for polished micro-interactions

Key components:
- `AppShell` - Layout wrapper with header
- `AppSidebar` - Collapsible navigation with chat history
- `ChatContainer` - Auto-scrolling message container
- `MessageBubble` - User/assistant messages with markdown rendering
- `Composer` - Multi-line input with auto-resize

See [frontend/README.md](frontend/README.md) for complete architecture, component contracts, and extension guide.

## Data Ingestion Pipeline

Automated workflow for ingesting documents into Vertex AI Search:
1. **Load**: Fetch documents from GCS bucket
2. **Chunk**: Split documents into manageable segments
3. **Embed**: Generate embeddings using text-embedding-005
4. **Import**: Upload to Vertex AI Search datastore

Pipeline features:
- Vertex AI Pipelines orchestration (Kubeflow)
- Cron scheduling for periodic updates
- Monitoring via Vertex AI Pipelines console
- Configurable chunk size, overlap, and embedding models

See [data_ingestion/README.md](data_ingestion/README.md) for detailed usage and troubleshooting.

## Infrastructure Deployment

Terraform-managed GCP resources:
- **Multi-project architecture**: Separate CICD, Staging, Production projects
- **For development**: All projects point to single dev project
- **Resources**: Service accounts, buckets (logs, RAG pipeline, load tests), IAM bindings, Vertex AI datastores
- **Modules**: Unified buckets, Discovery Engine, IAM, enabled services

Deployment paths:
1. **Automated** (recommended): `uvx agent-starter-pack setup-cicd` - Sets up entire CI/CD pipeline
2. **Manual**: `make setup-dev-env` - Applies Terraform with dev.tfvars
3. **Production**: Configure `vars/prod.tfvars` and apply via CI/CD

See [deployment/README.md](deployment/README.md) for Terraform structure and manual deployment steps.

## Monitoring and Observability

Comprehensive observability with OpenTelemetry:
- **Tracing**: Google Cloud Trace for request flows
- **Logging**: Cloud Logging for application logs
- **Metrics**: BigQuery for long-term storage of telemetry
- **Dashboard**: [Looker Studio template](https://lookerstudio.google.com/reporting/46b35167-b38b-4e44-bd37-701ef4307418/page/tEnnC) for visualising events

Log sinks:
- Feedback logs exported to `{project}_feedback` BigQuery dataset
- Telemetry logs exported to `{project}_telemetry` BigQuery dataset

## Project Conventions

- **Package manager**: uv (not pip/poetry)
- **Python version**: 3.12
- **Code style**: ruff (line length 88, isort for imports)
- **Type checking**: mypy (strict mode)
- **Testing**: pytest (unit + integration)
- **Infrastructure**: Terraform (module-based architecture)
- **CI/CD**: GitHub Actions (lint, test, deploy)

## Troubleshooting

### Agent not retrieving documents
- Verify datastore exists: Check Vertex AI Search console
- Check embeddings: Ensure `DATA_STORE_ID` and `DATA_STORE_REGION` env vars are set
- Wait for indexing: Initial ingestion may take 5-10 minutes

### Frontend connection errors
- Verify API is running: `curl http://localhost:8000/health`
- Check environment variables: `frontend/.env.local` should have correct `NEXT_PUBLIC_AGENT_API_URL`
- Review CORS settings: `app/api.py` CORS middleware

### Terraform errors
- Run `terraform init` after module changes
- Validate configuration: `terraform validate`
- Check project permissions: Service account needs Editor role

### Pipeline failures
- Check Vertex AI Pipelines console for detailed logs
- Verify service account permissions: `{project}-knowsee-rag@{project}.iam.gserviceaccount.com`
- Ensure GCS bucket exists and is accessible

## Additional Resources

- **Component Documentation**:
  - [Frontend README](frontend/README.md) - UI architecture and component contracts
  - [Data Ingestion README](data_ingestion/README.md) - Pipeline setup and usage
  - [Deployment README](deployment/README.md) - Infrastructure and Terraform
- **Agent Starter Pack**: [Documentation](https://googlecloudplatform.github.io/agent-starter-pack/)
- **Google ADK**: [GitHub](https://github.com/google/adk-python)
- **CopilotKit**: [Documentation](https://docs.copilotkit.ai)
- **Vertex AI Search**: [Documentation](https://cloud.google.com/generative-ai-app-builder/docs/enterprise-search-introduction)

## Licence

Copyright 2025 Google LLC. Licensed under Apache 2.0.
