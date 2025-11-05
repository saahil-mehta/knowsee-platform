# File: Makefile
# Desc: Makefile for managing Knowsee development and infrastructure
#
##############################################################################

# Environment paths
STAGING_DIR = terraform/environments/staging
PROD_DIR = terraform/environments/prod

# Terraform variables
STAGING_TFVARS = $(STAGING_DIR)/terraform.tfvars
PROD_TFVARS = $(PROD_DIR)/terraform.tfvars

.PHONY: help dev dev-start dev-stop dev-logs dev-restart frontend staging prod

# Default target - show help
help:
	@echo "Knowsee - Development & Infrastructure Management"
	@echo ""
	@echo "Development Commands:"
	@echo "  make dev             - Start development environment (API + Frontend)"
	@echo "  make dev-start       - Start dev API server"
	@echo "  make dev-stop        - Stop dev API server"
	@echo "  make dev-logs        - View dev API logs"
	@echo "  make dev-restart     - Restart dev API server"
	@echo "  make frontend        - Install and start frontend dev server"
	@echo ""
	@echo "Cloud Deployment:"
	@echo "  make staging         - Deploy to staging environment"
	@echo "  make prod            - Deploy to prod environment"
	@echo ""
	@echo "Terraform Commands:"
	@echo "  make staging-init    - Initialize staging terraform"
	@echo "  make staging-plan    - Plan staging changes"
	@echo "  make staging-apply   - Apply staging changes"
	@echo "  make prod-init       - Initialize prod terraform"
	@echo "  make prod-plan       - Plan prod changes"
	@echo "  make prod-apply      - Apply prod changes"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make fmt             - Format all terraform files"
	@echo "  make validate        - Validate terraform configs"
	@echo "  make clean           - Clean terraform cache files"
	@echo ""

##############################################################################
# Development Environment
##############################################################################

dev:
	@echo "==> Starting Knowsee development environment..."
	@echo ""
	@cd dev && docker-compose up -d
	@echo ""
	@echo "==> Waiting for services to be ready..."
	@sleep 5
	@echo ""
	@echo "==> Checking service health..."
	@curl -s http://localhost:8000/health > /dev/null && echo "  ✓ API is healthy!" || echo "  ✗ API not responding"
	@curl -s http://localhost:3000 > /dev/null && echo "  ✓ Frontend is ready!" || echo "  ⏳ Frontend starting..."
	@echo ""
	@echo "╔════════════════════════════════════════════════════════╗"
	@echo "║     Knowsee Development Environment Ready!     ║"
	@echo "╚════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "🌐 Services:"
	@echo "   Frontend:   http://localhost:3000"
	@echo "   API:        http://localhost:8000"
	@echo "   API Docs:   http://localhost:8000/docs"
	@echo ""
	@echo "📝 Commands:"
	@echo "   View logs:  make dev-logs"
	@echo "   Stop all:   make dev-stop"
	@echo "   Restart:    make dev-restart"
	@echo ""
	@echo "💬 Try it:"
	@echo "   Open http://localhost:3000 and start chatting!"
	@echo ""

dev-start:
	@echo "==> Starting dev API server..."
	@cd dev && docker-compose up -d
	@echo "==> Dev API started at http://localhost:8000"

dev-stop:
	@echo "==> Stopping dev API server..."
	@cd dev && docker-compose down
	@echo "==> Dev API stopped"

dev-logs:
	@echo "==> Streaming logs from all services (Ctrl+C to exit)..."
	@cd dev && docker-compose logs -f

dev-restart:
	@echo "==> Restarting all dev services..."
	@cd dev && docker-compose restart
	@echo "==> All services restarted"
	@echo ""
	@echo "Frontend: http://localhost:3000"
	@echo "API:      http://localhost:8000"

frontend:
	@echo "==> Starting frontend development server..."
	@cd web && npm install && npm run dev

##############################################################################
# Cloud Deployment
##############################################################################

# Staging environment commands
staging-init:
	@echo "==> Initializing Terraform for staging environment..."
	@cd $(STAGING_DIR) && terraform init

staging-plan:
	@echo "==> Planning Terraform changes for staging environment..."
	@cd $(STAGING_DIR) && terraform plan -var-file=$(notdir $(STAGING_TFVARS))

staging-apply:
	@echo "==> Applying Terraform changes for staging environment..."
	@cd $(STAGING_DIR) && terraform apply -var-file=$(notdir $(STAGING_TFVARS))

staging-output:
	@echo "==> Staging environment outputs:"
	@cd $(STAGING_DIR) && terraform output

staging-destroy:
	@echo "==> WARNING: Destroying staging environment..."
	@cd $(STAGING_DIR) && terraform destroy -var-file=$(notdir $(STAGING_TFVARS))

staging: staging-init staging-plan staging-apply
	@echo "==> Staging environment setup complete!"
	@echo ""
	@make staging-output

# Production environment commands
prod-init:
	@echo "==> Initializing Terraform for prod environment..."
	@cd $(PROD_DIR) && terraform init

prod-plan:
	@echo "==> Planning Terraform changes for prod environment..."
	@cd $(PROD_DIR) && terraform plan -var-file=$(notdir $(PROD_TFVARS))

prod-apply:
	@echo "==> Applying Terraform changes for prod environment..."
	@cd $(PROD_DIR) && terraform apply -var-file=$(notdir $(PROD_TFVARS))

prod-output:
	@echo "==> Production environment outputs:"
	@cd $(PROD_DIR) && terraform output

prod-destroy:
	@echo "==> WARNING: Destroying production environment..."
	@cd $(PROD_DIR) && terraform destroy -var-file=$(notdir $(PROD_TFVARS))

prod: prod-init prod-plan prod-apply
	@echo "==> Production environment setup complete!"
	@echo ""
	@make prod-output

# Utility commands
fmt:
	@echo "==> Formatting Terraform files..."
	@terraform fmt -recursive terraform/
	@echo "==> Format complete!"

validate:
	@echo "==> Validating staging environment..."
	@cd $(STAGING_DIR) && terraform validate
	@echo "==> Validating prod environment..."
	@cd $(PROD_DIR) && terraform validate
	@echo "==> Validation complete!"

clean:
	@echo "==> Cleaning Terraform cache files..."
	@find terraform -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find terraform -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "==> Clean complete!"
