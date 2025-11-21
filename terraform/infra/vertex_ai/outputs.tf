output "agent_engine_resource_name" {
  description = "Full resource name of the Agent Engine (format: projects/{project}/locations/{location}/reasoningEngines/{id})"
  value       = data.external.agent_engine.result.resource_name
}

output "agent_engine_id" {
  description = "Agent Engine ID"
  value       = data.external.agent_engine.result.id
}

output "agent_engine_display_name" {
  description = "Agent Engine display name"
  value       = "${var.resource_prefix}-${var.environment}-agent-engine"
}
