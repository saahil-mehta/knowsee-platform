variable "name" {
  description = "Name of the storage bucket"
  type        = string
}

variable "location" {
  description = "Location of the storage bucket"
  type        = string
}

variable "project" {
  description = "GCP project ID"
  type        = string
}

variable "labels" {
  description = "Labels to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "When deleting a bucket, delete all objects first"
  type        = bool
  default     = false
}

variable "versioning" {
  description = "Enable versioning on the bucket"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "lifecycle_rules" {
  description = "Optional lifecycle rules"
  type = list(object({
    action    = map(string)
    condition = map(any)
  }))
  default = []
}
