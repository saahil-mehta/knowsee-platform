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
SAGENT_COMPOSE_FILE := dev/docker-compose.sagent.yml
SAGENT_COMPOSE := docker compose -f $(SAGENT_COMPOSE_FILE)
TERRAFORM_ROOT := terraform
TERRAFORM_ENVS := cicd dev staging prod
TF_VARS_NAME := terraform.tfvars
PLAYGROUND_PORT ?= 8501
BACKEND_HOST ?= localhost
BACKEND_PORT ?= 8000

# ==============================================================================
# ASCII Branding Macros
# ==============================================================================

define KNOWSEE_LOGO
	@printf "\n"
	@printf "  ██╗  ██╗███╗   ██╗ ██████╗ ██╗    ██╗███████╗███████╗███████╗\n"
	@printf "  ██║ ██╔╝████╗  ██║██╔═══██╗██║    ██║██╔════╝██╔════╝██╔════╝\n"
	@printf "  █████╔╝ ██╔██╗ ██║██║   ██║██║ █╗ ██║███████╗█████╗  █████╗  \n"
	@printf "  ██╔═██╗ ██║╚██╗██║██║   ██║██║███╗██║╚════██║██╔══╝  ██╔══╝  \n"
	@printf "  ██║  ██╗██║ ╚████║╚██████╔╝╚███╔███╔╝███████║███████╗███████╗\n"
	@printf "  ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝ ╚══════╝╚══════╝╚══════╝\n"
	@printf "\n"
endef

define SEPARATOR
	@printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
endef

# Usage: $(call PRINT_HEADER,Title)
define PRINT_HEADER
	$(KNOWSEE_LOGO)
	@printf "  $(1)\n"
	$(SEPARATOR)
	@printf "\n"
endef

.PHONY: \
	help install bootstrap \
	playground local-backend backend deploy data-ingestion \
	dev-local dev-local-up dev-local-down dev-local-logs dev-local-restart dev-local-health \
	frontend-dev frontend-build frontend-typecheck frontend-lint frontend-test \
	backend-test backend-lint test lint check ci \
	fmt validate clean \
	sagent sagent-down sagent-logs sagent-logs-frontend sagent-logs-backend sagent-status \
	gcp-switch gcp-status gcp-setup gcp-login \
	$(TERRAFORM_ENVS) \
	$(addsuffix -init,$(TERRAFORM_ENVS)) \
	$(addsuffix -plan,$(TERRAFORM_ENVS)) \
	$(addsuffix -apply,$(TERRAFORM_ENVS)) \
	$(addsuffix -output,$(TERRAFORM_ENVS)) \
	$(addsuffix -destroy,$(TERRAFORM_ENVS))

help:
	$(call PRINT_HEADER,Platform Toolkit)
	@printf "Development:\n"
	@printf "  make install           Install uv deps + frontend packages\n"
	@printf "  make playground        Launch ADK Streamlit playground (:$(PLAYGROUND_PORT))\n"
	@printf "  make local-backend     Run FastAPI backend (:$(BACKEND_PORT))\n"
	@printf "  make dev-local         Start local Docker stack (api+web+redis)\n"
	@printf "  make sagent            Build + run AG-UI Copilot stack (Docker)\n"
	@printf "\n"
	@printf "Cloud Environments (Terraform):\n"
	@printf "  make cicd              Deploy CICD infrastructure\n"
	@printf "  make dev               Deploy dev cloud environment\n"
	@printf "  make staging           Deploy staging environment\n"
	@printf "  make prod              Deploy production environment\n"
	@printf "\n"
	@printf "GCP Profile Management:\n"
	@printf "  make gcp-switch PROFILE=<name>  Switch GCP profile and update .env\n"
	@printf "  make gcp-login                  Full GCP authentication (CLI + ADC)\n"
	@printf "  make gcp-status                 Show current GCP profile and project\n"
	@printf "  make gcp-setup                  Get started with GCP (if not configured)\n"
	@printf "\n"
	@printf "Utilities:\n"
	@printf "  make check             Run full test suite (lint+typecheck+test+build)\n"
	@printf "  make lint / make test  Lint or test backend + frontend\n"
	@printf "  make data-ingestion    Submit RAG ingestion pipeline\n"
	@printf "  make fmt / validate    Terraform formatting / validation\n"
	@printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

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
# GCP Profile Management
# ==============================================================================

gcp-switch:
	@if [ -z "$(PROFILE)" ]; then \
		echo ""; \
		echo "Error: PROFILE not specified"; \
		echo ""; \
		echo "Usage: make gcp-switch PROFILE=<profile-name>"; \
		echo ""; \
		echo "Available profiles:"; \
		gcloud config configurations list 2>/dev/null || echo "  (gcloud not configured)"; \
		echo ""; \
		echo "For more details, see: docs/GCP_PROFILE_MANAGEMENT.md"; \
		echo ""; \
		exit 1; \
	fi
	@./scripts/switch-gcp-profile.sh $(PROFILE)
	@printf "\nFor more details, see: docs/GCP_PROFILE_MANAGEMENT.md\n"

gcp-setup:
	@./scripts/switch-gcp-profile.sh
	@printf "\nFor more details, see: docs/GCP_PROFILE_MANAGEMENT.md\n"

gcp-login:
	$(call PRINT_HEADER,GCP Full Authentication)
	@printf "Step 1/3: Authenticating gcloud CLI...\n"
	@gcloud auth login
	@printf "\nStep 2/3: Authenticating Application Default Credentials...\n"
	@gcloud auth application-default login
	@printf "\nStep 3/3: Setting ADC quota project...\n"
	@PROJECT_ID=$$(gcloud config get-value project 2>/dev/null); \
	if [ -n "$$PROJECT_ID" ]; then \
		gcloud auth application-default set-quota-project "$$PROJECT_ID"; \
		printf "ADC quota project set to: $$PROJECT_ID\n"; \
	else \
		printf "Warning: No project configured. Run 'make gcp-switch PROFILE=<name>' first.\n"; \
	fi
	@printf "\n"
	$(SEPARATOR)
	@printf "\nAuthentication complete. Both CLI and ADC credentials are now active.\n"
	@printf "For more details, see: docs/GCP_PROFILE_MANAGEMENT.md\n"

gcp-status:
	$(call PRINT_HEADER,GCP Configuration Status)
	@printf "gcloud active profile:\n"
	@gcloud config configurations list | grep True || echo "  No active configuration"
	@printf "\nGCP project (from gcloud):\n"
	@printf "  %s\n" "$$(gcloud config get-value project 2>/dev/null || echo 'Not set')"
	@printf "\nGCP project (from .env):\n"
	@if [ -f .env ]; then \
		grep "^GOOGLE_CLOUD_PROJECT=" .env | cut -d'=' -f2 || echo "  Not set in .env"; \
	else \
		echo "  .env file not found"; \
	fi
	@printf "\nAll configurations:\n"
	@gcloud config configurations list 2>/dev/null || echo "  No configurations found"
	@printf "\nFor more details, see: docs/GCP_PROFILE_MANAGEMENT.md\n"
	$(SEPARATOR)
	@printf "\n"

# ==============================================================================
# Backend (ADK agent) workflows
# ==============================================================================

playground:
	$(call PRINT_HEADER,Agent Playground)
	@printf "  Starting your agent playground...\n"
	@printf "  IMPORTANT: Select the 'app' folder to interact with your agent.\n"
	$(SEPARATOR)
	@printf "\n"
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
# Local Docker development stack
# ==============================================================================

dev-local: dev-local-up dev-local-health
	$(call PRINT_HEADER,Local Development Services Ready)
	@printf "  Frontend: http://localhost:3000\n"
	@printf "  API:      http://localhost:8000\n"
	$(SEPARATOR)
	@printf "\n"

dev-local-up:
	@$(DOCKER_COMPOSE) up -d --build

dev-local-down:
	@$(DOCKER_COMPOSE) down

dev-local-logs:
	@$(DOCKER_COMPOSE) logs -f

dev-local-restart:
	@$(DOCKER_COMPOSE) restart

dev-local-health:
	@printf "Checking local services...\n"
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

sagent:
	$(call PRINT_HEADER,Sagent Stack (ADK + AG-UI + CopilotKit))
	@set -a && source .env && $(SAGENT_COMPOSE) up -d --build
	@echo ""
	@echo "✅ Sagent stack is starting..."
	@echo ""
	@echo "   📍 Services:"
	@echo "      • CopilotKit UI  → http://localhost:3000"
	@echo "      • ADK Backend    → http://localhost:8000"
	@echo ""
	@echo "   📊 Monitor real-time logs:"
	@echo "      • All services:   make sagent-logs"
	@echo "      • Frontend only:  make sagent-logs-frontend"
	@echo "      • Backend only:   make sagent-logs-backend"
	@echo ""
	@echo "   ⏳ Waiting for services to be healthy..."
	@sleep 5
	@echo ""
	@$(SAGENT_COMPOSE) ps
	@printf "\n"
	$(SEPARATOR)
	@printf "  ✨ Stack ready! Check logs above for any issues.\n"
	$(SEPARATOR)
	@printf "\n"

sagent-down:
	@set -a && source .env && $(SAGENT_COMPOSE) down

sagent-logs:
	@echo "📊 Streaming logs from all Sagent services (Ctrl+C to exit)..."
	@$(SAGENT_COMPOSE) logs -f

sagent-logs-frontend:
	@echo "📊 Streaming frontend logs (Ctrl+C to exit)..."
	@$(SAGENT_COMPOSE) logs -f sagent-frontend

sagent-logs-backend:
	@echo "📊 Streaming backend logs (Ctrl+C to exit)..."
	@$(SAGENT_COMPOSE) logs -f sagent-backend

sagent-status:
	@echo "📊 Sagent service status:"
	@$(SAGENT_COMPOSE) ps

# ==============================================================================
# Frontend workflows (Next.js)
# ==============================================================================

frontend-dev:
	@cd $(FRONTEND_DIR) && npm run dev

frontend-build:
	@cd $(FRONTEND_DIR) && npm run build

frontend-typecheck:
	@cd $(FRONTEND_DIR) && npm run typecheck

frontend-lint:
	@cd $(FRONTEND_DIR) && npm run lint

frontend-test:
	@cd $(FRONTEND_DIR) && npm run test

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

# Full CI pipeline - runs all checks in proper order
check: ci

ci:
	$(call PRINT_HEADER,Full Test Suite Running)
	@printf "  1️⃣  Backend Linting...\n\n"
	@$(MAKE) backend-lint
	@printf "\n  ✅ Backend linting passed\n\n"
	@printf "  2️⃣  Backend Testing...\n\n"
	@$(MAKE) backend-test
	@printf "\n  ✅ Backend tests passed\n\n"
	@printf "  3️⃣  Frontend Type Checking...\n\n"
	@$(MAKE) frontend-typecheck
	@printf "\n  ✅ Frontend type checking passed\n\n"
	@printf "  4️⃣  Frontend Linting...\n\n"
	@$(MAKE) frontend-lint
	@printf "\n  ✅ Frontend linting passed\n\n"
	@printf "  5️⃣  Frontend Testing...\n\n"
	@$(MAKE) frontend-test
	@printf "\n  ✅ Frontend tests passed\n\n"
	@printf "  6️⃣  Frontend Build...\n\n"
	@$(MAKE) frontend-build
	@printf "\n  ✅ Frontend build passed\n\n"
	$(SEPARATOR)
	@printf "  ✨ All checks passed successfully!\n"
	$(SEPARATOR)
	@printf "\n"

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
