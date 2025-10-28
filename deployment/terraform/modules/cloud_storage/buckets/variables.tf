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

variable "buckets" {
  description = "Map of bucket configurations"
  type = map(object({
    name                        = string
    location                    = string
    project                     = string
    storage_class               = optional(string, "STANDARD")
    uniform_bucket_level_access = optional(bool, true)
    force_destroy               = optional(bool, false)
    versioning_enabled          = optional(bool, false)
    labels                      = optional(map(string), {})
    lifecycle_rules = optional(list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })
      condition = object({
        age                        = optional(number)
        created_before             = optional(string)
        with_state                 = optional(string)
        matches_storage_class      = optional(list(string))
        num_newer_versions         = optional(number)
        days_since_custom_time     = optional(number)
        days_since_noncurrent_time = optional(number)
        noncurrent_time_before     = optional(string)
      })
    })), [])
  }))
}
