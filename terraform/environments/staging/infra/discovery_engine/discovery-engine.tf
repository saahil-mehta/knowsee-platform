output "discovery_engine_config" {
  description = "Vertex AI Discovery Engine configuration"
  value = {
    datastore = {
      data_store_id               = "${var.project_name}-datastore"
      display_name                = "${var.project_name}-datastore"
      location                    = var.data_store_region
      industry_vertical           = "GENERIC"
      content_config              = "NO_CONTENT"
      solution_types              = ["SOLUTION_TYPE_SEARCH"]
      create_advanced_site_search = false
      create_search_engine        = true
      search_engine_id            = "${var.project_name}-search"
      search_engine_display_name  = "Search Engine App Staging"
      search_tier                 = "SEARCH_TIER_ENTERPRISE"
    }
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "data_store_region" {
  description = "Vertex AI Discovery Engine datastore region"
  type        = string
}
