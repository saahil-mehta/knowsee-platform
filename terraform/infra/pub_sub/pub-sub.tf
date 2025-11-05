# Pub/Sub topics and subscriptions for staging

# Example Topic:
# module "example_topic" {
#   source = "../modules/pub_sub"
#
#   project_id = var.project_id
#   name       = "staging-example-topic"
#
#   labels = local.common_labels
# }

# Example Subscription:
# resource "google_pubsub_subscription" "example_sub" {
#   name  = "staging-example-subscription"
#   topic = module.example_topic.id
#
#   ack_deadline_seconds = 20
#
#   push_config {
#     push_endpoint = "https://example.com/push"
#   }
# }
