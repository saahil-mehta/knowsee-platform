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

output "data_stores" {
  description = "Map of Discovery Engine data store resources"
  value       = google_discovery_engine_data_store.data_stores
}

output "data_store_ids" {
  description = "Map of data store IDs"
  value       = { for k, v in google_discovery_engine_data_store.data_stores : k => v.data_store_id }
}

output "data_store_names" {
  description = "Map of data store names (fully qualified)"
  value       = { for k, v in google_discovery_engine_data_store.data_stores : k => v.name }
}
