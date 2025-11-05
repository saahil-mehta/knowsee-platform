# File: Makefile
# Desc: Unified tooling for Knowsee development and infrastructure

SHELL := /bin/bash

FRONTEND_DIR := web
COMPOSE_FILE := dev/docker-compose.yml
DOCKER_COMPOSE := docker compose -f $(COMPOSE_FILE)
TERRAFORM_ROOT := terraform
TERRAFORM_ENVS := staging prod
TF_VARS_NAME := terraform.tfvars

.PHONY: \
	help \
	dev dev-up dev-down dev-logs dev-restart dev-health \
	frontend bootstrap lint test \
	fmt validate clean \
	$(TERRAFORM_ENVS) \
	$(addsuffix -init,$(TERRAFORM_ENVS)) \
	$(addsuffix -plan,$(TERRAFORM_ENVS)) \
	$(addsuffix -apply,$(TERRAFORM_ENVS)) \
	$(addsuffix -output,$(TERRAFORM_ENVS)) \
	$(addsuffix -destroy,$(TERRAFORM_ENVS))

help:
	@printf "\nKnowsee Toolkit\n"
	@printf "  make dev          Start dev stack (API, web, redis)\n"
	@printf "  make dev-down     Stop dev stack\n"
	@printf "  make dev-logs     Tail container logs\n"
	@printf "  make bootstrap    Prepare frontend dependencies and env files\n"
	@printf "  make lint         Run frontend lint checks\n"
	@printf "  make test         Run frontend Playwright smoke tests\n"
	@printf "  make fmt          Run terraform fmt recursively\n"
	@printf "  make validate     terraform validate for all environments\n"
	@printf "  make clean        Remove terraform cache directories\n"
	@printf "\nTerraform shortcuts:\n"
	@printf "  make staging|prod Run init → plan → apply → output for the env\n"
	@printf "  make staging-plan Run plan only (same for prod-plan)\n\n"

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

frontend:
	@cd $(FRONTEND_DIR) && npm run dev

bootstrap:
	@cd $(FRONTEND_DIR) && npm run bootstrap

lint:
	@cd $(FRONTEND_DIR) && npm run lint

test:
	@cd $(FRONTEND_DIR) && npm run test:e2e

fmt:
	@terraform fmt -recursive $(TERRAFORM_ROOT)

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
