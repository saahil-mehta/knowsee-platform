# Compute Engine VMs for staging

# Example VM:
# module "example_vm" {
#   source = "../modules/compute"
#
#   project_id   = var.project_id
#   name         = "staging-example-vm"
#   zone         = "${var.region}-a"
#   machine_type = "e2-medium"
#
#   boot_disk = {
#     image = "debian-cloud/debian-11"
#     size  = 50
#   }
#
#   network_interface = {
#     network = "default"
#   }
#
#   labels = local.common_labels
# }
