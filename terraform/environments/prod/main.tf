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

# Grant IAM roles to service accounts
resource "google_project_iam_member" "service_account_roles" {
  for_each = merge([
    for sa_key, sa in module.gcp_service_accounts.service_accounts : {
      for role in sa.roles :
      "${sa_key}-${role}" => {
        service_account = module.service_accounts[sa_key].email
        role            = role
      }
    }
  ]...)

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${each.value.service_account}"

  depends_on = [module.service_accounts]
}

# ==============================================================================
# Storage Buckets
# ==============================================================================

module "storage_infra" {
  source = "./infra/storage"

  project_id   = var.project_id
  project_name = var.project_name
  region       = var.region
}

module "storage_buckets" {
  source   = "../../modules/cloud_storage/buckets"
  for_each = module.storage_infra.storage_buckets

  name          = each.value.name
  location      = each.value.location
  project       = var.project_id
  force_destroy = each.value.force_destroy

  versioning = {
    enabled = each.value.versioning
  }

  labels = var.labels

  depends_on = [module.enabled_services]
}

# ==============================================================================
# Discovery Engine (Vertex AI Search)
# ==============================================================================

module "discovery_engine_infra" {
  source = "./infra/discovery_engine"

  project_name      = var.project_name
  data_store_region = var.data_store_region
}

module "discovery_engine" {
  source = "../../modules/discovery_engine"

  project_id                  = var.project_id
  data_store_id               = module.discovery_engine_infra.discovery_engine_config.datastore.data_store_id
  display_name                = module.discovery_engine_infra.discovery_engine_config.datastore.display_name
  location                    = module.discovery_engine_infra.discovery_engine_config.datastore.location
  industry_vertical           = module.discovery_engine_infra.discovery_engine_config.datastore.industry_vertical
  content_config              = module.discovery_engine_infra.discovery_engine_config.datastore.content_config
  solution_types              = module.discovery_engine_infra.discovery_engine_config.datastore.solution_types
  create_advanced_site_search = module.discovery_engine_infra.discovery_engine_config.datastore.create_advanced_site_search
  create_search_engine        = module.discovery_engine_infra.discovery_engine_config.datastore.create_search_engine
  search_engine_id            = module.discovery_engine_infra.discovery_engine_config.datastore.search_engine_id
  search_engine_display_name  = module.discovery_engine_infra.discovery_engine_config.datastore.search_engine_display_name
  search_tier                 = module.discovery_engine_infra.discovery_engine_config.datastore.search_tier

  depends_on = [module.enabled_services]
}

# ==============================================================================
# Log Sinks
# ==============================================================================

module "log_sinks_infra" {
  source = "./infra/log_sinks"

  project_name = var.project_name
  region       = var.region
}

module "log_sinks" {
  source   = "../../modules/log_sink"
  for_each = module.log_sinks_infra.log_sinks

  project_id            = var.project_id
  sink_name             = each.value.sink_name
  dataset_id            = each.value.dataset_id
  dataset_friendly_name = each.value.dataset_friendly_name
  location              = each.value.location
  filter                = each.value.filter

  depends_on = [module.enabled_services]
}

# ==============================================================================
# Cloud Run Services
# ==============================================================================

module "cloud_run_infra" {
  source = "./infra/cloud_run"

  project_name      = var.project_name
  region            = var.region
  data_store_region = var.data_store_region
}

# Get dynamic data store ID from module output
locals {
  service_account_map = {
    for key, sa in module.service_accounts :
    key => sa.email
  }
}

module "cloud_run_services" {
  source   = "../../modules/cloud_run_service"
  for_each = module.cloud_run_infra.cloud_run_services

  project_id                       = var.project_id
  name                             = each.value.name
  location                         = each.value.location
  image                            = each.value.image
  cpu                              = each.value.cpu
  memory                           = each.value.memory
  cpu_idle                         = each.value.cpu_idle
  min_instance_count               = each.value.min_instance_count
  max_instance_count               = each.value.max_instance_count
  max_instance_request_concurrency = each.value.max_instance_request_concurrency
  session_affinity                 = each.value.session_affinity
  service_account_email            = local.service_account_map[each.value.service_account_key]
  labels                           = merge(var.labels, each.value.labels)

  # Replace DATA_STORE_ID placeholder with actual value
  env_vars = [
    for env in each.value.env_vars :
    {
      name  = env.name
      value = env.name == "DATA_STORE_ID" ? module.discovery_engine.data_store_id : env.value
    }
  ]

  secret_env_vars = each.value.secret_env_vars

  depends_on = [module.enabled_services, module.service_accounts, module.discovery_engine]
}
