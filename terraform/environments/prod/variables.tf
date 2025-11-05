# Variables for prod environment

variable "project_id" {
  description = "GCP project ID for prod environment"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (staging/prod)"
  type        = string
  default     = "prod"
}

variable "enable_apis" {
  description = "List of GCP APIs to enable"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# Storage variables
variable "storage_buckets" {
  description = "Map of storage buckets to create"
  type = map(object({
    location      = string
    storage_class = string
    versioning    = bool
  }))
  default = {}
}

# BigQuery variables
variable "bigquery_datasets" {
  description = "Map of BigQuery datasets to create"
  type = map(object({
    location                    = string
    delete_contents_on_destroy  = bool
    default_table_expiration_ms = number
  }))
  default = {}
}

# Service Account variables
variable "service_accounts" {
  description = "Map of service accounts to create"
  type = map(object({
    display_name = string
    description  = string
  }))
  default = {}
}
