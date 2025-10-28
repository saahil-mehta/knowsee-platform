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

# NOTE: Discovery Engine resources don't have a module in data-platform-ingestion-pipelines.
# These definitions will remain as direct resources in main.tf.

locals {
  # Data stores (one per deploy environment: staging, prod)
  data_stores = {
    staging = {
      location                    = var.data_store_region
      project                     = var.staging_project_id
      data_store_id               = "${var.project_name}-datastore"
      display_name                = "${var.project_name}-datastore"
      industry_vertical           = "GENERIC"
      content_config              = "NO_CONTENT"
      solution_types              = ["SOLUTION_TYPE_SEARCH"]
      create_advanced_site_search = false
      provider_alias              = "staging_billing_override"
    }
    prod = {
      location                    = var.data_store_region
      project                     = var.prod_project_id
      data_store_id               = "${var.project_name}-datastore"
      display_name                = "${var.project_name}-datastore"
      industry_vertical           = "GENERIC"
      content_config              = "NO_CONTENT"
      solution_types              = ["SOLUTION_TYPE_SEARCH"]
      create_advanced_site_search = false
      provider_alias              = "prod_billing_override"
    }
  }

  # Search engines (one per deploy environment: staging, prod)
  search_engines = {
    staging = {
      project        = var.staging_project_id
      engine_id      = "${var.project_name}-search"
      collection_id  = "default_collection"
      display_name   = "Search Engine App Staging"
      search_tier    = "SEARCH_TIER_ENTERPRISE"
      provider_alias = "staging_billing_override"
      # data_store_id and location will be set dynamically from the data_store resource
    }
    prod = {
      project        = var.prod_project_id
      engine_id      = "${var.project_name}-search"
      collection_id  = "default_collection"
      display_name   = "Search Engine App Prod"
      search_tier    = "SEARCH_TIER_ENTERPRISE"
      provider_alias = "prod_billing_override"
      # data_store_id and location will be set dynamically from the data_store resource
    }
  }
}

output "data_stores" {
  value       = local.data_stores
  description = "Map of discovery engine data store definitions"
}

output "search_engines" {
  value       = local.search_engines
  description = "Map of discovery engine search engine definitions"
}
