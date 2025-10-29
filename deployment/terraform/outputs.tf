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
# MODULE OUTPUTS
# ============================================================================
# These outputs are exposed when this directory is used as a module by
# environment-specific configurations in environments/{dev,staging,prod}/
# ============================================================================

output "service_accounts" {
  description = "Service accounts created by the infrastructure"
  value       = module.service_accounts
}

output "buckets" {
  description = "Storage buckets created by the infrastructure"
  value       = module.storage_buckets
}

output "discovery_engine_datastores" {
  description = "Discovery Engine datastores created"
  value = {
    staging = try(module.discovery_engine_data_store_staging[*], [])
    prod    = try(module.discovery_engine_data_store_prod[*], [])
  }
}
