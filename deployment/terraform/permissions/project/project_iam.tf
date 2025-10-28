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

# NOTE: Project IAM bindings use google_project_iam_member (additive) via the
# iam/project_member module rather than google_project_iam_binding (authoritative).
# This is safer as it won't override existing IAM bindings on the project.

locals {
  # CICD Service Account email
  cicd_sa_email = "${var.project_name}-cb@${var.cicd_runner_project_id}.iam.gserviceaccount.com"

  # Role lists by purpose
  cicd_sa_cicd_project_roles   = var.cicd_roles
  cicd_sa_deploy_project_roles = var.cicd_sa_deployment_required_roles
  app_sa_roles                 = var.app_sa_roles
  vertexai_pipeline_sa_roles   = var.pipelines_roles
}

output "cicd_sa_email" {
  value       = local.cicd_sa_email
  description = "CICD Service Account email"
}

output "cicd_sa_cicd_project_roles" {
  value       = local.cicd_sa_cicd_project_roles
  description = "CICD SA roles on CICD project"
}

output "cicd_sa_deploy_project_roles" {
  value       = local.cicd_sa_deploy_project_roles
  description = "CICD SA roles on deploy projects"
}

output "app_sa_roles" {
  value       = local.app_sa_roles
  description = "App SA roles on deploy projects"
}

output "vertexai_pipeline_sa_roles" {
  value       = local.vertexai_pipeline_sa_roles
  description = "Vertex AI Pipeline SA roles on deploy projects"
}
