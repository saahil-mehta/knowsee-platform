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

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "cicd_runner_project_id" {
  type        = string
  description = "CICD runner project ID"
}

variable "cicd_roles" {
  type        = list(string)
  description = "CICD SA roles on CICD project"
}

variable "cicd_sa_deployment_required_roles" {
  type        = list(string)
  description = "CICD SA roles on deploy projects"
}

variable "app_sa_roles" {
  type        = list(string)
  description = "App SA roles"
}

variable "pipelines_roles" {
  type        = list(string)
  description = "Vertex AI Pipeline SA roles"
}
