terraform {
  backend "gcs" {
    bucket = "terraform-knowsee-staging"
    prefix = "terraform/state"
  }
}
