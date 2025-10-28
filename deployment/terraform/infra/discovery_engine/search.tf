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

locals {
  # Data stores (one per deploy environment: staging, prod)
  data_stores_staging = {
    staging = {
      location          = var.data_store_region
      project           = var.staging_project_id
      data_store_id     = "${var.project_name}-datastore"
      display_name      = "${var.project_name}-datastore"
      industry_vertical = "GENERIC"
      content_config    = "NO_CONTENT"
      solution_types    = ["SOLUTION_TYPE_SEARCH"]
    }
  }

  data_stores_prod = {
    prod = {
      location          = var.data_store_region
      project           = var.prod_project_id
      data_store_id     = "${var.project_name}-datastore"
      display_name      = "${var.project_name}-datastore"
      industry_vertical = "GENERIC"
      content_config    = "NO_CONTENT"
      solution_types    = ["SOLUTION_TYPE_SEARCH"]
    }
  }

  # Search engines (one per deploy environment: staging, prod)
  # Note: data_store_ids will be populated from module outputs in main.tf
  search_engines_staging = {
    staging = {
      project           = var.staging_project_id
      engine_id         = "${var.project_name}-search"
      collection_id     = "default_collection"
      display_name      = "Search Engine App Staging"
      location          = var.data_store_region
      data_store_ids    = [] # Will be populated dynamically in main.tf
      industry_vertical = "GENERIC"
      search_engine_config = {
        search_tier    = "SEARCH_TIER_ENTERPRISE"
        search_add_ons = []
      }
    }
  }

  search_engines_prod = {
    prod = {
      project           = var.prod_project_id
      engine_id         = "${var.project_name}-search"
      collection_id     = "default_collection"
      display_name      = "Search Engine App Prod"
      location          = var.data_store_region
      data_store_ids    = [] # Will be populated dynamically in main.tf
      industry_vertical = "GENERIC"
      search_engine_config = {
        search_tier    = "SEARCH_TIER_ENTERPRISE"
        search_add_ons = []
      }
    }
  }
}

output "data_stores_staging" {
  value       = local.data_stores_staging
  description = "Staging discovery engine data store definitions"
}

output "data_stores_prod" {
  value       = local.data_stores_prod
  description = "Prod discovery engine data store definitions"
}

output "search_engines_staging" {
  value       = local.search_engines_staging
  description = "Staging discovery engine search engine definitions"
}

output "search_engines_prod" {
  value       = local.search_engines_prod
  description = "Prod discovery engine search engine definitions"
}
