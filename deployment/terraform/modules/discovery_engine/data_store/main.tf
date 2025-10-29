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

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_discovery_engine_data_store" "data_stores" {
  for_each = var.data_stores

  data_store_id     = each.value.data_store_id
  display_name      = each.value.display_name
  industry_vertical = each.value.industry_vertical
  content_config    = each.value.content_config
  solution_types    = each.value.solution_types
  location          = each.value.location
  project           = each.value.project
}
