variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "location" {
  description = "Location for the data store (e.g., 'us', 'eu', 'global')"
  type        = string
  default     = "us"
}

variable "data_store_id" {
  description = "ID of the data store"
  type        = string
}

variable "display_name" {
  description = "Display name of the data store"
  type        = string
}

variable "industry_vertical" {
  description = "Industry vertical (GENERIC, RETAIL, MEDIA, HEALTHCARE_FHIR)"
  type        = string
  default     = "GENERIC"
}

variable "content_config" {
  description = "Content configuration (NO_CONTENT, CONTENT_REQUIRED, PUBLIC_WEBSITE)"
  type        = string
  default     = "NO_CONTENT"
}

variable "solution_types" {
  description = "Solution types (e.g., SOLUTION_TYPE_SEARCH, SOLUTION_TYPE_RECOMMENDATION)"
  type        = list(string)
  default     = ["SOLUTION_TYPE_SEARCH"]
}

variable "create_advanced_site_search" {
  description = "Whether to create advanced site search"
  type        = bool
  default     = false
}

variable "create_search_engine" {
  description = "Whether to create a search engine"
  type        = bool
  default     = true
}

variable "search_engine_id" {
  description = "ID of the search engine"
  type        = string
  default     = ""
}

variable "search_engine_display_name" {
  description = "Display name of the search engine"
  type        = string
  default     = ""
}

variable "collection_id" {
  description = "Collection ID for the search engine"
  type        = string
  default     = "default_collection"
}

variable "search_tier" {
  description = "Search tier (SEARCH_TIER_STANDARD, SEARCH_TIER_ENTERPRISE)"
  type        = string
  default     = "SEARCH_TIER_ENTERPRISE"
}
