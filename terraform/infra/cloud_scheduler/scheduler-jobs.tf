# Cloud Scheduler jobs configuration for staging

# Example Scheduler Job:
# module "example_scheduler" {
#   source = "../modules/cloud_scheduler"
#
#   project_id  = var.project_id
#   name        = "staging-example-scheduler"
#   description = "Example scheduled job"
#   schedule    = "0 0 * * *"  # Daily at midnight
#   time_zone   = "America/New_York"
#
#   http_target = {
#     uri         = "https://example.com/api/endpoint"
#     http_method = "POST"
#   }
# }
