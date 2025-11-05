# BigQuery dataset IAM permissions for staging

# Example Dataset IAM Binding:
# module "dataset_iam" {
#   source = "../modules/iam/bindings/bigquery"
#
#   project_id = var.project_id
#   dataset_id = "staging_analytics"
#
#   bindings = {
#     "roles/bigquery.dataViewer" = [
#       "serviceAccount:${module.service_accounts.example_sa_email}",
#       "group:data-analysts@example.com",
#     ]
#     "roles/bigquery.dataEditor" = [
#       "serviceAccount:${module.service_accounts.etl_sa_email}",
#     ]
#   }
# }
