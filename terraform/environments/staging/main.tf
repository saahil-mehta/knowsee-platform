# Main terraform configuration for staging environment
# This file orchestrates the infrastructure modules using shared templates

locals {
  # Create resource name prefix
  name_prefix = "${var.project_id}-${var.environment}"

  # Merge environment labels with resource-specific labels
  common_labels = merge(
    var.labels,
    {
      environment = var.environment
      managed_by  = "terraform"
    }
  )
}

# Enable required GCP APIs
module "enabled_services" {
  source = "../../modules/enabled_services"

  count = length(var.enable_apis) > 0 ? 1 : 0

  project_id = var.project_id
  services   = var.enable_apis
}

# Service Accounts
module "service_accounts" {
  source = "../../modules/iam/service_accounts"

  for_each = var.service_accounts

  project_id   = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description

  depends_on = [module.enabled_services]
}

# Storage Buckets
module "storage_buckets" {
  source = "../../modules/cloud_storage/buckets"

  for_each = var.storage_buckets

  project_id    = var.project_id
  name          = each.key
  location      = each.value.location
  storage_class = each.value.storage_class

  versioning = {
    enabled = each.value.versioning
  }

  labels = local.common_labels

  depends_on = [module.enabled_services]
}

# BigQuery Datasets
module "bigquery_datasets" {
  source = "../../modules/bigquery/datasets"

  for_each = var.bigquery_datasets

  project_id                  = var.project_id
  dataset_id                  = each.key
  location                    = each.value.location
  delete_contents_on_destroy  = each.value.delete_contents_on_destroy
  default_table_expiration_ms = each.value.default_table_expiration_ms

  labels = local.common_labels

  depends_on = [module.enabled_services]
}

##############################################################################
# Shared Infrastructure Templates
# Uncomment and customize as needed from ../../infra/, ../../permissions/, ../../resources/
##############################################################################

# Example: Custom IAM roles
# module "custom_roles_definition" {
#   source = "../../infra/custom_roles"
# }

# Example: Project-level permissions
# module "project_permissions" {
#   source = "../../permissions/project"
# }

# Additional infrastructure can be added by referencing the shared templates:
# - ../../infra/artifact_repositories/
# - ../../infra/bigquery/
# - ../../infra/buckets/
# - ../../infra/cloud_functions/
# - ../../infra/cloud_run/
# - ../../infra/cloud_scheduler/
# - ../../infra/composer/
# - ../../infra/compute/
# - ../../infra/datastreams/
# - ../../infra/monitoring/
# - ../../infra/pub_sub/
# - ../../infra/secrets/
# - ../../permissions/bigquery/
# - ../../permissions/buckets/
# - ../../permissions/cloud_run_jobs/
# - ../../permissions/groups/
