# Shared storage buckets configuration for dev/staging/prod environments

locals {
  buckets = {
    logs = {
      name          = "${var.resource_prefix}-${var.environment}-logs"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = false
      force_destroy = true
    }
    rag_pipeline = {
      name          = "${var.resource_prefix}-${var.environment}-rag"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = false
      force_destroy = true
    }
  }
}
