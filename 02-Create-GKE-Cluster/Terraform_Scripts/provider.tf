provider "google" {
  credentials = file("./edurekaproject-340011-933f7f30dc2e.json")
  project     = var.project_id
  region      = var.region
}

terraform {
  backend "gcs" {
    bucket      = "mitch-devops-terraform-bucket"
    prefix      = "terraform/state"
    credentials = "edurekaproject-340011-933f7f30dc2e.json"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}