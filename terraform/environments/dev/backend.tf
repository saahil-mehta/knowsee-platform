terraform {
  backend "gcs" {
    bucket = "terraform-knowsee-dev"
    prefix = "terraform/state"
  }
}
