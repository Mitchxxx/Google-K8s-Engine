variable "project_id" {
  type    = string
  default = "edurekaproject-340011"
}


variable "region" {
  type    = string
  default = "europe-west1"
}

variable "state_bucket" {
  type    = string
  default = "mitch-devops-terraform-bucket"
}

variable "cluster_name" {
  type    = string
  default = "terraform-gke-cluster"
}


variable "min_node_count" {
  type    = number
  default = "1"
}

variable "max_node_count" {
  type    = number
  default = "3"
}

variable "machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "preemptible" {
  type    = bool
  default = true
}