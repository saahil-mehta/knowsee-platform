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

# Project name used for resource naming
project_name = "knowsee"

# Your Production Google Cloud project ID
prod_project_id = "your-production-project-id"

# Your Google Cloud project ID that will be used to host the Cloud Build pipelines
cicd_runner_project_id = "your-cicd-project-id"

repository_owner = "Your GitHub organisation or username."

# Name of the repository you added to Cloud Build
repository_name = "knowsee"

# The Google Cloud region you will use to deploy the infrastructure
region = "europe-west2"

pipeline_cron_schedule = "0 0 * * 0"

# The value can only be one of "global", "us" and "eu".
data_store_region = "eu"
