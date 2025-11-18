terraform {
  backend "gcs" {
    bucket = "terraform-knowsee-development"
    prefix = "terraform/state"
  }
}
