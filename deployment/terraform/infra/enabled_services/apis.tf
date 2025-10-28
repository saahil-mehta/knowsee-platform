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
  # Enabled services per project
  project_enabled_services = merge(
    # CICD project services
    {
      cicd = {
        project_id       = var.cicd_runner_project_id
        enabled_services = local.cicd_services
      }
    },
    # Deploy project services (staging, prod)
    {
      for env, project_id in local.deploy_project_ids :
      env => {
        project_id       = project_id
        enabled_services = local.deploy_project_services
      }
    }
  )
}

output "project_enabled_services" {
  value       = local.project_enabled_services
  description = "Map of enabled services per project"
}
