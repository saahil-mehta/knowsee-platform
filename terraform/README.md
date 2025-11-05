# Knowsee - Terraform Infrastructure

This directory contains the Terraform infrastructure-as-code for the Knowsee project.

## Structure

```
terraform/
├── environments/         # Environment-specific configurations
│   ├── staging/          # Staging environment (mirrors prod)
│   │   ├── backend.tf    # GCS backend config
│   │   ├── main.tf       # Main infrastructure orchestration
│   │   ├── outputs.tf    # Output values
│   │   ├── providers.tf  # Provider configuration
│   │   ├── terraform.tfvars  # Staging-specific variables
│   │   └── variables.tf  # Variable definitions
│   └── prod/             # Production environment (mirrors staging)
│       ├── backend.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── terraform.tfvars  # Prod-specific variables
│       └── variables.tf
├── modules/              # Reusable Terraform modules
│   ├── artifact_registry_repository/
│   ├── bigquery/
│   ├── cloud_functions/
│   ├── cloud_run_job/
│   ├── cloud_scheduler/
│   ├── cloud_storage/
│   ├── composer/
│   ├── compute/
│   ├── datastream/
│   ├── enabled_services/
│   ├── iam/
│   ├── kms/
│   ├── monitoring/
│   ├── project/
│   ├── pub_sub/
│   ├── secret_manager/
│   └── storage_transfer/
├── infra/                # Shared infrastructure templates
│   ├── artifact_repositories/
│   ├── bigquery/
│   ├── buckets/
│   ├── cloud_functions/
│   ├── cloud_run/
│   ├── cloud_scheduler/
│   ├── composer/
│   ├── compute/
│   ├── custom_roles/
│   ├── datastreams/
│   ├── enabled_services/
│   ├── monitoring/
│   ├── pub_sub/
│   ├── secrets/
│   └── service_accounts/
├── permissions/          # Shared IAM permission templates
│   ├── bigquery/
│   ├── buckets/
│   ├── cloud_run_jobs/
│   ├── groups/
│   └── project/
└── resources/            # Shared resource configurations
    ├── schemas/          # BigQuery schemas, etc.
    └── secrets/          # Secret configurations
```

## Architecture

**Shared Templates Approach:**
- `modules/` - Low-level reusable Terraform modules
- `infra/` - Shared infrastructure templates (used by both environments)
- `permissions/` - Shared IAM permission templates
- `resources/` - Shared resource configurations (schemas, secrets)
- `environments/staging/` and `environments/prod/` - Mirror each other, differentiated only by `terraform.tfvars`

This ensures staging and production stay in sync structurally, while allowing environment-specific values.

## Getting Started

### Prerequisites

1. Install [Terraform](https://www.terraform.io/downloads.html) >= 1.0
2. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
3. Authenticate with GCP:
   ```bash
   gcloud auth application-default login
   ```

### Initial Setup

1. **Update Environment Variables**

   Edit the `terraform.tfvars` file in each environment directory:

   **Staging:** `terraform/environments/staging/terraform.tfvars`
   ```hcl
   project_id = "your-staging-project-id"
   region     = "us-central1"
   ```

   **Production:** `terraform/environments/prod/terraform.tfvars`
   ```hcl
   project_id = "your-prod-project-id"
   region     = "us-central1"
   ```

2. **Create GCS Backend Buckets**

   Create storage buckets for Terraform state:
   ```bash
   # Staging
   gsutil mb -p your-staging-project-id -l us-central1 gs://terraform-knowsee-staging
   gsutil versioning set on gs://terraform-knowsee-staging

   # Production
   gsutil mb -p your-prod-project-id -l us-central1 gs://terraform-knowsee-prod
   gsutil versioning set on gs://terraform-knowsee-prod
   ```

3. **Update Backend Configuration**

   Update the `backend.tf` file in each environment if you changed the bucket names.

## Usage

From the root directory, use the Makefile commands:

### Quick Start

```bash
# Deploy staging environment
make staging

# Deploy production environment
make prod
```

### Detailed Workflow

```bash
# Initialize Terraform
make staging-init   # or make prod-init

# Plan changes (review before applying)
make staging-plan   # or make prod-plan

# Apply changes
make staging-apply  # or make prod-apply

# View outputs
make staging-output # or make prod-output
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

## Configuration

### Adding Infrastructure Resources

1. **Enable APIs** - Add required APIs to `enable_apis` in `terraform.tfvars`
2. **Add Resources** - Uncomment or add resource blocks in the relevant `terraform.tfvars` file
3. **Custom Modules** - Add additional module calls in `main.tf` as needed

### Example: Adding a Storage Bucket

In `terraform/environments/staging/terraform.tfvars`:

```hcl
storage_buckets = {
  "staging-data-bucket" = {
    location      = "us-central1"
    storage_class = "STANDARD"
    versioning    = true
  }
}
```

### Example: Adding a Service Account

In `terraform/environments/staging/terraform.tfvars`:

```hcl
service_accounts = {
  "staging-app-sa" = {
    display_name = "Staging Application Service Account"
    description  = "Service account for staging application workloads"
  }
}
```

## Environment Differences

### Staging
- Intended for testing and validation
- Data can be deleted (`delete_contents_on_destroy = true`)
- May have table expiration policies
- Lower cost configuration options

### Production
- Production workloads
- Data persistence (`delete_contents_on_destroy = false`)
- No table expiration policies
- Production-grade configuration options

## Available Modules

All modules are located in `terraform/modules/` and can be used in your environment configurations:

- **artifact_registry_repository** - Docker/artifact repositories
- **bigquery** - BigQuery datasets and tables
- **cloud_functions** - Cloud Functions (gen1 and gen2)
- **cloud_run_job** - Cloud Run jobs
- **cloud_scheduler** - Scheduled jobs
- **cloud_storage** - GCS buckets
- **composer** - Cloud Composer (Airflow)
- **compute** - Compute Engine VMs
- **datastream** - Datastream connections and streams
- **enabled_services** - Enable GCP APIs
- **iam** - IAM roles, service accounts, and bindings
- **kms** - Key Management Service
- **monitoring** - Monitoring and alerting
- **project** - GCP project management
- **pub_sub** - Pub/Sub topics and subscriptions
- **secret_manager** - Secret Manager secrets
- **storage_transfer** - Storage Transfer Service

## Best Practices

1. **Always run `plan` before `apply`** - Review changes before applying
2. **Use version control** - Commit `terraform.tfvars` changes (if not containing secrets)
3. **State management** - Never manually edit state files
4. **Modular design** - Keep environment-specific configs in `terraform.tfvars`
5. **Labels** - Use consistent labeling for resource organization
6. **Destroy carefully** - Double-check before running destroy commands

## Troubleshooting

### State Lock Issues
```bash
# If state is locked, identify the lock ID and force unlock
cd terraform/environments/staging
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
# Re-initialize to download modules
make staging-init  # or make prod-init
```

## Contributing

When adding new infrastructure:
1. Create or update modules in `terraform/modules/`
2. Add variables to `variables.tf`
3. Add configuration to `terraform.tfvars`
4. Document changes in this README
5. Test in staging before deploying to production
