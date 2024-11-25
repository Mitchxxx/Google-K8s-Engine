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

resource "google_storage_bucket" "remote-state" {
  name          = var.state_bucket
  location      = var.region
  project       = var.project_id
  storage_class = "STANDARD"
  force_destroy = true
  versioning {
    enabled = true
  }
}

resource "google_container_cluster" "primary" {
  name                     = var.cluster_name
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = var.min_node_count
  deletion_protection      = false
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-nodes"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1
  project    = var.project_id

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    preemptible  = var.preemptible
    machine_type = var.machine_type
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
}

#Create a repository using the google_artifact_registry_repository block to save the Docker image
resource "google_artifact_registry_repository" "google_artifact_registry_repository" {
  project       = var.project_id
  location      = var.region
  repository_id = "cloud-run-artifact-repository"
  format        = "DOCKER"
  description   = "Cloud-run Repository"
}

#Assign an IAM policy using the google_artifact_registry_repository_iam_binding block
resource "google_artifact_registry_repository_iam_binding" "google_artifact_registry_repository_iam_binding" {
  members = [
  "serviceAccount:edurekaterraform@edurekaproject-340011.iam.gserviceaccount.com"]
  repository = google_artifact_registry_repository.google_artifact_registry_repository.name
  role       = "roles/artifactregistry.writer"
  location   = var.region
  project    = var.project_id
}

# Enable Cloud Run APIs
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
  disable_on_destroy = true
}

# Deploy the Image in Artifact registry to Cloud Run
resource "google_cloud_run_service" "default" {
  name = "cloudrun-service"
  location = var.region

  template {
    spec {
      containers {
        image = "europe-west1-docker.pkg.dev/edurekaproject-340011/cloud-run-artifact-repository/manageapp:latest"
      }
    }
  }
  traffic {
    percent = 100
    latest_revision = true
  }
}

data "google_iam_policy" "noauth" {
  binding {
    members = ["allUsers"]
    role = "roles/run.invoker"
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  service     = google_cloud_run_service.default.name
  location    = google_cloud_run_service.default.location
  project     = google_cloud_run_service.default.project
  policy_data = data.google_iam_policy.noauth.policy_data
}