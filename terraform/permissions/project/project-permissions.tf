# Project-level IAM permissions for staging

# Example Project IAM Bindings:
# module "project_iam" {
#   source = "../modules/iam/project"
#
#   project_id = var.project_id
#
#   bindings = {
#     "roles/compute.viewer" = [
#       "serviceAccount:${module.service_accounts.monitoring_sa_email}",
#     ]
#     "roles/storage.admin" = [
#       "serviceAccount:${module.service_accounts.storage_admin_sa_email}",
#     ]
#     "roles/bigquery.admin" = [
#       "serviceAccount:${module.service_accounts.bq_admin_sa_email}",
#     ]
#   }
# }
