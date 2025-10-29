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

  service_accounts = merge(
    # CICD Runner Service Account
    {
      cicd_runner = {
        account_id   = "${var.project_name}-cb"
        display_name = "CICD Runner SA"
        description  = "Service account used by Cloud Build for CICD operations"
        project_id   = var.cicd_runner_project_id
      }
    },
    # App Service Accounts (one per deploy project)
    {
      for env, project_id in local.deploy_project_ids :
      "app_${env}" => {
        account_id   = "${var.project_name}-app"
        display_name = "${var.project_name} Agent Service Account"
        description  = "Service account for running the ${var.project_name} agent in ${env}"
        project_id   = project_id
      }
    },
    # Vertex AI Pipeline Service Accounts (one per deploy project)
    {
      for env, project_id in local.deploy_project_ids :
      "vertexai_pipeline_${env}" => {
        account_id   = "${var.project_name}-rag"
        display_name = "Vertex AI Pipeline app SA"
        description  = "Service account for running Vertex AI pipelines in ${env}"
        project_id   = project_id
      }
    }
  )
}

output "service_accounts" {
  value       = local.service_accounts
  description = "Map of service account definitions"
}
