# Knowsee Platform

Unified workspace that pairs the **sagent** ADK RAG agent with the Knowsee Next.js frontend so the conversational UI, ingestion pipeline, and infrastructure live in one repo.

## Overview
- **Frontend (`frontend/`)** – Next.js 15 + Tailwind experience that streams responses from GPT-OSS-120B (or any OpenAI-compatible endpoint) and ships via Cloud Run.
- **Backend (`app/` + `dev/api/`)** – ADK-generated FastAPI stack for retrieval-augmented chat plus a lightweight mock API for local docker workflows.
- **Infrastructure (`terraform/`)** – Shared modules and environment folders (`staging`, `prod`) managing Cloud Run, Vertex AI connections, and IAM via Terraform.
- **Data (`data_ingestion/`)** – Pipelines that push curated docs into Vertex AI Search/Vector Search for grounding.

`GEMINI.md` contains context for AI copilots, and the intro notebooks under `notebooks/` walk through agent prototyping + evaluation.

## Project Structure
```
knowsee-platform/
├── app/                        # ADK agent application (FastAPI, agent logic)
├── data_ingestion/             # Vertex AI data ingestion pipeline
├── deployment/terraform/dev    # Lightweight dev project bootstrap
├── dev/                        # Docker-compose stack + mock API
├── frontend/                   # Next.js client
├── notebooks/                  # Evaluation + prototyping notebooks
├── terraform/                  # IaC (modules, infra, environments/{staging,prod})
├── tests/                      # Backend unit + integration suites
├── Makefile                    # Unified automation entrypoint
└── README.md                   # This file
```

## Prerequisites
- Node.js 20+
- Python 3.11+ and [uv](https://docs.astral.sh/uv/getting-started/installation/) (auto-installed by `make install`)
- Docker & Docker Compose v2
- Google Cloud SDK (configured with the desired project)
- Terraform ≥ 1.6
- Make, curl, and bash (default on macOS/Linux)

## Quick Start
1. **Install all dependencies**
   ```bash
   make install  # uv sync + npm install
   ```
2. **Run the ADK playground (Streamlit) during agent development**
   ```bash
   make playground
   ```
3. **Bring up the full dockerized dev stack (API + web + Redis)**
   ```bash
   make dev        # use make dev-down / dev-logs / dev-restart as needed
   ```
4. **Iterate on the frontend only**
   ```bash
   make frontend-dev
   ```
5. **Check quality gates before committing**
   ```bash
   make lint
   make test
   ```

## Key Make Targets
| Target | Description |
| ------ | ----------- |
| `install` | Install uv if missing, sync Python deps, run `npm install` in `frontend/` |
| `playground` | Launch ADK Streamlit playground on port 8501 |
| `local-backend` | Start FastAPI locally with hot reload on `localhost:8000` |
| `dev` | Build + start docker compose stack defined in `dev/docker-compose.yml` |
| `frontend-dev` / `frontend-lint` / `frontend-test` | Workflows for the Next.js app |
| `backend-lint` / `backend-test` | Codespell, Ruff, Mypy, and PyTest suites |
| `data-ingestion` | Submit the Vertex AI data ingestion pipeline for the configured project |
| `setup-dev-env` | Provision minimal dev infra via `deployment/terraform/dev` |
| `fmt`, `validate`, `clean` | Terraform hygiene commands |
| `staging` / `prod` | Run `init → plan → apply → output` for each environment (see `terraform/environments/<env>/`)

Run `make help` anytime to see the full catalog.

## Development Workflows
### ADK Agent (`app/`, `data_ingestion/`)
- Modify `app/agent.py` to change retrieval or response logic. The FastAPI adapter lives in `app/fast_api_app.py`.
- Use `make local-backend` for a tight loop or `make playground` for a UI-driven testing surface.
- Update embeddings or corpora, then execute `make data-ingestion` to push fresh docs into Vertex AI Search / Vector Search (requires `gcloud auth login` and proper IAM).
- Backend QA: `make backend-test` (unit + integration) and `make backend-lint` (codespell, Ruff, Mypy).

### Frontend (`frontend/`)
- `make frontend-dev` runs `npm run dev` with hot reload at `http://localhost:3000`.
- Bootstrap `.env.local` quickly with `make bootstrap` (delegates to `npm run bootstrap`).
- CI-aligned quality gates: `make frontend-lint` and `make frontend-test` (Playwright e2e smoke suite).
- The app streams chat completions, supports dark mode, uploads, and responsive design out of the box.

### Dockerized Stack (`dev/`)
- `make dev-up` / `make dev-down` build and orchestrate the mock API, frontend, and Redis services.
- `make dev-logs` tails combined container logs; `make dev-health` pings the FastAPI + Next.js endpoints until healthy.
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
- Ensure the `DATA_STORE_ID` and region flags match your Vertex AI Search or Vector Search deployment before running `make data-ingestion`.

### Developer Sandbox Project
- `make setup-dev-env` boots the minimal GCP resources (datastore, service accounts, secrets) defined in `deployment/terraform/dev`. Supply overrides in `deployment/terraform/dev/vars/env.tfvars`.

## Deployment
- **Backend to Cloud Run:**
  ```bash
  gcloud config set project <your-project>
  make deploy    # optional: make deploy IAP=true PORT=8080
  ```
- **Frontend to Cloud Run / CDN:** build artifacts live in `frontend/`. Terraform modules can containerize and deploy the image; alternatively, reuse your existing CI/CD to `npm run build` then `gcloud run deploy`.
- Use the Terraform environments for staging/production parity, or run `uvx agent-starter-pack setup-cicd` for the original ADK bootstrapper if preferred.

## Monitoring & Observability
- OpenTelemetry traces/logs are emitted from `app/` to Cloud Trace and Logging, with persistent storage in BigQuery.
- The Looker Studio dashboard template (https://lookerstudio.google.com/reporting/46b35167-b38b-4e44-bd37-701ef4307418/page/tEnnC) visualizes the events; follow the dashboard "Setup Instructions" tab to point it at your dataset.
- Frontend metrics (Core Web Vitals, UX timings) can be forwarded via the same logging sink—consider adding a small helper under `frontend/src/lib/` (for example `telemetry.ts`) to batch and send events alongside backend traces.

## Additional Tips
- Keep `GEMINI.md` updated so AI assistants understand custom commands, secrets, and architecture.
- Notebooks under `notebooks/` demonstrate evaluation harnesses; start with the intro notebook to benchmark prompt changes before redeploying.
- When adding new infrastructure, mirror the `staging` folder first, validate, then promote to `prod` via the same Make targets for consistency.
