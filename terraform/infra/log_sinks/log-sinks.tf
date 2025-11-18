# Shared log sinks configuration for dev/staging/prod environments

locals {
  log_sinks = {
    telemetry = {
      sink_name             = "${var.resource_prefix}_${var.environment}_telemetry"
      dataset_id            = "${var.resource_prefix}_${var.environment}_telemetry"
      dataset_friendly_name = "${var.resource_prefix}_${var.environment}_telemetry"
      location              = var.region
      filter                = "labels.service_name=\"${var.resource_prefix}-${var.environment}\" labels.type=\"agent_telemetry\""
    }
    feedback = {
      sink_name             = "${var.resource_prefix}_${var.environment}_feedback"
      dataset_id            = "${var.resource_prefix}_${var.environment}_feedback"
      dataset_friendly_name = "${var.resource_prefix}_${var.environment}_feedback"
      location              = var.region
      filter                = "jsonPayload.log_type=\"feedback\""
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

variable "region" {
  description = "GCP region"
  type        = string
}
