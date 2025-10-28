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

variable "search_engines" {
  description = "Map of Discovery Engine search engine configurations"
  type = map(object({
    engine_id         = string
    display_name      = string
    data_store_ids    = list(string)
    collection_id     = string
    location          = string
    project           = string
    industry_vertical = optional(string, "GENERIC")
    search_engine_config = object({
      search_tier    = string
      search_add_ons = optional(list(string), [])
    })
  }))
}
