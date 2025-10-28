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

# This file contains terraform outputs for the knowsee infrastructure.
# Add outputs here as needed for use by other systems or for documentation.

# Example outputs (commented out for now):

# output "service_account_emails" {
#   description = "Emails of created service accounts"
#   value = {
#     for key, sa in module.service_accounts :
#     key => sa.email
#   }
# }

# output "bucket_names" {
#   description = "Names of created storage buckets"
#   value = {
#     load_test = google_storage_bucket.bucket_load_test_results.name
#     logs      = [for bucket in google_storage_bucket.logs_data_bucket : bucket.name]
#     rag       = [for bucket in google_storage_bucket.data_ingestion_pipeline_gcs_root : bucket.name]
#   }
# }
