# BigQuery datasets configuration for staging
# Add dataset definitions here or manage via main.tf bigquery_datasets variable

# Example:
# module "custom_dataset" {
#   source = "../modules/bigquery/datasets"
#
#   project_id                  = var.project_id
#   dataset_id                  = "staging_custom_dataset"
#   location                    = "US"
#   delete_contents_on_destroy  = true
#   default_table_expiration_ms = 2592000000  # 30 days
#
#   labels = local.common_labels
# }
