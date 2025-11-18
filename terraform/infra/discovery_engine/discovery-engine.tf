# Shared Vertex AI Discovery Engine configuration for dev/staging/prod environments

locals {
  environment_display_names = {
    dev     = "Search Engine App Dev"
    staging = "Search Engine App Staging"
    prod    = "Search Engine App Production"
  }

  discovery_engine_config = {
    datastore = {
      data_store_id               = "${var.resource_prefix}-${var.environment}-datastore"
      display_name                = "${var.resource_prefix}-${var.environment}-datastore"
      location                    = var.data_store_region
      industry_vertical           = "GENERIC"
      content_config              = "NO_CONTENT"
      solution_types              = ["SOLUTION_TYPE_SEARCH"]
      create_advanced_site_search = false
      create_search_engine        = true
      search_engine_id            = "${var.resource_prefix}-${var.environment}-search"
      search_engine_display_name  = local.environment_display_names[var.environment]
      search_tier                 = "SEARCH_TIER_ENTERPRISE"
    }
  }
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "data_store_region" {
  description = "Vertex AI Discovery Engine datastore region"
  type        = string
}
