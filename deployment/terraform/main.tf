# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  required_version = ">= 1.3.0"
}

# ============================================================================
# INFRASTRUCTURE DEFINITIONS
# ============================================================================

# Load service account definitions
module "service_accounts_definition" {
  source = "./infra/service_accounts"
}

# Load enabled services definitions
module "enabled_services_definition" {
  source = "./infra/enabled_services"
}

# Load bucket definitions
module "buckets_definition" {
  source = "./infra/buckets"
}

# Load discovery engine definitions
module "discovery_engine_definition" {
  source = "./infra/discovery_engine"
}

# ============================================================================
# PERMISSIONS DEFINITIONS
# ============================================================================

module "project_iam_definition" {
  source = "./permissions/project"
}

module "service_account_iam_definition" {
  source = "./permissions/service_accounts"
}

# ============================================================================
# ENABLED SERVICES
# ============================================================================

module "enabled_services" {
  source   = "./modules/enabled_services"
  for_each = module.enabled_services_definition.project_enabled_services

  project_id       = each.value.project_id
  enabled_services = each.value.enabled_services
}

# ============================================================================
# SERVICE ACCOUNTS
# ============================================================================

module "service_accounts" {
  source   = "./modules/iam/service_accounts"
  for_each = module.service_accounts_definition.service_accounts

  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
  project_id   = each.value.project_id

  depends_on = [module.enabled_services]
}

# ============================================================================
# STORAGE BUCKETS
# NOTE: These use direct resources because the cloud_storage/buckets module
# doesn't support uniform_bucket_level_access and has force_destroy=false hardcoded.
# ============================================================================

resource "google_storage_bucket" "bucket_load_test_results" {
  name                        = module.buckets_definition.bucket_load_test_results.name
  location                    = module.buckets_definition.bucket_load_test_results.location
  project                     = module.buckets_definition.bucket_load_test_results.project
  uniform_bucket_level_access = module.buckets_definition.bucket_load_test_results.uniform_bucket_level_access
  force_destroy               = module.buckets_definition.bucket_load_test_results.force_destroy

  depends_on = [module.enabled_services]
}

resource "google_storage_bucket" "logs_data_bucket" {
  for_each = module.buckets_definition.logs_data_buckets

  name                        = each.value.name
  location                    = each.value.location
  project                     = each.value.project
  uniform_bucket_level_access = each.value.uniform_bucket_level_access
  force_destroy               = each.value.force_destroy

  depends_on = [module.enabled_services]
}

resource "google_storage_bucket" "data_ingestion_pipeline_gcs_root" {
  for_each = module.buckets_definition.data_ingestion_pipeline_gcs_roots

  name                        = each.value.name
  location                    = each.value.location
  project                     = each.value.project
  uniform_bucket_level_access = each.value.uniform_bucket_level_access
  force_destroy               = each.value.force_destroy

  depends_on = [module.enabled_services]
}

# ============================================================================
# DISCOVERY ENGINE
# NOTE: These use direct resources because there's no discovery engine module
# in data-platform-ingestion-pipelines.
# ============================================================================

resource "google_discovery_engine_data_store" "data_store_staging" {
  location                    = module.discovery_engine_definition.data_stores["staging"].location
  project                     = module.discovery_engine_definition.data_stores["staging"].project
  data_store_id               = module.discovery_engine_definition.data_stores["staging"].data_store_id
  display_name                = module.discovery_engine_definition.data_stores["staging"].display_name
  industry_vertical           = module.discovery_engine_definition.data_stores["staging"].industry_vertical
  content_config              = module.discovery_engine_definition.data_stores["staging"].content_config
  solution_types              = module.discovery_engine_definition.data_stores["staging"].solution_types
  create_advanced_site_search = module.discovery_engine_definition.data_stores["staging"].create_advanced_site_search

  provider   = google.staging_billing_override
  depends_on = [module.enabled_services]
}

resource "google_discovery_engine_search_engine" "search_engine_staging" {
  project        = module.discovery_engine_definition.search_engines["staging"].project
  engine_id      = module.discovery_engine_definition.search_engines["staging"].engine_id
  collection_id  = module.discovery_engine_definition.search_engines["staging"].collection_id
  location       = google_discovery_engine_data_store.data_store_staging.location
  display_name   = module.discovery_engine_definition.search_engines["staging"].display_name
  data_store_ids = [google_discovery_engine_data_store.data_store_staging.data_store_id]

  search_engine_config {
    search_tier = module.discovery_engine_definition.search_engines["staging"].search_tier
  }

  provider = google.staging_billing_override
}

resource "google_discovery_engine_data_store" "data_store_prod" {
  location                    = module.discovery_engine_definition.data_stores["prod"].location
  project                     = module.discovery_engine_definition.data_stores["prod"].project
  data_store_id               = module.discovery_engine_definition.data_stores["prod"].data_store_id
  display_name                = module.discovery_engine_definition.data_stores["prod"].display_name
  industry_vertical           = module.discovery_engine_definition.data_stores["prod"].industry_vertical
  content_config              = module.discovery_engine_definition.data_stores["prod"].content_config
  solution_types              = module.discovery_engine_definition.data_stores["prod"].solution_types
  create_advanced_site_search = module.discovery_engine_definition.data_stores["prod"].create_advanced_site_search

  provider   = google.prod_billing_override
  depends_on = [module.enabled_services]
}

resource "google_discovery_engine_search_engine" "search_engine_prod" {
  project        = module.discovery_engine_definition.search_engines["prod"].project
  engine_id      = module.discovery_engine_definition.search_engines["prod"].engine_id
  collection_id  = module.discovery_engine_definition.search_engines["prod"].collection_id
  location       = google_discovery_engine_data_store.data_store_prod.location
  display_name   = module.discovery_engine_definition.search_engines["prod"].display_name
  data_store_ids = [google_discovery_engine_data_store.data_store_prod.data_store_id]

  search_engine_config {
    search_tier = module.discovery_engine_definition.search_engines["prod"].search_tier
  }

  provider = google.prod_billing_override
}

# ============================================================================
# VERTEX AI REASONING ENGINE
# NOTE: These are knowsee-specific resources with no module equivalent.
# ============================================================================

# Get project information to access the project number
data "google_project" "project" {
  for_each = local.deploy_project_ids

  project_id = local.deploy_project_ids[each.key]
}

resource "google_vertex_ai_reasoning_engine" "app_staging" {
  display_name = var.project_name
  description  = "Agent deployed via Terraform"
  region       = var.region
  project      = var.staging_project_id

  spec {
    service_account = module.service_accounts["app_staging"].email

    package_spec {
      python_version           = "3.12"
      pickle_object_gcs_uri    = "gs://agent-starter-pack/dummy/agent_engine.pkl"
      dependency_files_gcs_uri = "gs://agent-starter-pack/dummy/dependencies.tar.gz"
      requirements_gcs_uri     = "gs://agent-starter-pack/dummy/requirements.txt"
    }
  }

  lifecycle {
    ignore_changes = [spec]
  }

  depends_on = [module.enabled_services]
}

resource "google_vertex_ai_reasoning_engine" "app_prod" {
  display_name = var.project_name
  description  = "Agent deployed via Terraform"
  region       = var.region
  project      = var.prod_project_id

  spec {
    service_account = module.service_accounts["app_prod"].email

    package_spec {
      python_version           = "3.12"
      pickle_object_gcs_uri    = "gs://agent-starter-pack/dummy/agent_engine.pkl"
      dependency_files_gcs_uri = "gs://agent-starter-pack/dummy/dependencies.tar.gz"
      requirements_gcs_uri     = "gs://agent-starter-pack/dummy/requirements.txt"
    }
  }

  lifecycle {
    ignore_changes = [spec]
  }

  depends_on = [module.enabled_services]
}

# ============================================================================
# IAM BINDINGS - PROJECT LEVEL
# NOTE: These use google_project_iam_member (additive) rather than the
# modules/iam/project module to avoid overwriting existing IAM bindings.
# ============================================================================

# Data source to get project numbers
data "google_project" "projects" {
  for_each   = local.deploy_project_ids
  project_id = each.value
}

# CICD SA roles on CICD project
resource "google_project_iam_member" "cicd_project_roles" {
  for_each = toset(module.project_iam_definition.cicd_sa_cicd_project_roles.roles)

  project    = var.cicd_runner_project_id
  role       = each.value
  member     = module.project_iam_definition.cicd_sa_cicd_project_roles.member
  depends_on = [module.enabled_services]
}

# CICD SA roles on deploy projects (staging, prod)
resource "google_project_iam_member" "other_projects_roles" {
  for_each = {
    for pair in setproduct(keys(local.deploy_project_ids), module.project_iam_definition.cicd_sa_deploy_project_roles.roles) :
    "${pair[0]}-${pair[1]}" => {
      project_id = local.deploy_project_ids[pair[0]]
      role       = pair[1]
    }
  }

  project    = each.value.project_id
  role       = each.value.role
  member     = module.project_iam_definition.cicd_sa_deploy_project_roles.member
  depends_on = [module.enabled_services]
}

# App SA roles on deploy projects
resource "google_project_iam_member" "app_sa_roles" {
  for_each = {
    for pair in setproduct(keys(local.deploy_project_ids), module.project_iam_definition.app_sa_roles.roles) :
    join(",", pair) => {
      project = local.deploy_project_ids[pair[0]]
      role    = pair[1]
      env     = pair[0]
    }
  }

  project    = each.value.project
  role       = each.value.role
  member     = "serviceAccount:${module.service_accounts["app_${each.value.env}"].email}"
  depends_on = [module.enabled_services]
}

# Vertex AI Pipeline SA roles on deploy projects
resource "google_project_iam_member" "vertexai_pipeline_sa_roles" {
  for_each = {
    for pair in setproduct(keys(local.deploy_project_ids), module.project_iam_definition.vertexai_pipeline_sa_roles.roles) :
    join(",", pair) => {
      project = local.deploy_project_ids[pair[0]]
      role    = pair[1]
      env     = pair[0]
    }
  }

  project    = each.value.project
  role       = each.value.role
  member     = "serviceAccount:${module.service_accounts["vertexai_pipeline_${each.value.env}"].email}"
  depends_on = [module.enabled_services]
}

# ============================================================================
# IAM BINDINGS - SERVICE ACCOUNT LEVEL
# ============================================================================

# CICD SA self-referencing permissions
resource "google_service_account_iam_member" "cicd_sa_self_bindings" {
  for_each = {
    for pair in flatten([
      for role, config in module.service_account_iam_definition.cicd_sa_self_bindings : [
        for member in config.members : {
          key    = "${role}-${member}"
          role   = role
          member = member
        }
      ]
      ]) : pair.key => {
      role   = pair.role
      member = pair.member
    }
  }

  service_account_id = module.service_accounts["cicd_runner"].name
  role               = each.value.role
  member             = each.value.member
  depends_on         = [module.enabled_services]
}
