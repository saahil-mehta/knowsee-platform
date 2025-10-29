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

# ============================================================================
# DEVELOPMENT ENVIRONMENT - TERRAFORM CONFIGURATION
# ============================================================================
# This configuration uses the shared infrastructure modules from the parent
# directory. All infrastructure definitions are centralised in ../../
# ============================================================================

module "knowsee_infrastructure" {
  source = "../../"

  # Project configuration
  project_name           = var.project_name
  prod_project_id        = var.prod_project_id
  staging_project_id     = var.staging_project_id
  cicd_runner_project_id = var.cicd_runner_project_id

  # Repository configuration
  repository_owner  = var.repository_owner
  repository_name   = var.repository_name
  create_repository = var.create_repository

  # Region configuration
  region            = var.region
  data_store_region = var.data_store_region

  # Pipeline configuration
  pipeline_cron_schedule = var.pipeline_cron_schedule

  # Role assignments (using defaults if not specified)
  app_sa_roles                      = var.app_sa_roles
  cicd_roles                        = var.cicd_roles
  cicd_sa_deployment_required_roles = var.cicd_sa_deployment_required_roles
  pipelines_roles                   = var.pipelines_roles
}

# Output important values from the infrastructure module
output "service_accounts" {
  description = "Service accounts created by the infrastructure"
  value       = module.knowsee_infrastructure.service_accounts
}

output "buckets" {
  description = "Storage buckets created by the infrastructure"
  value       = module.knowsee_infrastructure.buckets
}

output "discovery_engine_datastores" {
  description = "Discovery Engine datastores created"
  value       = module.knowsee_infrastructure.discovery_engine_datastores
}
