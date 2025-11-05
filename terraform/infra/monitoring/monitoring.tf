# Monitoring, logging, and alerting for staging

# Example Alert Policy:
# module "example_alert" {
#   source = "../modules/monitoring"
#
#   project_id = var.project_id
#
#   alert_policies = {
#     high_error_rate = {
#       display_name = "High Error Rate - Staging"
#       conditions = [{
#         display_name = "Error rate above threshold"
#         # Add condition configuration
#       }]
#     }
#   }
# }
