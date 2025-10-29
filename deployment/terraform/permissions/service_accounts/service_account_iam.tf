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

# Service account IAM bindings for CICD runner SA

locals {
  # CICD SA self-referencing permissions
  cicd_sa_self_bindings = {
    "roles/iam.serviceAccountTokenCreator" = {
      members = ["serviceAccount:${var.project_name}-cb@${var.cicd_runner_project_id}.iam.gserviceaccount.com"]
    }
    "roles/iam.serviceAccountUser" = {
      members = ["serviceAccount:${var.project_name}-cb@${var.cicd_runner_project_id}.iam.gserviceaccount.com"]
    }
  }
}

output "cicd_sa_self_bindings" {
  value       = local.cicd_sa_self_bindings
  description = "CICD SA self-referencing IAM bindings"
}
