variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "sink_name" {
  description = "Name of the log sink"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
}

variable "dataset_friendly_name" {
  description = "Friendly name for the BigQuery dataset"
  type        = string
}

variable "location" {
  description = "Location for the BigQuery dataset"
  type        = string
  default     = "US"
}

variable "filter" {
  description = "Log filter for the sink"
  type        = string
}

variable "use_partitioned_tables" {
  description = "Whether to use partitioned tables in BigQuery"
  type        = bool
  default     = true
}

variable "prevent_destroy" {
  description = "Prevent accidental deletion of the dataset"
  type        = bool
  default     = false
}
