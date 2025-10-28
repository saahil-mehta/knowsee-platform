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

output "buckets" {
  description = "Map of bucket resources"
  value       = google_storage_bucket.buckets
}

output "bucket_names" {
  description = "Map of bucket names"
  value       = { for k, v in google_storage_bucket.buckets : k => v.name }
}

output "bucket_urls" {
  description = "Map of bucket URLs"
  value       = { for k, v in google_storage_bucket.buckets : k => v.url }
}

output "bucket_self_links" {
  description = "Map of bucket self links"
  value       = { for k, v in google_storage_bucket.buckets : k => v.self_link }
}
