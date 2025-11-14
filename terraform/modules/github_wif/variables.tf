variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
}

variable "pool_display_name" {
  description = "Display name for the Workload Identity Pool"
  type        = string
  default     = "GitHub Actions Pool"
}

variable "pool_description" {
  description = "Description for the Workload Identity Pool"
  type        = string
  default     = "Workload Identity Pool for GitHub Actions"
}

variable "pool_disabled" {
  description = "Whether the pool is disabled"
  type        = bool
  default     = false
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
}

variable "provider_display_name" {
  description = "Display name for the Workload Identity Provider"
  type        = string
  default     = "GitHub OIDC Provider"
}

variable "provider_description" {
  description = "Description for the Workload Identity Provider"
  type        = string
  default     = "OIDC provider for GitHub Actions"
}

variable "provider_disabled" {
  description = "Whether the provider is disabled"
  type        = bool
  default     = false
}

variable "issuer_uri" {
  description = "OIDC issuer URI"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "attribute_mapping" {
  description = "Attribute mapping for the provider"
  type        = map(string)
  default = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }
}

variable "attribute_condition" {
  description = "Attribute condition for the provider"
  type        = string
  default     = null
}

variable "repository_owner" {
  description = "GitHub repository owner (for IAM bindings)"
  type        = string
  default     = ""
}

variable "repository_name" {
  description = "GitHub repository name (for IAM bindings)"
  type        = string
  default     = ""
}

variable "service_account_email" {
  description = "Service account email to grant access to (optional)"
  type        = string
  default     = null
}

variable "service_account_id" {
  description = "Service account ID (full resource name) to grant access to (optional)"
  type        = string
  default     = null
}

variable "grant_token_creator" {
  description = "Whether to grant token creator role to the service account"
  type        = bool
  default     = true
}
