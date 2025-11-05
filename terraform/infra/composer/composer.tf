# Cloud Composer (Airflow) environment for staging

# Example Composer Environment:
# module "composer" {
#   source = "../modules/composer"
#
#   project_id = var.project_id
#   name       = "staging-composer"
#   region     = var.region
#
#   node_count = 3
#   node_config = {
#     machine_type = "n1-standard-4"
#     disk_size_gb = 100
#   }
#
#   software_config = {
#     image_version = "composer-2-airflow-2"
#     python_version = "3"
#   }
# }
