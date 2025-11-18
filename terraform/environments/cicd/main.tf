terraform {
  required_version = ">= 1.6"
}

# Data source for project information
data "google_project" "project" {
  project_id = var.project_id
}

# ==============================================================================
# Enabled Services
# ==============================================================================

module "required_apis" {
  source = "./infra/enabled_services"
}

module "enabled_services" {
  source = "../../modules/enabled_services"

  project_id       = var.project_id
  enabled_services = module.required_apis.required_apis
}

# ==============================================================================
# Service Accounts
# ==============================================================================

module "gcp_service_accounts" {
  source = "./infra/service_accounts"

  project_id   = var.project_id
  project_name = var.project_name
}

module "service_accounts" {
  source   = "../../modules/iam/service_accounts"
  for_each = module.gcp_service_accounts.service_accounts

  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
  project_id   = each.value.project_id

  depends_on = [module.enabled_services]
}

# ==============================================================================
# Artifact Registry
# ==============================================================================

module "artifact_registry_infra" {
  source = "./infra/artifact_registry"

  project_id   = var.project_id
  project_name = var.project_name
  region       = var.region
}

resource "google_artifact_registry_repository" "repositories" {
  for_each = module.artifact_registry_infra.artifact_repositories

  project       = each.value.project_id
  location      = each.value.location
  repository_id = each.value.repository_id
  description   = each.value.description
  format        = each.value.format
  labels        = var.labels

  depends_on = [module.enabled_services]
}

# ==============================================================================
# Storage Buckets
# ==============================================================================

module "storage_infra" {
  source = "./infra/storage"

  resource_prefix = var.resource_prefix
  environment     = var.environment
  region          = var.region
  labels          = var.labels
}

module "storage_buckets" {
  source   = "../../modules/cloud_storage/buckets"
  for_each = module.storage_infra.buckets

  name          = each.value.name
  location      = each.value.location
  project       = var.project_id
  labels        = each.value.labels
  force_destroy = each.value.force_destroy

  versioning = {
    enabled = each.value.versioning
  }

  depends_on = [module.enabled_services]
}

# ==============================================================================
# GitHub Workload Identity Federation
# ==============================================================================

module "github_wif_infra" {
  source = "./infra/github_wif"

  project_name     = var.project_name
  repository_owner = var.repository_owner
  repository_name  = var.repository_name
}

module "github_wif" {
  source = "../../modules/github_wif"

  project_id            = var.project_id
  pool_id               = module.github_wif_infra.github_wif_config.pool_id
  pool_display_name     = module.github_wif_infra.github_wif_config.pool_display_name
  provider_id           = module.github_wif_infra.github_wif_config.provider_id
  provider_display_name = module.github_wif_infra.github_wif_config.provider_display_name
  repository_owner      = module.github_wif_infra.github_wif_config.repository_owner
  repository_name       = module.github_wif_infra.github_wif_config.repository_name
  attribute_condition   = "attribute.repository == '${var.repository_owner}/${var.repository_name}'"
  service_account_email = module.service_accounts["cicd_runner"].email
  service_account_id    = module.service_accounts["cicd_runner"].name
  grant_token_creator   = true

  depends_on = [module.enabled_services, module.service_accounts]
}
