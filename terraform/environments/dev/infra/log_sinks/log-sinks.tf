output "log_sinks" {
  description = "Log sinks configuration for BigQuery"
  value = {
    telemetry = {
      sink_name             = "${var.project_name}_telemetry"
      dataset_id            = replace("${var.project_name}_telemetry", "-", "_")
      dataset_friendly_name = "${var.project_name}_telemetry"
      location              = var.region
      filter                = "labels.service_name=\"${var.project_name}\" labels.type=\"agent_telemetry\""
    }
    feedback = {
      sink_name             = "${var.project_name}_feedback"
      dataset_id            = replace("${var.project_name}_feedback", "-", "_")
      dataset_friendly_name = "${var.project_name}_feedback"
      location              = var.region
      filter                = "jsonPayload.log_type=\"feedback\""
    }
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}
