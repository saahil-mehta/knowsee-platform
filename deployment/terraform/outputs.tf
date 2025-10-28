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

# Example outputs (uncomment and customize as needed):

# output "service_account_emails" {
#   description = "Emails of created service accounts"
#   value = {
#     for key, sa in module.service_accounts :
#     key => sa.email
#   }
# }

# output "bucket_names" {
#   description = "Names of created storage buckets"
#   value       = module.storage_buckets.bucket_names
# }

# output "data_store_ids" {
#   description = "Discovery Engine data store IDs"
#   value = {
#     staging = module.discovery_engine_data_store_staging.data_store_ids
#     prod    = module.discovery_engine_data_store_prod.data_store_ids
#   }
# }
