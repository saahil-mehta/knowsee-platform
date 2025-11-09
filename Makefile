# ==============================================================================
# Knowsee Platform Unified Makefile
# ============================================================================== 
# Combines ADK agent workflows, frontend tooling, and Terraform automation.
# ==============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

FRONTEND_DIR := frontend
COMPOSE_FILE := dev/docker-compose.yml
DOCKER_COMPOSE := docker compose -f $(COMPOSE_FILE)
TERRAFORM_ROOT := terraform
TERRAFORM_ENVS := staging prod
TF_VARS_NAME := terraform.tfvars
PLAYGROUND_PORT ?= 8501
BACKEND_HOST ?= localhost
BACKEND_PORT ?= 8000

.PHONY: \
	help install bootstrap \
	playground local-backend backend deploy setup-dev-env data-ingestion \
	dev dev-up dev-down dev-logs dev-restart dev-health \
	frontend-dev frontend-lint frontend-test \
	backend-test backend-lint test lint \
	fmt validate clean \
	$(TERRAFORM_ENVS) \
	$(addsuffix -init,$(TERRAFORM_ENVS)) \
	$(addsuffix -plan,$(TERRAFORM_ENVS)) \
	$(addsuffix -apply,$(TERRAFORM_ENVS)) \
	$(addsuffix -output,$(TERRAFORM_ENVS)) \
	$(addsuffix -destroy,$(TERRAFORM_ENVS))

help:
	@printf "\nKnowsee Platform Toolkit\n"
	@printf "  make install         Install uv deps + frontend packages\n"
	@printf "  make playground      Launch ADK Streamlit playground (:$(PLAYGROUND_PORT))\n"
	@printf "  make local-backend   Run FastAPI backend (:$(BACKEND_PORT))\n"
	@printf "  make dev             Start dockerized dev stack (api+web+redis)\n"
	@printf "  make frontend-dev    Run Next.js dev server (:3000)\n"
	@printf "  make lint/test       Lint or test backend + frontend\n"
	@printf "  make data-ingestion  Submit RAG ingestion pipeline\n"
	@printf "  make staging|prod    Terraform init→plan→apply→output for env\n"
	@printf "  make fmt|validate    Terraform formatting / validation\n"

# ==============================================================================
# Setup
# ==============================================================================

install:
	@command -v uv >/dev/null 2>&1 || { \
		echo "uv is not installed. Installing..."; \
		curl -LsSf https://astral.sh/uv/0.8.13/install.sh | sh; \
		source $$HOME/.local/bin/env; \
	}
	@uv sync
	@cd $(FRONTEND_DIR) && npm install

bootstrap:
	@cd $(FRONTEND_DIR) && npm run bootstrap

# ==============================================================================
# Backend (ADK agent) workflows
# ==============================================================================

playground:
	@echo "==============================================================================="
	@echo "| 🚀 Starting your agent playground...                                        |"
	@echo "| 🔍 IMPORTANT: Select the 'app' folder to interact with your agent.          |"
	@echo "==============================================================================="
	uv run adk web . --port $(PLAYGROUND_PORT) --reload_agents

local-backend:
	uv run uvicorn app.fast_api_app:app --host $(BACKEND_HOST) --port $(BACKEND_PORT) --reload

backend: deploy

deploy:
	PROJECT_ID=$$(gcloud config get-value project) && \
	gcloud beta run deploy sagent \
		--source . \
		--memory "4Gi" \
		--project $$PROJECT_ID \
		--region "europe-west2" \
		--no-allow-unauthenticated \
		--no-cpu-throttling \
		--labels "created-by=adk" \
		--update-build-env-vars "AGENT_VERSION=$(shell awk -F'"' '/^version = / {print $$2}' pyproject.toml || echo '0.0.0')" \
		--set-env-vars \
		"COMMIT_SHA=$(shell git rev-parse HEAD),DATA_STORE_ID=sagent-datastore,DATA_STORE_REGION=us" \
		$$(if $$(IAP),--iap) \
		$$(if $$(PORT),--port=$$(PORT))

setup-dev-env:
	PROJECT_ID=$$(gcloud config get-value project) && \
	(cd deployment/terraform/dev && terraform init && terraform apply --var-file vars/env.tfvars --var dev_project_id=$$PROJECT_ID --auto-approve)

data-ingestion:
	PROJECT_ID=$$(gcloud config get-value project) && \
	(cd data_ingestion && uv run data_ingestion_pipeline/submit_pipeline.py \
		--project-id=$$PROJECT_ID \
		--region="europe-west2" \
		--data-store-id="sagent-datastore" \
		--data-store-region="eu" \
		--service-account="sagent-rag@$$PROJECT_ID.iam.gserviceaccount.com" \
		--pipeline-root="gs://$$PROJECT_ID-sagent-rag" \
		--pipeline-name="data-ingestion-pipeline")

# ==============================================================================
# Dockerized dev stack
# ==============================================================================

dev: dev-up dev-health
	@printf "\nServices ready:\n"
	@printf "  Frontend: http://localhost:3000\n"
	@printf "  API:      http://localhost:8000\n\n"

dev-up:
	@$(DOCKER_COMPOSE) up -d --build

dev-down:
	@$(DOCKER_COMPOSE) down

dev-logs:
	@$(DOCKER_COMPOSE) logs -f

dev-restart:
	@$(DOCKER_COMPOSE) restart

dev-health:
	@printf "Checking services...\n"
	@curl -fsS --max-time 5 http://localhost:8000/health >/dev/null && printf "  api:   healthy\n" || printf "  api:   unavailable\n"
	@{ \
		attempt=0; \
		while ! curl -fsS --max-time 5 http://localhost:3000 >/dev/null 2>&1; do \
			attempt=$$((attempt + 1)); \
			if [ $$attempt -ge 20 ]; then \
				printf "  web:   starting (still warming up)\n"; \
				exit 0; \
			fi; \
			sleep 1; \
		done; \
		printf "  web:   healthy\n"; \
	}

# ==============================================================================
# Frontend workflows (Next.js)
# ==============================================================================

frontend-dev:
	@cd $(FRONTEND_DIR) && npm run dev

frontend-lint:
	@cd $(FRONTEND_DIR) && npm run lint

frontend-test:
	@cd $(FRONTEND_DIR) && npm run test:e2e

# ==============================================================================
# Quality gates
# ==============================================================================

backend-test:
	uv sync --dev
	uv run pytest tests/unit
	uv run pytest tests/integration

backend-lint:
	uv sync --dev --extra lint
	uv run codespell
	uv run ruff check . --diff
	uv run ruff format . --check --diff
	uv run mypy .

test: backend-test frontend-test

lint: backend-lint frontend-lint

# ==============================================================================
# Terraform automation
# ==============================================================================

fmt:
	terraform fmt -recursive $(TERRAFORM_ROOT)

validate:
	@for env in $(TERRAFORM_ENVS); do \
		printf "Validating $$env...\n"; \
		(cd $(TERRAFORM_ROOT)/environments/$$env && terraform validate) || exit 1; \
	done

clean:
	@find $(TERRAFORM_ROOT) -type d -name ".terraform" -prune -exec rm -rf {} + 2>/dev/null || true
	@find $(TERRAFORM_ROOT) -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true

define TERRAFORM_TARGETS
$(1)-init:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform init

$(1)-plan:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform plan -var-file=$(TF_VARS_NAME)

$(1)-apply:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform apply -var-file=$(TF_VARS_NAME)

$(1)-output:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform output

$(1)-destroy:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform destroy -var-file=$(TF_VARS_NAME)

$(1): $(1)-init $(1)-plan $(1)-apply $(1)-output
endef

$(foreach env,$(TERRAFORM_ENVS),$(eval $(call TERRAFORM_TARGETS,$(env))))
