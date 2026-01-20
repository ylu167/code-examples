variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "jenkins_sa_email" {
  type = string
}

variable "apis_enabled" {
  type = list(string)
}

resource "google_container_cluster" "gke_cluster" {
  name = var.cluster_name
  location = var.zone
  project = var.project_id

  remove_default_node_pool = true
  initial_node_count = 1

  deletion_protection = false

  network = "default"
  subnetwork = "default"

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  depends_on = [var.apis_enabled]
}

resource "google_container_node_pool" "primary_nodes" {
  name = "${var.cluster_name}-node-pool"
  location = var.zone
  cluster = google_container_cluster.gke_cluster.name
  node_count = 2

  node_config {
    machine_type = "e2-standard-2"
    disk_size_gb = 50
    disk_type = "pd-standard"

    service_account = var.jenkins_sa_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      env = "ci"
    }

    tags = ["gke-node", "ci"]
  }

  management {
    auto_repair = true
    auto_upgrade = true
  }
}

data "google_client_config" "default" {}

data "google_container_cluster" "gke_cluster" {
  name = google_container_cluster.gke_cluster.name
  location = var.zone
  project = var.project_id

  depends_on = [google_container_node_pool.primary_nodes]
}

output "cluster_name" {
  value = google_container_cluster.gke_cluster.name
}

output "cluster_endpoint" {
  value = "https://${google_container_cluster.gke_cluster.endpoint}"
  sensitive = true
}

output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate)
  sensitive = true
}

output "cluster_token" {
  value = data.google_client_config.default.access_token
  sensitive = true
}
