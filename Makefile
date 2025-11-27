# ==============================================================================
# Knowsee Platform Unified Makefile
# ============================================================================== 
# Combines ADK agent workflows, frontend tooling, and Terraform automation.
# ==============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

FRONTEND_DIR := frontend
LOCAL_COMPOSE := docker compose -f local/docker-compose.sagent.yml
ENV_COMPOSE = set -a && source .env && $(LOCAL_COMPOSE)
TERRAFORM_ROOT := terraform
TERRAFORM_ENVS := cicd dev staging prod
TF_VARS_NAME := terraform.tfvars
PLAYGROUND_PORT ?= 8501
BACKEND_HOST ?= localhost
BACKEND_PORT ?= 8000
GCP_REGION := europe-west2
SEPARATOR_LINE := ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
	@printf "$(SEPARATOR_LINE)\n"
endef

# Usage: $(call PRINT_HEADER,Title)
define PRINT_HEADER
	$(KNOWSEE_LOGO)
	@printf "  $(1)\n"
	$(SEPARATOR)
	@printf "\n"
endef

# Usage: $(call PNPM,command)
define PNPM
	@cd $(FRONTEND_DIR) && pnpm $(1)
endef

.PHONY: \
	help install upgrade outdated \
	playground local-backend data-ingestion \
	docker-auth docker-build-backend docker-build-frontend docker-push-backend docker-push-frontend \
	deploy-backend deploy-frontend build-backend build-frontend build-all \
	release-backend release-frontend release-all \
	local local-down local-logs local-logs-backend local-logs-frontend local-status local-restart \
	drift \
	frontend frontend-down frontend-clean frontend-install frontend-build frontend-typecheck frontend-lint frontend-test frontend-test-unit frontend-test-e2e frontend-db-psql frontend-db-query \
	backend-test backend-test-unit backend-test-int backend-test-cov backend-test-full backend-lint backend-health test-db-up test-db-down test lint check \
	fmt validate clean \
	gcp-switch gcp-status gcp-setup gcp-login \
	$(TERRAFORM_ENVS) \
	$(addsuffix -init,$(TERRAFORM_ENVS)) \
	$(addsuffix -validate,$(TERRAFORM_ENVS)) \
	$(addsuffix -plan,$(TERRAFORM_ENVS)) \
	$(addsuffix -apply,$(TERRAFORM_ENVS)) \
	$(addsuffix -output,$(TERRAFORM_ENVS)) \
	$(addsuffix -destroy,$(TERRAFORM_ENVS))

help:
	$(call PRINT_HEADER,Platform Toolkit)
	@printf "Development:\n"
	@printf "  make install           Install uv deps + frontend packages\n"
	@printf "  make upgrade           Upgrade all dependencies to latest compatible versions\n"
	@printf "  make outdated          Check for outdated dependencies without upgrading\n"
	@printf "  make playground        Launch ADK Streamlit playground (:$(PLAYGROUND_PORT))\n"
	@printf "  make local-backend     Run FastAPI backend only (:$(BACKEND_PORT))\n"
	@printf "  make local             Start full local stack (backend + frontend)\n"
	@printf "  make local-down        Stop local stack\n"
	@printf "  make local-logs        Stream local stack logs\n"
	@printf "\n"
	@printf "Frontend (Next.js Chatbot):\n"
	@printf "  make frontend              Start frontend with DB setup and migrations (:3000)\n"
	@printf "  make frontend-down         Stop frontend database\n"
	@printf "  make frontend-clean        Stop database and remove all data\n"
	@printf "  make frontend-install      Install frontend dependencies\n"
	@printf "  make frontend-build        Build frontend for production\n"
	@printf "  make frontend-db-psql      Open PostgreSQL CLI for database\n"
	@printf "  make frontend-db-query     Show database summary and recent data\n"
	@printf "  make frontend-lint         Lint frontend code\n"
	@printf "  make frontend-test         Run all frontend tests (unit + e2e)\n"
	@printf "  make frontend-test-unit    Run frontend unit tests (fast)\n"
	@printf "  make frontend-test-e2e     Run frontend e2e tests (requires server)\n"
	@printf "\n"
	@printf "Docker Build and Deploy (requires ENV=dev|staging|prod):\n"
	@printf "  make build-backend ENV=<env>     Build and push backend image\n"
	@printf "  make build-frontend ENV=<env>    Build and push frontend image\n"
	@printf "  make deploy-backend ENV=<env>    Deploy backend to Cloud Run\n"
	@printf "  make deploy-frontend ENV=<env>   Deploy frontend to Cloud Run\n"
	@printf "  make release-backend ENV=<env>   Build, push, and deploy backend\n"
	@printf "  make release-frontend ENV=<env>  Build, push, and deploy frontend\n"
	@printf "  make release-all ENV=<env>       Release both services\n"
	@printf "\n"
	@printf "Terraform (per environment: cicd, dev, staging, prod):\n"
	@printf "  make drift [ENV=<env>] Check resource drift (defaults to all envs in current GCP project)\n"
	@printf "  make <env>-init        Initialise Terraform for environment\n"
	@printf "  make <env>-validate    Validate Terraform configuration\n"
	@printf "  make <env>-plan        Plan infrastructure changes\n"
	@printf "  make <env>-apply       Apply infrastructure changes\n"
	@printf "  make <env>-output      Show Terraform outputs\n"
	@printf "  make <env>-destroy     Destroy infrastructure\n"
	@printf "  make <env>             Full deploy (init -> plan -> apply -> output)\n"
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

install: frontend-install
	@command -v uv >/dev/null 2>&1 || { \
		echo "uv is not installed. Installing..."; \
		curl -LsSf https://astral.sh/uv/0.8.13/install.sh | sh; \
		source $$HOME/.local/bin/env; \
	}
	@uv sync

upgrade:
	$(call PRINT_HEADER,Upgrading Dependencies)
	@printf "  Checking for uncommitted changes...\n"
	@if ! git diff-index --quiet HEAD -- 2>/dev/null; then \
		printf "\n  ⚠️  Warning: You have uncommitted changes.\n"; \
		printf "  Consider committing or stashing before upgrading.\n\n"; \
	else \
		printf "  ✅ Working tree is clean\n\n"; \
	fi
	@printf "  Creating backup of lock files...\n"
	@cp uv.lock uv.lock.backup 2>/dev/null || true
	@cp $(FRONTEND_DIR)/pnpm-lock.yaml $(FRONTEND_DIR)/pnpm-lock.yaml.backup 2>/dev/null || true
	@printf "  ✅ Backups created: uv.lock.backup, pnpm-lock.yaml.backup\n\n"
	@printf "  Checking outdated backend packages...\n"
	@uv pip list --outdated 2>/dev/null | head -20 || printf "  (No outdated packages detected)\n"
	@printf "\n"
	$(SEPARATOR)
	@printf "  Upgrading backend Python dependencies...\n\n"
	@uv lock --upgrade
	@printf "\n  Installing upgraded backend packages...\n\n"
	@uv sync
	@printf "\n"
	$(SEPARATOR)
	@printf "  Upgrading frontend packages...\n\n"
	$(call PNPM,update)
	@printf "\n  Running security audit...\n\n"
	@cd $(FRONTEND_DIR) && pnpm audit || printf "\n  Security issues found - review above\n"
	@printf "\n"
	$(SEPARATOR)
	@printf "  Upgrade Summary:\n\n"
	@printf "  Backend Python packages:\n"
	@if [ -f uv.lock.backup ]; then \
		python3 -c 'import re; \
		old = open("uv.lock.backup").read(); \
		new = open("uv.lock").read(); \
		old_pkgs = {m.group(1): m.group(2) for m in re.finditer(r"name = \"([^\"]+)\".*?version = \"([^\"]+)\"", old, re.DOTALL)}; \
		new_pkgs = {m.group(1): m.group(2) for m in re.finditer(r"name = \"([^\"]+)\".*?version = \"([^\"]+)\"", new, re.DOTALL)}; \
		changes = [(k, old_pkgs.get(k, "new"), v) for k, v in new_pkgs.items() if old_pkgs.get(k) != v]; \
		for pkg, old_v, new_v in sorted(changes)[:15]: \
			print(f"    {pkg}: {old_v} → {new_v}")' 2>/dev/null || printf "    No version changes detected\n"; \
	else \
		printf "    No backup found\n"; \
	fi
	@printf "\n  Frontend packages:\n"
	@printf "    Run 'git diff $(FRONTEND_DIR)/pnpm-lock.yaml' to see changes\n"
	@printf "\n"
	$(SEPARATOR)
	@printf "  ✅ All dependencies upgraded successfully!\n"
	@printf "\n  Next steps:\n"
	@printf "    • Review changes: git diff uv.lock $(FRONTEND_DIR)/pnpm-lock.yaml\n"
	@printf "    • Run tests: make check\n"
	@printf "    • Rollback if needed: mv uv.lock.backup uv.lock && mv $(FRONTEND_DIR)/pnpm-lock.yaml.backup $(FRONTEND_DIR)/pnpm-lock.yaml\n"
	$(SEPARATOR)
	@printf "\n"

outdated:
	$(call PRINT_HEADER,Checking Outdated Dependencies)
	@printf "  Backend (Python):\n\n"
	@uv pip list --outdated 2>/dev/null || printf "  ✅ All packages are up to date\n"
	@printf "\n"
	$(SEPARATOR)
	@printf "  Frontend (pnpm):\n\n"
	@cd $(FRONTEND_DIR) && pnpm outdated || printf "  ✅ All packages are up to date\n"
	@printf "\n"
	$(SEPARATOR)
	@printf "  To upgrade: make upgrade\n"
	$(SEPARATOR)
	@printf "\n"

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
	uv run uvicorn backend.src.app:app --host $(BACKEND_HOST) --port $(BACKEND_PORT) --reload

# ==============================================================================
# Docker Build and Deploy
# ==============================================================================

# Environment must be specified: make release-backend ENV=dev
ENV ?=
RESOURCE_PREFIX ?= knowsee

# Validate ENV is set for deploy targets
define CHECK_ENV
	@if [ -z "$(ENV)" ]; then \
		printf "\nError: ENV not specified\n\n"; \
		printf "Usage: make $(1) ENV=<environment>\n\n"; \
		printf "Available environments: dev, staging, prod\n\n"; \
		printf "Example: make $(1) ENV=dev\n\n"; \
		exit 1; \
	fi
endef

# Get registry URL from terraform output or construct it
REGISTRY_URL = $(shell if [ -n "$(ENV)" ]; then cd terraform/environments/$(ENV) && terraform output -raw artifact_registry_url 2>/dev/null || echo "$(GCP_REGION)-docker.pkg.dev/$$(gcloud config get-value project)/$(RESOURCE_PREFIX)-$(ENV)-app"; fi)
SERVICE_PREFIX = $(RESOURCE_PREFIX)-$(ENV)

docker-auth:
	@gcloud auth configure-docker $(GCP_REGION)-docker.pkg.dev --quiet

docker-build-backend:
	$(call CHECK_ENV,docker-build-backend)
	$(call PRINT_HEADER,Building Backend Image ($(ENV)))
	docker build --platform linux/amd64 -t $(REGISTRY_URL)/backend:latest \
		--build-arg COMMIT_SHA=$(shell git rev-parse HEAD) \
		--build-arg AGENT_VERSION=$(shell awk -F'"' '/^version = / {print $$2}' pyproject.toml || echo '0.0.0') \
		.

docker-build-frontend:
	$(call CHECK_ENV,docker-build-frontend)
	$(call PRINT_HEADER,Building Frontend Image ($(ENV)))
	docker build --platform linux/amd64 -t $(REGISTRY_URL)/frontend:latest ./frontend

docker-push-backend: docker-auth
	$(call CHECK_ENV,docker-push-backend)
	$(call PRINT_HEADER,Pushing Backend Image ($(ENV)))
	docker push $(REGISTRY_URL)/backend:latest

docker-push-frontend: docker-auth
	$(call CHECK_ENV,docker-push-frontend)
	$(call PRINT_HEADER,Pushing Frontend Image ($(ENV)))
	docker push $(REGISTRY_URL)/frontend:latest

deploy-backend:
	$(call CHECK_ENV,deploy-backend)
	$(call PRINT_HEADER,Deploying Backend to Cloud Run ($(ENV)))
	@PROJECT_ID=$$(gcloud config get-value project) && \
	gcloud run deploy $(SERVICE_PREFIX)-backend \
		--image $(REGISTRY_URL)/backend:latest \
		--project $$PROJECT_ID \
		--region $(GCP_REGION) \
		--service-account $(SERVICE_PREFIX)-app@$$PROJECT_ID.iam.gserviceaccount.com \
		--no-allow-unauthenticated \
		--memory 8Gi \
		--cpu 4 \
		--min-instances 1 \
		--max-instances 10 \
		--set-env-vars "DATA_STORE_ID=$(SERVICE_PREFIX)-datastore,DATA_STORE_REGION=eu" && \
	printf "\n" && \
	printf "$(SEPARATOR_LINE)\n" && \
	printf "  Backend deployed successfully!\n\n" && \
	printf "  Access from GCP Cloud Shell:\n" && \
	printf "  1. Run: gcloud run services proxy $(SERVICE_PREFIX)-backend --port=8080 --region=$(GCP_REGION) --project=$$PROJECT_ID\n\n" && \
	printf "  2. Click Web Preview > Preview on port 8080\n" && \
	printf "$(SEPARATOR_LINE)\n" && \
	printf "\n"

deploy-frontend:
	$(call CHECK_ENV,deploy-frontend)
	$(call PRINT_HEADER,Deploying Frontend to Cloud Run ($(ENV)))
	@PROJECT_ID=$$(gcloud config get-value project) && \
	BACKEND_URL=$$(gcloud run services describe $(SERVICE_PREFIX)-backend \
		--region $(GCP_REGION) \
		--format 'value(status.url)') && \
	gcloud run deploy $(SERVICE_PREFIX)-frontend \
		--image $(REGISTRY_URL)/frontend:latest \
		--project $$PROJECT_ID \
		--region $(GCP_REGION) \
		--service-account $(SERVICE_PREFIX)-app@$$PROJECT_ID.iam.gserviceaccount.com \
		--no-allow-unauthenticated \
		--memory 512Mi \
		--cpu 1 \
		--min-instances 0 \
		--max-instances 10 \
		--set-env-vars "NODE_ENV=production,NEXT_PUBLIC_COPILOT_AGENT=sagent_copilot,AGENT_RUNTIME_URL=$$BACKEND_URL/api/agui" && \
	printf "\n" && \
	printf "$(SEPARATOR_LINE)\n" && \
	printf "  Frontend deployed successfully!\n\n" && \
	printf "  Access from GCP Cloud Shell:\n" && \
	printf "  1. Run: gcloud run services proxy $(SERVICE_PREFIX)-frontend --port=8080 --region=$(GCP_REGION) --project=$$PROJECT_ID\n\n" && \
	printf "  2. Click Web Preview > Preview on port 8080\n" && \
	printf "$(SEPARATOR_LINE)\n" && \
	printf "\n"

# Full build and deploy workflows
build-backend: docker-build-backend docker-push-backend
build-frontend: docker-build-frontend docker-push-frontend
build-all: build-backend build-frontend

release-backend: build-backend deploy-backend
release-frontend: build-frontend deploy-frontend
release-all: release-backend release-frontend

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
# Local Docker Development
# ==============================================================================

local:
	$(call PRINT_HEADER,Local Stack (Backend + Frontend))
	@$(ENV_COMPOSE) up -d --build
	@printf "\n"
	@printf "  Services:\n"
	@printf "    Frontend  http://localhost:3000\n"
	@printf "    Backend         http://localhost:8000\n"
	@printf "\n"
	@printf "  Commands:\n"
	@printf "    make local-logs            Stream all logs\n"
	@printf "    make local-logs-backend    Stream backend logs\n"
	@printf "    make local-logs-frontend   Stream frontend logs\n"
	@printf "    make local-status          Show service status\n"
	@printf "    make local-down            Stop all services\n"
	@printf "\n"
	@printf "  Waiting for services...\n"
	@sleep 5
	@$(LOCAL_COMPOSE) ps
	$(SEPARATOR)
	@printf "  Stack ready.\n"
	$(SEPARATOR)
	@printf "\n"

local-down:
	@$(ENV_COMPOSE) down

local-logs:
	@$(LOCAL_COMPOSE) logs -f

local-logs-backend:
	@$(LOCAL_COMPOSE) logs -f sagent-backend

local-logs-frontend:
	@$(LOCAL_COMPOSE) logs -f sagent-frontend

local-status:
	@$(LOCAL_COMPOSE) ps

local-restart:
	@$(ENV_COMPOSE) restart

# ==============================================================================
# Drift Check
# ==============================================================================

drift:
	@if [ -n "$(ENV)" ]; then \
		uv run python scripts/detect_drift.py --environment $(ENV); \
	else \
		uv run python scripts/detect_drift.py; \
	fi

# ==============================================================================
# Frontend workflows (Next.js)
# ==============================================================================

frontend:
	$(call PRINT_HEADER,Frontend Development)
	@printf "  Setting up PostgreSQL database...\n\n"
	@cd $(FRONTEND_DIR) && bash scripts/setup-db.sh
	@printf "\n"
	$(SEPARATOR)
	@printf "  Setting up test user...\n\n"
	@USER_COUNT=$$(docker exec knowsee-frontend-db psql -U postgres -d chatbot -tAc 'SELECT COUNT(*) FROM "User"' 2>/dev/null || echo "0"); \
	if [ "$$USER_COUNT" -eq 0 ]; then \
		read -p "  Enter email (default: test@example.com): " USER_EMAIL; \
		USER_EMAIL=$${USER_EMAIL:-test@example.com}; \
		read -sp "  Enter password (default: password): " USER_PASSWORD; \
		USER_PASSWORD=$${USER_PASSWORD:-password}; \
		printf "\n"; \
		cd $(FRONTEND_DIR) && npx tsx scripts/create-user.ts "$$USER_EMAIL" "$$USER_PASSWORD"; \
		printf "\n  Test user created:\n"; \
		printf "    Email:    $$USER_EMAIL\n"; \
		printf "    Password: $$USER_PASSWORD\n"; \
	else \
		printf "  Users already exist, skipping user creation\n"; \
	fi
	@printf "\n"
	$(SEPARATOR)
	@printf "  Starting frontend development server...\n\n"
	@printf "  Frontend:  http://localhost:3000\n"
	@printf "  Database:  postgresql://postgres:postgres@localhost:5432/chatbot\n"
	@printf "\n"
	@printf "  Commands:\n"
	@printf "    make frontend-down         Stop database\n"
	@printf "    make frontend-db-psql      Open PostgreSQL CLI\n"
	@printf "\n"
	$(SEPARATOR)
	$(call PNPM,dev)

frontend-down:
	@printf "Stopping frontend database...\n"
	@cd $(FRONTEND_DIR) && docker compose -f docker-compose.local.yml down
	@printf "Database stopped\n"

frontend-clean:
	@printf "Stopping frontend database and removing all data...\n"
	@cd $(FRONTEND_DIR) && docker compose -f docker-compose.local.yml down -v
	@printf "Database and data removed\n"

frontend-install:
	@cd $(FRONTEND_DIR) && pnpm install
	@cd $(FRONTEND_DIR) && pnpm exec playwright install --with-deps chromium

frontend-build:
	$(call PNPM,build)

frontend-typecheck:
	$(call PNPM,tsc --noEmit)

frontend-lint:
	$(call PNPM,lint)

frontend-test:
	$(call PNPM,test)

frontend-test-unit:
	$(call PNPM,test:unit)

frontend-test-e2e:
	$(call PNPM,test:e2e)

frontend-db-psql:
	@docker exec -it knowsee-frontend-db psql -U postgres -d chatbot

frontend-db-query:
	@if ! docker ps --format '{{.Names}}' | grep -q '^knowsee-frontend-db$$'; then \
		printf "\n  Database not running.\n\n"; \
		printf "  Start it with: make frontend\n\n"; \
		exit 1; \
	fi
	@printf "\n  Database Summary\n"
	@printf "$(SEPARATOR_LINE)\n\n"
	@docker exec knowsee-frontend-db psql -U postgres -d chatbot -c "\
		SELECT 'User' as table_name, COUNT(*) as rows FROM \"User\" \
		UNION ALL SELECT 'Chat', COUNT(*) FROM \"Chat\" \
		UNION ALL SELECT 'Message_v2', COUNT(*) FROM \"Message_v2\" \
		UNION ALL SELECT 'Document', COUNT(*) FROM \"Document\" \
		UNION ALL SELECT 'Vote_v2', COUNT(*) FROM \"Vote_v2\" \
		UNION ALL SELECT 'Suggestion', COUNT(*) FROM \"Suggestion\" \
		UNION ALL SELECT 'Stream', COUNT(*) FROM \"Stream\" \
		ORDER BY table_name;"
	@printf "\n  Recent Chats (last 5)\n"
	@printf "$(SEPARATOR_LINE)\n"
	@docker exec knowsee-frontend-db psql -U postgres -d chatbot -c "\
		SELECT id, title, visibility, \"createdAt\" FROM \"Chat\" \
		ORDER BY \"createdAt\" DESC LIMIT 5;"
	@printf "\n  Recent Messages (last 10)\n"
	@printf "$(SEPARATOR_LINE)\n"
	@docker exec knowsee-frontend-db psql -U postgres -d chatbot -c "\
		SELECT m.id, m.role, LEFT(m.parts::text, 80) as parts_preview, m.\"createdAt\" \
		FROM \"Message_v2\" m ORDER BY m.\"createdAt\" DESC LIMIT 10;"

# ==============================================================================
# Quality gates
# ==============================================================================

backend-test: backend-test-unit backend-test-int

backend-test-unit:
	uv sync --all-extras
	uv run pytest tests/unit -v

backend-test-int:
	@if ! docker ps --format '{{.Names}}' | grep -q '^knowsee-test-db$$'; then \
		printf "\n  Test database not running.\n\n"; \
		printf "  Start it with: make test-db-up\n"; \
		printf "  Or run full workflow: make test-db-up && make backend-test-int && make test-db-down\n\n"; \
		exit 1; \
	fi
	uv sync --all-extras
	TEST_DATABASE_URL="postgresql+asyncpg://test:test@localhost:5433/test_knowsee" uv run pytest tests/integration -v

backend-test-cov:
	@if ! docker ps --format '{{.Names}}' | grep -q '^knowsee-test-db$$'; then \
		printf "\n  Test database not running. Starting...\n\n"; \
		$(MAKE) test-db-up; \
	fi
	uv sync --all-extras
	TEST_DATABASE_URL="postgresql+asyncpg://test:test@localhost:5433/test_knowsee" uv run pytest tests/ -v --cov=backend/src --cov-report=html --cov-report=term
	@printf "\n  Coverage report: htmlcov/index.html\n"

backend-lint:
	uv sync --all-extras
	uv run codespell backend/
	uv run ruff check backend/ --diff
	uv run ruff format backend/ --check --diff
	uv run mypy backend/src

# Test database management
test-db-up:
	docker compose -f docker-compose.test.yml up -d
	@printf "Waiting for test database...\n"
	@sleep 3
	@docker compose -f docker-compose.test.yml ps

test-db-down:
	docker compose -f docker-compose.test.yml down -v

# Full backend test workflow (start db, run all tests, stop db)
backend-test-full:
	$(call PRINT_HEADER,Backend Test Suite)
	@printf "  Starting test database...\n\n"
	@$(MAKE) test-db-up
	@printf "\n  Running all backend tests...\n\n"
	@$(MAKE) backend-test || ($(MAKE) test-db-down && exit 1)
	@printf "\n  Stopping test database...\n\n"
	@$(MAKE) test-db-down
	@printf "\n  All backend tests passed!\n\n"

# Health check
backend-health:
	@curl -s http://localhost:$(BACKEND_PORT)/health/ready | python3 -m json.tool || echo "Backend not running"

test: backend-test frontend-test

lint: backend-lint frontend-lint

# Full CI pipeline - runs all checks in proper order
check:
	$(call PRINT_HEADER,Full Test Suite Running)
	@printf "  1. Backend Linting...\n\n"
	@$(MAKE) backend-lint
	@printf "\n  Backend linting passed\n\n"
	@printf "  2. Starting test database...\n\n"
	@$(MAKE) test-db-up
	@printf "\n  3. Backend Testing...\n\n"
	@$(MAKE) backend-test || ($(MAKE) test-db-down && exit 1)
	@printf "\n  Backend tests passed\n\n"
	@printf "  4. Frontend Type Checking...\n\n"
	@$(MAKE) frontend-typecheck
	@printf "\n  Frontend type checking passed\n\n"
	@printf "  5. Frontend Linting...\n\n"
	@$(MAKE) frontend-lint
	@printf "\n  Frontend linting passed\n\n"
	@printf "  6. Starting backend for e2e tests...\n\n"
	@TEST_DATABASE_URL="postgresql+asyncpg://test:test@localhost:5433/test_knowsee" \
		uv run uvicorn backend.src.app:app --host 0.0.0.0 --port 8000 & \
		BACKEND_PID=$$!; \
		sleep 5; \
		printf "  7. Frontend Testing (e2e with backend)...\n\n"; \
		$(MAKE) frontend-test; \
		TEST_EXIT=$$?; \
		printf "\n  Stopping backend...\n"; \
		kill $$BACKEND_PID 2>/dev/null || true; \
		if [ $$TEST_EXIT -ne 0 ]; then $(MAKE) test-db-down; exit 1; fi
	@printf "\n  Frontend tests passed\n\n"
	@printf "  8. Stopping test database...\n\n"
	@$(MAKE) test-db-down
	@printf "\n  9. Frontend Build...\n\n"
	@$(MAKE) frontend-build
	@printf "\n  Frontend build passed\n\n"
	$(SEPARATOR)
	@printf "  All checks passed successfully!\n"
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
	@rm -f uv.lock.backup $(FRONTEND_DIR)/package-lock.json.backup 2>/dev/null || true
	@printf "Cleaned Terraform cache and backup files\n"

define TERRAFORM_TARGETS
$(1)-init:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform init

$(1)-validate:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform validate

$(1)-plan:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform plan -var-file=$(TF_VARS_NAME)

$(1)-apply:
	$(SEPARATOR)
	@printf "\n!!! REMINDER: This only creates infrastructure. !!!\n"
	@printf "    To deploy images, run: make release-all ENV=$(1)\n\n"
	$(SEPARATOR)
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform apply -var-file=$(TF_VARS_NAME)

$(1)-output:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform output

$(1)-destroy:
	@cd $(TERRAFORM_ROOT)/environments/$(1) && terraform destroy -var-file=$(TF_VARS_NAME)

$(1): $(1)-init $(1)-validate $(1)-plan $(1)-apply $(1)-output
endef

$(foreach env,$(TERRAFORM_ENVS),$(eval $(call TERRAFORM_TARGETS,$(env))))
