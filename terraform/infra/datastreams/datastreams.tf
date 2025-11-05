# Datastream configuration for staging

# Example Private Connection:
# module "datastream_private_connection" {
#   source = "../modules/datastream/private_connection"
#
#   project_id = var.project_id
#   location   = var.region
#   name       = "staging-private-connection"
# }

# Example Connection Profile:
# module "datastream_connection_profile" {
#   source = "../modules/datastream/connection_profile"
#
#   project_id = var.project_id
#   location   = var.region
#   name       = "staging-connection-profile"
# }

# Example Stream:
# module "datastream" {
#   source = "../modules/datastream/stream"
#
#   project_id = var.project_id
#   location   = var.region
#   stream_id  = "staging-stream"
# }
