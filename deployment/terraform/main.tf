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

  project_name           = var.project_name
  cicd_runner_project_id = var.cicd_runner_project_id
  staging_project_id     = var.staging_project_id
  prod_project_id        = var.prod_project_id
}

# Load enabled services definitions
module "enabled_services_definition" {
  source = "./infra/enabled_services"

  cicd_runner_project_id  = var.cicd_runner_project_id
  staging_project_id      = var.staging_project_id
  prod_project_id         = var.prod_project_id
  cicd_services           = local.cicd_services
  deploy_project_services = local.deploy_project_services
}

# Load bucket definitions
module "buckets_definition" {
  source = "./infra/buckets"

  project_name           = var.project_name
  cicd_runner_project_id = var.cicd_runner_project_id
  region                 = var.region
  staging_project_id     = var.staging_project_id
  prod_project_id        = var.prod_project_id
}

# Load discovery engine definitions
module "discovery_engine_definition" {
  source = "./infra/discovery_engine"

  project_name       = var.project_name
  data_store_region  = var.data_store_region
  staging_project_id = var.staging_project_id
  prod_project_id    = var.prod_project_id
}

# ============================================================================
# PERMISSIONS DEFINITIONS
# ============================================================================

module "project_iam_definition" {
  source = "./permissions/project"

  project_name                      = var.project_name
  cicd_runner_project_id            = var.cicd_runner_project_id
  cicd_roles                        = var.cicd_roles
  cicd_sa_deployment_required_roles = var.cicd_sa_deployment_required_roles
  app_sa_roles                      = var.app_sa_roles
  pipelines_roles                   = var.pipelines_roles
}

module "service_account_iam_definition" {
  source = "./permissions/service_accounts"

  project_name           = var.project_name
  cicd_runner_project_id = var.cicd_runner_project_id
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
# ============================================================================

module "storage_buckets" {
  source = "./modules/cloud_storage/buckets"

  buckets = merge(
    { load_test_results = module.buckets_definition.bucket_load_test_results },
    module.buckets_definition.logs_data_buckets,
    module.buckets_definition.data_ingestion_pipeline_gcs_roots
  )

  depends_on = [module.enabled_services]
}

# ============================================================================
# DISCOVERY ENGINE - STAGING
# ============================================================================

module "discovery_engine_data_store_staging" {
  source = "./modules/discovery_engine/data_store"

  data_stores = module.discovery_engine_definition.data_stores_staging

  providers = {
    google = google.staging_billing_override
  }

  depends_on = [module.enabled_services]
}

module "discovery_engine_search_engine_staging" {
  source = "./modules/discovery_engine/search_engine"

  search_engines = {
    for k, v in module.discovery_engine_definition.search_engines_staging :
    k => merge(v, {
      data_store_ids = [module.discovery_engine_data_store_staging.data_store_names["staging"]]
    })
  }

  providers = {
    google = google.staging_billing_override
  }

  depends_on = [module.discovery_engine_data_store_staging]
}

# ============================================================================
# DISCOVERY ENGINE - PROD
# ============================================================================

module "discovery_engine_data_store_prod" {
  source = "./modules/discovery_engine/data_store"

  data_stores = module.discovery_engine_definition.data_stores_prod

  providers = {
    google = google.prod_billing_override
  }

  depends_on = [module.enabled_services]
}

module "discovery_engine_search_engine_prod" {
  source = "./modules/discovery_engine/search_engine"

  search_engines = {
    for k, v in module.discovery_engine_definition.search_engines_prod :
    k => merge(v, {
      data_store_ids = [module.discovery_engine_data_store_prod.data_store_names["prod"]]
    })
  }

  providers = {
    google = google.prod_billing_override
  }

  depends_on = [module.discovery_engine_data_store_prod]
}

# ============================================================================
# IAM BINDINGS - PROJECT LEVEL
# ============================================================================

# CICD SA roles on CICD project
module "project_iam_cicd_project" {
  source = "./modules/iam/project_member"

  project_iam_members = {
    for role in module.project_iam_definition.cicd_sa_cicd_project_roles :
    "${var.cicd_runner_project_id}-${role}" => {
      project = var.cicd_runner_project_id
      role    = role
      member  = "serviceAccount:${module.project_iam_definition.cicd_sa_email}"
    }
  }

  depends_on = [module.enabled_services, module.service_accounts]
}

# CICD SA roles on deploy projects (staging, prod)
module "project_iam_cicd_deploy_projects" {
  source = "./modules/iam/project_member"

  project_iam_members = {
    for pair in setproduct(keys(local.deploy_project_ids), module.project_iam_definition.cicd_sa_deploy_project_roles) :
    "${pair[0]}-${pair[1]}" => {
      project = local.deploy_project_ids[pair[0]]
      role    = pair[1]
      member  = "serviceAccount:${module.project_iam_definition.cicd_sa_email}"
    }
  }

  depends_on = [module.enabled_services, module.service_accounts]
}

# App SA roles on deploy projects
module "project_iam_app_sa" {
  source = "./modules/iam/project_member"

  project_iam_members = {
    for pair in setproduct(keys(local.deploy_project_ids), module.project_iam_definition.app_sa_roles) :
    "${pair[0]}-${pair[1]}" => {
      project = local.deploy_project_ids[pair[0]]
      role    = pair[1]
      member  = "serviceAccount:${module.service_accounts["app_${pair[0]}"].email}"
    }
  }

  depends_on = [module.enabled_services, module.service_accounts]
}

# Vertex AI Pipeline SA roles on deploy projects
module "project_iam_vertexai_pipeline_sa" {
  source = "./modules/iam/project_member"

  project_iam_members = {
    for pair in setproduct(keys(local.deploy_project_ids), module.project_iam_definition.vertexai_pipeline_sa_roles) :
    "${pair[0]}-${pair[1]}" => {
      project = local.deploy_project_ids[pair[0]]
      role    = pair[1]
      member  = "serviceAccount:${module.service_accounts["vertexai_pipeline_${pair[0]}"].email}"
    }
  }

  depends_on = [module.enabled_services, module.service_accounts]
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
