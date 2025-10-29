# ==============================================================================
# Installation & Setup
# ==============================================================================

# Install dependencies using uv package manager
install:
	@command -v uv >/dev/null 2>&1 || { echo "uv is not installed. Installing uv..."; curl -LsSf https://astral.sh/uv/0.8.13/install.sh | sh; source $HOME/.local/bin/env; }
	uv sync --dev

# ==============================================================================
# Playground Targets
# ==============================================================================

# Launch local dev playground (ADK built-in UI)
playground:
	@echo "==============================================================================="
	@echo "| 🚀 Starting your agent playground...                                        |"
	@echo "|                                                                             |"
	@echo "| 💡 Try asking: How to save a pandas dataframe to CSV?                       |"
	@echo "|                                                                             |"
	@echo "| 🔍 IMPORTANT: Select the 'app' folder to interact with your agent.          |"
	@echo "==============================================================================="
	uv run adk web . --port 8501 --reload_agents

# ==============================================================================
# Frontend & API Targets
# ==============================================================================

# Install frontend dependencies
install-frontend:
	@echo "📦 Installing frontend dependencies..."
	cd frontend && npm install

# Start FastAPI API server for frontend
api:
	@echo "==============================================================================="
	@echo "| 🚀 Starting Knowsee API server...                                          |"
	@echo "|                                                                             |"
	@echo "| API: http://localhost:8000                                                  |"
	@echo "| Docs: http://localhost:8000/docs                                            |"
	@echo "==============================================================================="
	uv run python -m app.api

# Start Next.js frontend development server
frontend:
	@echo "==============================================================================="
	@echo "| 🚀 Starting Knowsee frontend...                                            |"
	@echo "|                                                                             |"
	@echo "| Frontend: http://localhost:3000                                             |"
	@echo "| Make sure API is running on http://localhost:8000                           |"
	@echo "==============================================================================="
	cd frontend && npm run dev

# Start both API and frontend concurrently
dev:
	@echo "==============================================================================="
	@echo "| 🚀 Starting full development environment...                                |"
	@echo "|                                                                             |"
	@echo "| API: http://localhost:8000                                                  |"
	@echo "| Frontend: http://localhost:3000                                             |"
	@echo "==============================================================================="
	@command -v uv >/dev/null 2>&1 || { echo "uv not found. Please install uv"; exit 1; }
	@command -v npm >/dev/null 2>&1 || { echo "npm not found. Please install Node.js"; exit 1; }
	@bash -c 'set -euo pipefail; trap "trap - INT TERM EXIT; kill 0" INT TERM EXIT; \
		uv run python -m app.api & \
		cd frontend && npm run dev'

# ==============================================================================
# Backend Deployment Targets
# ==============================================================================

# Deploy the agent remotely
backend:
	# Export dependencies to requirements file using uv export.
	uv export --no-hashes --no-header --no-dev --no-emit-project --no-annotate > .requirements.txt 2>/dev/null || \
	uv export --no-hashes --no-header --no-dev --no-emit-project > .requirements.txt && uv run app/agent_engine_app.py


# ==============================================================================
# Infrastructure Setup
# ==============================================================================

# Environment selection (default: dev)
# Usage: make setup-env ENV=prod | make data-ingestion ENV=staging
ENV ?= dev

# Set up environment resources using Terraform
# NOTE: Configure deployment/terraform/environments/$(ENV)/terraform.tfvars with your project IDs first
# Examples:
#   make setup-env              # Deploys dev environment (default)
#   make setup-env ENV=prod     # Deploys production environment
#   make setup-env ENV=staging  # Deploys staging environment
setup-env:
	@if [ ! -d deployment/terraform/environments/$(ENV) ]; then \
		echo "Error: deployment/terraform/environments/$(ENV) directory not found"; \
		echo "Valid environments: dev, staging, prod"; \
		exit 1; \
	fi
	@if [ "$(ENV)" != "dev" ] && [ ! -f deployment/terraform/environments/$(ENV)/terraform.tfvars ]; then \
		echo "Error: deployment/terraform/environments/$(ENV)/terraform.tfvars not found"; \
		echo "For production/staging, copy the .example file and configure it:"; \
		echo "  cp deployment/terraform/environments/$(ENV)/terraform.tfvars.example deployment/terraform/environments/$(ENV)/terraform.tfvars"; \
		echo "  vim deployment/terraform/environments/$(ENV)/terraform.tfvars  # Edit with your values"; \
		exit 1; \
	fi
	cd deployment/terraform/environments/$(ENV) && terraform init && terraform apply --auto-approve

# Backward compatibility: keep setup-dev-env as alias
setup-dev-env: ENV=dev
setup-dev-env: setup-env

# ==============================================================================
# Data Ingestion (RAG capabilities)
# ==============================================================================

# Run the data ingestion pipeline for RAG capabilities
# NOTE: Extracts all configuration from deployment/terraform/environments/$(ENV)/terraform.tfvars
# Examples:
#   make data-ingestion              # Runs on dev environment (default)
#   make data-ingestion ENV=prod     # Runs on production environment
data-ingestion:
	@if [ ! -f deployment/terraform/environments/$(ENV)/terraform.tfvars ]; then \
		echo "Error: deployment/terraform/environments/$(ENV)/terraform.tfvars not found"; \
		exit 1; \
	fi
	PROJECT_ID=$$(grep -E '^prod_project_id' deployment/terraform/environments/$(ENV)/terraform.tfvars | cut -d'"' -f2) && \
	REGION=$$(grep -E '^region' deployment/terraform/environments/$(ENV)/terraform.tfvars | cut -d'"' -f2) && \
	DATA_STORE_REGION=$$(grep -E '^data_store_region' deployment/terraform/environments/$(ENV)/terraform.tfvars | cut -d'"' -f2) && \
	PROJECT_NAME=$$(grep -E '^project_name' deployment/terraform/environments/$(ENV)/terraform.tfvars | cut -d'"' -f2) && \
	if [ -z "$$PROJECT_ID" ] || [ "$$PROJECT_ID" = "your-dev-project-id" ] || [ "$$PROJECT_ID" = "your-production-project-id" ]; then \
		echo "Error: Please configure prod_project_id in deployment/terraform/environments/$(ENV)/terraform.tfvars"; \
		exit 1; \
	fi && \
	echo "Running data ingestion for $(ENV) environment:" && \
	echo "  Project ID: $$PROJECT_ID" && \
	echo "  Region: $$REGION" && \
	echo "  Data Store Region: $$DATA_STORE_REGION" && \
	(cd data_ingestion && uv run data_ingestion_pipeline/submit_pipeline.py \
		--project-id=$$PROJECT_ID \
		--region="$$REGION" \
		--data-store-id="$$PROJECT_NAME-datastore" \
		--data-store-region="$$DATA_STORE_REGION" \
		--service-account="$$PROJECT_NAME-rag@$$PROJECT_ID.iam.gserviceaccount.com" \
		--pipeline-root="gs://$$PROJECT_ID-$$PROJECT_NAME-rag" \
		--pipeline-name="data-ingestion-pipeline")

# ==============================================================================
# Testing & Code Quality
# ==============================================================================

# Run unit and integration tests
test:
	uv run pytest tests/unit && uv run pytest tests/integration

# Run code quality checks (codespell, ruff, mypy)
lint:
	uv sync --dev --extra lint
	uv run codespell
	uv run ruff check . --diff
	uv run ruff format . --check --diff
	uv run mypy .
