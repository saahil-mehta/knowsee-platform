# Knowsee Platform - Terraform Infrastructure

This directory contains the Terraform infrastructure-as-code for the Knowsee platform, including ADK agent infrastructure (formerly in `deployment/terraform/`).

## Architecture

The infrastructure follows a modular pattern with clear separation of concerns:

**Modules → Infra → Environments**

```
terraform/
├── modules/              # Reusable Terraform modules (logic)
├── environments/         # Environment-specific configurations (data)
│   ├── cicd/            # CICD runner project
│   ├── dev/             # Development cloud environment
│   ├── staging/         # Staging environment (mirrors prod)
│   └── prod/            # Production environment
```

### Design Pattern

Each environment follows this structure:

```
environments/<env>/
├── backend.tf           # GCS backend configuration
├── providers.tf         # Provider setup
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Environment-specific values
├── main.tf              # Module orchestration
├── outputs.tf           # Output values
└── infra/               # Local infrastructure definitions
    ├── cloud_run/       # Cloud Run service configs
    ├── discovery_engine/
    ├── enabled_services/
    ├── log_sinks/
    ├── service_accounts/
    └── storage/
```

**Key Principle:** The `infra/` subdirectories contain **output** blocks that define environment-specific configurations (data), whilst `modules/` contain the actual Terraform resources (logic). This eliminates code duplication.

## Environments

### CICD (`environments/cicd/`)
**Purpose:** CI/CD runner project for GitHub Actions and Cloud Build

**Resources:**
- CICD runner service account
- Artifact Registry (Docker repository)
- GitHub Workload Identity Federation
- Logs bucket

**Project:** Separate CICD project

### Dev (`environments/dev/`)
**Purpose:** Development cloud environment for testing

**Resources:**
- Cloud Run services (backend + optional frontend)
- Vertex AI Discovery Engine (datastore + search engine)
- Service accounts (app, vertex AI pipeline)
- Storage buckets (RAG pipeline, logs)
- BigQuery datasets (telemetry, feedback)
- Log sinks

**Project:** Separate dev project

### Staging (`environments/staging/`)
**Purpose:** Pre-production environment that mirrors production

**Resources:** Same as dev, with staging-specific configuration

**Project:** Separate staging project

### Prod (`environments/prod/`)
**Purpose:** Production environment

**Resources:** Same as dev/staging, with production-grade configuration

**Project:** Separate production project

## Available Modules

All modules are located in `terraform/modules/`:

### ADK-Specific Modules
- **cloud_run_service** - Cloud Run v2 services (backend/frontend)
- **discovery_engine** - Vertex AI Discovery Engine (Search) datastore + search engine
- **log_sink** - BigQuery log sinks for telemetry and feedback
- **github_wif** - GitHub Workload Identity Federation for CI/CD

### Shared Modules
- **enabled_services** - Enable GCP APIs
- **iam/service_accounts** - Service account creation
- **iam/bindings/** - IAM bindings (project, buckets, BigQuery, Cloud Run)
- **cloud_storage/buckets** - GCS buckets
- **bigquery/datasets** - BigQuery datasets
- **bigquery/tables** - BigQuery tables
- **cloud_run_job** - Cloud Run jobs
- **artifact_registry_repository** - Artifact Registry repositories
- **secret_manager** - Secret Manager secrets
- **kms** - Cloud KMS encryption keys

Plus many more in `modules/` directory (see existing modules from knowsee platform).

## Quick Start

### Prerequisites

1. Install [Terraform](https://www.terraform.io/downloads.html) >= 1.6
2. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
3. Authenticate with GCP:
   ```bash
   gcloud auth application-default login
   ```

### Initial Setup

1. **Create GCS Backend Buckets**

   Create storage buckets for Terraform state:
   ```bash
   # CICD
   gsutil mb -p your-cicd-project-id -l europe-west2 gs://terraform-knowsee-cicd
   gsutil versioning set on gs://terraform-knowsee-cicd

   # Dev
   gsutil mb -p your-dev-project-id -l europe-west2 gs://terraform-knowsee-dev
   gsutil versioning set on gs://terraform-knowsee-dev

   # Staging
   gsutil mb -p your-staging-project-id -l europe-west2 gs://terraform-knowsee-staging
   gsutil versioning set on gs://terraform-knowsee-staging

   # Production
   gsutil mb -p your-prod-project-id -l europe-west2 gs://terraform-knowsee-prod
   gsutil versioning set on gs://terraform-knowsee-prod
   ```

2. **Update Environment Variables**

   Edit `terraform.tfvars` in each environment directory:

   **CICD:** `terraform/environments/cicd/terraform.tfvars`
   ```hcl
   project_id       = "your-cicd-project-id"
   repository_owner = "your-github-username"
   repository_name  = "knowsee-platform"
   ```

   **Dev:** `terraform/environments/dev/terraform.tfvars`
   ```hcl
   project_id = "your-dev-project-id"
   ```

   **Staging:** `terraform/environments/staging/terraform.tfvars`
   ```hcl
   project_id = "your-staging-project-id"
   ```

   **Production:** `terraform/environments/prod/terraform.tfvars`
   ```hcl
   project_id = "your-prod-project-id"
   ```

## Usage

From the root directory, use the Makefile commands:

### Deploy Environments

```bash
# Deploy CICD infrastructure
make cicd

# Deploy dev environment
make dev

# Deploy staging environment
make staging

# Deploy production environment
make prod
```

### Detailed Workflow

```bash
# Initialize Terraform
make cicd-init    # or make dev-init, staging-init, prod-init

# Plan changes (review before applying)
make cicd-plan    # or make dev-plan, staging-plan, prod-plan

# Apply changes
make cicd-apply   # or make dev-apply, staging-apply, prod-apply

# View outputs
make cicd-output  # or make dev-output, staging-output, prod-output
```

### Utility Commands

```bash
# Format all Terraform files
make fmt

# Validate configurations
make validate

# Clean Terraform cache
make clean

# Show all available commands
make help
```

## Development Workflow

### Local Development

```bash
# Run Docker Compose stack locally
make dev-local

# Run ADK playground for agent development
make playground
```

### Cloud Development

```bash
# Deploy to dev cloud environment
make dev

# Run data ingestion pipeline
make data-ingestion
```

### Promotion Path

```
dev-local (Docker) → dev (cloud) → staging → prod
```

## Configuration

### Adding Infrastructure Resources

1. **Define in infra/** - Add configuration to the appropriate `infra/` subdirectory
   ```hcl
   # Example: terraform/environments/dev/infra/storage/storage.tf
   output "storage_buckets" {
     value = {
       new_bucket = {
         name     = "my-new-bucket"
         location = var.region
         ...
       }
     }
   }
   ```

2. **Reference in main.tf** - Use the shared module with the local configuration
   ```hcl
   # Example: terraform/environments/dev/main.tf
   module "storage_infra" {
     source = "./infra/storage"
     ...
   }

   module "storage_buckets" {
     source   = "../../modules/cloud_storage/buckets"
     for_each = module.storage_infra.storage_buckets
     ...
   }
   ```

3. **Apply** - Run terraform apply for the environment

### Example: Adding a Storage Bucket to Dev

```hcl
# terraform/environments/dev/infra/storage/storage.tf
output "storage_buckets" {
  value = {
    logs = { ... }
    rag_pipeline = { ... }
    new_data_bucket = {  # ← Add this
      name          = "${var.project_id}-data"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = true
      force_destroy = false
    }
  }
}
```

Then run:
```bash
make dev-plan   # Review changes
make dev-apply  # Apply changes
```

## Environment Differences

### Dev
- Lower resource limits (1 min instance for Cloud Run)
- Force destroy enabled for storage
- Shorter retention periods
- Used for testing and development

### Staging
- Mirrors production configuration
- Used for pre-production testing
- Same resource limits as production

### Prod
- Production-grade configuration
- Higher availability (min instances = 1)
- Force destroy disabled
- Longer retention periods
- Deletion protection enabled

## State Management

Each environment has its own Terraform state file stored in GCS:

- `gs://terraform-knowsee-cicd/terraform/state`
- `gs://terraform-knowsee-dev/terraform/state`
- `gs://terraform-knowsee-staging/terraform/state`
- `gs://terraform-knowsee-prod/terraform/state`

**Important:** Never manually edit state files. Use `terraform state` commands if needed.

## Best Practices

1. **Always run `plan` before `apply`** - Review changes before applying
2. **Use version control** - Commit `terraform.tfvars` changes (if not containing secrets)
3. **State isolation** - Each environment has separate state for safety
4. **Modular design** - Keep environment-specific configs in `infra/`, logic in `modules/`
5. **Labels** - Use consistent labelling for resource organisation
6. **Test in dev first** - Always test changes in dev before staging/prod

## Migration from `deployment/terraform/`

The ADK infrastructure previously in `deployment/terraform/` has been migrated into this structure:

**Old:**
```
deployment/terraform/
├── service.tf          → modules/cloud_run_service/
├── storage.tf          → modules/discovery_engine/ + storage buckets
├── service_accounts.tf → modules/iam/service_accounts/
├── log_sinks.tf        → modules/log_sink/
├── wif.tf              → modules/github_wif/
└── github.tf           → environments/cicd/
```

**New:**
```
terraform/
├── modules/           # Reusable logic
└── environments/      # Environment-specific data
    ├── cicd/
    ├── dev/
    ├── staging/
    └── prod/
```

## Troubleshooting

### State Lock Issues
```bash
# If state is locked, identify the lock ID and force unlock
cd terraform/environments/dev
terraform force-unlock <LOCK_ID>
```

### Authentication Issues
```bash
# Re-authenticate with GCP
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
```

### Module Not Found
```bash
# Re-initialise to download modules
make dev-init  # or cicd-init, staging-init, prod-init
```

## Contributing

When adding new infrastructure:

1. Create or update modules in `terraform/modules/`
2. Add configuration to `terraform/environments/<env>/infra/`
3. Reference in `terraform/environments/<env>/main.tf`
4. Update this README with new module documentation
5. Test in dev before deploying to staging/prod

---

**CRITICAL_ASSESSMENT:**

This Terraform structure successfully eliminates code duplication through the infra/modules pattern whilst maintaining clear separation between environments. The migration from `deployment/terraform/` consolidates all infrastructure in one location, following the DRY and KISS principles. State isolation via separate backends provides safety, and the modular design allows easy extension. However, the four-environment setup (CICD + dev + staging + prod) increases complexity and requires careful state management. The pattern is well-documented and follows Terraform best practices for large-scale infrastructure management.
