# Deployment

Infrastructure as code for Knowsee using Terraform. Provisions GCP resources including service accounts, storage buckets, IAM bindings, Vertex AI datastores, and Workload Identity Federation for GitHub Actions.

## Architecture

### Multi-Project Design

The terraform configuration supports a multi-project architecture for production environments:

```
┌────────────────────────────────────────────────────────────────┐
│ CICD Runner Project                                            │
│ - Workload Identity Federation pool + provider                │
│ - CICD service account with deployment permissions            │
│ - Load test results bucket                                    │
│ - Cloud Build (optional)                                      │
└────────────────────────────────────────────────────────────────┘
                        │
                        │ Deployment Permissions
                        ▼
┌────────────────────────────────────────────────────────────────┐
│ Staging Project                                                │
│ - Application service account                                 │
│ - Vertex AI Pipeline service account                          │
│ - RAG pipeline GCS bucket                                     │
│ - Logs bucket                                                 │
│ - Vertex AI Search datastore                                  │
│ - BigQuery datasets (feedback, telemetry)                     │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ Production Project                                             │
│ - Application service account                                 │
│ - Vertex AI Pipeline service account                          │
│ - RAG pipeline GCS bucket                                     │
│ - Logs bucket                                                 │
│ - Vertex AI Search datastore                                  │
│ - BigQuery datasets (feedback, telemetry)                     │
└────────────────────────────────────────────────────────────────┘
```

**For development**: All three project IDs point to the same project, consolidating resources in a single environment.

### Benefits of Multi-Project Architecture

- **Security isolation**: CICD credentials separated from application resources
- **Environment segregation**: Staging and production fully isolated
- **Cost tracking**: Clear attribution per environment
- **Blast radius limitation**: Issues in one environment don't affect others
- **Compliance**: Easier to meet regulatory requirements

## Terraform Structure

```
terraform/
├── main.tf                      # Root configuration with module calls
├── providers.tf                 # Provider configuration with aliases
├── variables.tf                 # Input variables
├── locals.tf                    # Computed locals (project lists, services)
├── outputs.tf                   # Output values
├── github.tf                    # GitHub Actions variables and secrets
├── wif.tf                       # Workload Identity Federation
├── log_sinks.tf                 # BigQuery log exports
├── vars/
│   ├── dev.tfvars              # Development environment values
│   └── prod.tfvars.example     # Production template
├── modules/                     # Reusable terraform modules
│   ├── cloud_storage/
│   │   └── buckets/            # Unified buckets module (versioning, lifecycle)
│   ├── discovery_engine/
│   │   ├── data_store/         # Vertex AI Search datastores
│   │   └── search_engine/      # Search engine configuration
│   ├── enabled_services/       # API enablement
│   └── iam/
│       ├── service_accounts/   # Service account creation
│       └── project_member/     # IAM binding management
├── infra/                       # Resource definitions (locals)
│   ├── service_accounts/       # SA definitions per project
│   ├── enabled_services/       # Required APIs per project
│   ├── buckets/                # Bucket definitions (logs, RAG, load tests)
│   └── discovery_engine/       # Datastore and search engine configs
└── permissions/                 # IAM binding definitions
    ├── project/                # Project-level IAM roles
    └── service_accounts/       # Service account impersonation
```

### Design Principles

1. **Infrastructure definitions separate from modules**: `infra/` and `permissions/` define resources as locals, `modules/` implement them
2. **Consistent naming**: All resources use environment-based map keys (`staging`, `prod`, `cicd`) not project IDs
3. **Unified modules**: Single `buckets` module supports all features (no `_enhanced` suffix)
4. **Provider aliases**: Separate providers for staging/prod to handle billing quotas
5. **Dependency management**: Explicit `depends_on` for API enablement and service accounts

## Resources Created

### Service Accounts

| Name | Project | Purpose |
|------|---------|---------|
| `knowsee-cicd` | CICD Runner | Deploys infrastructure and applications |
| `knowsee-app-{env}` | Staging/Prod | Runs agent application with limited permissions |
| `knowsee-rag-{env}` | Staging/Prod | Executes data ingestion pipelines |

### Storage Buckets

| Name | Project | Purpose | Key |
|------|---------|---------|-----|
| `{project}-knowsee-load-test` | CICD Runner | Load test results | `load_test_results` |
| `{project}-knowsee-logs` | All projects | Log exports | `staging`/`prod`/`cicd` |
| `{project}-knowsee-rag` | Staging/Prod | Pipeline artifacts | `staging`/`prod` |

### Vertex AI Resources

- **Datastores**: One per environment (`knowsee-datastore-{env}`)
- **Search Engines**: One per environment
- **Location**: Configurable via `data_store_region` (default: `eu`)

### IAM Permissions

- **CICD SA**: Editor-like permissions on all projects for deployment
- **App SA**: Vertex AI User, Logging Writer, Trace Agent
- **Pipeline SA**: Vertex AI User, Storage Admin on RAG bucket, Discovery Engine Editor

### GitHub Integration

Automatically configured variables and secrets:
- `GCP_PROJECT_NUMBER` - CICD project number
- `WIF_POOL_ID` - Workload Identity pool ID
- `WIF_PROVIDER_ID` - WIF provider ID
- `GCP_SERVICE_ACCOUNT` - CICD service account email
- `STAGING_PROJECT_ID`, `PROD_PROJECT_ID` - Environment project IDs
- Bucket names, service account emails, datastore IDs

## Configuration

### Development Environment

Edit `vars/dev.tfvars`:

```hcl
project_name = "knowsee"

# Single development project - replace with your project ID
prod_project_id        = "your-dev-project-id"
staging_project_id     = "your-dev-project-id"
cicd_runner_project_id = "your-dev-project-id"

# GitHub repository
repository_owner = "your-github-username"
repository_name  = "knowsee"

# Region configuration
region            = "europe-west2"
data_store_region = "eu"

# Optional: set to true to create GitHub repo via terraform
create_repository = false
```

### Production Environment

For production, use separate projects:

```hcl
project_name = "knowsee"

prod_project_id        = "knowsee-prod-abc123"
staging_project_id     = "knowsee-staging-abc123"
cicd_runner_project_id = "knowsee-cicd-abc123"

repository_owner = "your-org"
repository_name  = "knowsee"

region                 = "europe-west2"
data_store_region      = "eu"
pipeline_cron_schedule = "0 0 * * 0"  # Weekly

create_repository = false
```

## Deployment

### Automated (Recommended)

Use the Agent Starter Pack CLI:

```bash
uvx agent-starter-pack setup-cicd
```

This command:
1. Prompts for project IDs and configuration
2. Applies terraform automatically
3. Sets up GitHub Actions workflows
4. Configures Workload Identity Federation

### Manual Deployment

#### 1. Initialise Terraform

```bash
cd deployment/terraform
terraform init
```

#### 2. Validate Configuration

```bash
terraform validate
terraform fmt -recursive
```

#### 3. Plan Changes

```bash
# Development
terraform plan --var-file vars/dev.tfvars

# Production
terraform plan --var-file vars/prod.tfvars
```

#### 4. Apply Infrastructure

```bash
# Development (no approval required)
make setup-dev-env

# Production (requires confirmation)
terraform apply --var-file vars/prod.tfvars
```

#### 5. Verify Deployment

```bash
# Check outputs
terraform output

# Verify resources in GCP console
gcloud projects list
gcloud iam service-accounts list --project=<project-id>
gcloud storage buckets list --project=<project-id>
```

## Common Operations

### Update IAM Permissions

Edit `permissions/project/project.tf` to add roles:

```hcl
variable "app_sa_roles" {
  default = [
    "roles/aiplatform.user",
    "roles/logging.logWriter",
    "roles/cloudtrace.agent",
    "roles/your.custom.role",  # Add new role
  ]
}
```

Apply changes:

```bash
terraform apply --var-file vars/dev.tfvars
```

### Add New Storage Bucket

Edit `infra/buckets/buckets.tf`:

```hcl
locals {
  custom_bucket = {
    name                        = "${var.prod_project_id}-${var.project_name}-custom"
    location                    = var.region
    project                     = var.prod_project_id
    storage_class               = "STANDARD"
    uniform_bucket_level_access = true
    force_destroy               = false
    versioning_enabled          = true
    labels                      = {}
    lifecycle_rules             = []
  }
}

output "custom_bucket" {
  value = local.custom_bucket
}
```

Update `main.tf` to include in module call:

```hcl
module "storage_buckets" {
  source = "./modules/cloud_storage/buckets"

  buckets = merge(
    { load_test_results = module.buckets_definition.bucket_load_test_results },
    module.buckets_definition.logs_data_buckets,
    module.buckets_definition.data_ingestion_pipeline_gcs_roots,
    { custom = module.buckets_definition.custom_bucket }  # Add here
  )

  depends_on = [module.enabled_services]
}
```

### Destroy Resources

```bash
# Development
terraform destroy --var-file vars/dev.tfvars

# Specific resource
terraform destroy --var-file vars/dev.tfvars --target=module.storage_buckets
```

**Warning**: This permanently deletes resources. Buckets with `force_destroy = false` must be manually emptied first.

## Troubleshooting

### Module not found after changes

```bash
terraform init
```

### Permission denied errors

Ensure the account running terraform has sufficient permissions:

```bash
# Grant yourself Editor role
gcloud projects add-iam-policy-binding <project-id> \
  --member=user:<your-email> \
  --role=roles/editor
```

### API not enabled errors

Terraform automatically enables required APIs, but this can fail if:
- Service Usage API is not enabled (enable manually in console)
- Billing is not enabled on the project
- Project has insufficient quota

### Workload Identity Federation errors

Verify GitHub Actions can authenticate:

```bash
# Check WIF pool exists
gcloud iam workload-identity-pools list --location=global --project=<cicd-project-id>

# Check provider configuration
gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=github-pool \
  --location=global \
  --project=<cicd-project-id>
```

### Bucket naming conflicts

Bucket names are globally unique. If deployment fails with "bucket already exists":
1. Choose a different project ID
2. Modify `project_name` variable
3. Manually delete the conflicting bucket (if you own it)

## Best Practices

### State Management

- Use remote backends (GCS) for production:

```hcl
terraform {
  backend "gcs" {
    bucket = "knowsee-terraform-state"
    prefix = "prod"
  }
}
```

- Lock state file to prevent concurrent modifications
- Use separate state files per environment

### Variable Management

- Never commit `vars/prod.tfvars` with real values
- Use environment variables for sensitive values:

```bash
export TF_VAR_repository_owner="your-org"
terraform apply --var-file vars/prod.tfvars
```

- Consider using Google Secret Manager for secrets

### Module Versioning

- Pin module versions in production
- Test module updates in development first
- Document breaking changes in this README

### Drift Detection

Regularly check for drift between terraform and actual state:

```bash
terraform plan --var-file vars/prod.tfvars
```

## Additional Resources

- [Agent Starter Pack Deployment Guide](https://googlecloudplatform.github.io/agent-starter-pack/guide/deployment.html)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Vertex AI Search Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/discovery_engine_data_store)
