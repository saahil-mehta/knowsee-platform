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

locals {
  # Internal locals for project IDs
  deploy_project_ids = {
    staging = var.staging_project_id
    prod    = var.prod_project_id
  }

  all_project_ids = [
    var.cicd_runner_project_id,
    var.staging_project_id,
    var.prod_project_id
  ]

  # Load test results bucket (CICD project)
  bucket_load_test_results = {
    name                        = "${var.cicd_runner_project_id}-${var.project_name}-load-test"
    location                    = var.region
    project                     = var.cicd_runner_project_id
    storage_class               = "STANDARD"
    uniform_bucket_level_access = true
    force_destroy               = true
    versioning_enabled          = false
    labels                      = {}
    lifecycle_rules             = []
  }

  # Logs buckets (one per project: cicd, staging, prod)
  logs_data_buckets = merge(
    {
      cicd = {
        name                        = "${var.cicd_runner_project_id}-${var.project_name}-logs"
        location                    = var.region
        project                     = var.cicd_runner_project_id
        storage_class               = "STANDARD"
        uniform_bucket_level_access = true
        force_destroy               = true
        versioning_enabled          = false
        labels                      = {}
        lifecycle_rules             = []
      }
    },
    {
      for env, project_id in local.deploy_project_ids :
      env => {
        name                        = "${project_id}-${var.project_name}-logs"
        location                    = var.region
        project                     = project_id
        storage_class               = "STANDARD"
        uniform_bucket_level_access = true
        force_destroy               = true
        versioning_enabled          = false
        labels                      = {}
        lifecycle_rules             = []
      }
    }
  )

  # Data ingestion pipeline GCS roots (one per deploy project: staging, prod)
  data_ingestion_pipeline_gcs_roots = {
    for env, project_id in local.deploy_project_ids :
    env => {
      name                        = "${project_id}-${var.project_name}-rag"
      location                    = var.region
      project                     = project_id
      storage_class               = "STANDARD"
      uniform_bucket_level_access = true
      force_destroy               = true
      versioning_enabled          = false
      labels                      = {}
      lifecycle_rules             = []
    }
  }
}

output "bucket_load_test_results" {
  value       = local.bucket_load_test_results
  description = "Load test results bucket definition"
}

output "logs_data_buckets" {
  value       = local.logs_data_buckets
  description = "Map of logs buckets (one per project)"
}

output "data_ingestion_pipeline_gcs_roots" {
  value       = local.data_ingestion_pipeline_gcs_roots
  description = "Map of RAG pipeline GCS root buckets (one per deploy project)"
}
