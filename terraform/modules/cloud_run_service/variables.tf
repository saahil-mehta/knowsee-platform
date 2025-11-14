variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "location" {
  description = "GCP region for the Cloud Run service"
  type        = string
}

variable "image" {
  description = "Container image URL"
  type        = string
}

variable "cpu" {
  description = "CPU allocation for the container"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation for the container"
  type        = string
  default     = "512Mi"
}

variable "cpu_idle" {
  description = "Whether to throttle CPU when idle"
  type        = bool
  default     = true
}

variable "service_account_email" {
  description = "Email of the service account to run as"
  type        = string
}

variable "env_vars" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secret_env_vars" {
  description = "Secret environment variables from Secret Manager"
  type = list(object({
    name    = string
    secret  = string
    version = string
  }))
  default = []
}

variable "min_instance_count" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "max_instance_request_concurrency" {
  description = "Maximum concurrent requests per instance"
  type        = number
  default     = 80
}

variable "session_affinity" {
  description = "Enable session affinity"
  type        = bool
  default     = false
}

variable "traffic_type" {
  description = "Traffic allocation type"
  type        = string
  default     = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
}

variable "traffic_percent" {
  description = "Percentage of traffic to route to this revision"
  type        = number
  default     = 100
}

variable "ingress" {
  description = "Ingress settings (INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER)"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to the Cloud Run service"
  type        = map(string)
  default     = {}
}
