terraform {
  backend "gcs" {
    bucket = "terraform-knowsee-prod"
    prefix = "terraform/state"
  }
}
