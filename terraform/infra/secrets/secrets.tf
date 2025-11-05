# Secret Manager secrets for staging

# Example Secret:
# module "example_secret" {
#   source = "../modules/secret_manager"
#
#   project_id = var.project_id
#   secret_id  = "staging-example-secret"
#
#   labels = local.common_labels
# }

# # Set secret value
# resource "google_secret_manager_secret_version" "example_secret_value" {
#   secret      = module.example_secret.id
#   secret_data = "your-secret-value"
# }
