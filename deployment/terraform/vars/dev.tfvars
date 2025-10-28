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
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# ============================================================================
# For development, all three project IDs should point to your single dev project.
# Replace "your-dev-project-id" with your actual GCP project ID.

project_name = "knowsee"

# Single development project (replace with your actual project ID)
prod_project_id        = "your-dev-project-id"
staging_project_id     = "your-dev-project-id"
cicd_runner_project_id = "your-dev-project-id"

# Repository configuration (replace with your GitHub username/org)
repository_owner = "your-github-username"
repository_name  = "knowsee"

# Region configuration
region                 = "europe-west2"
pipeline_cron_schedule = "0 0 * * 0"
data_store_region      = "eu"

# Optional: set to true if you want terraform to create the GitHub repo
create_repository = false
