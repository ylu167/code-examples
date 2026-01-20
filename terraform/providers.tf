terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "google" {
  project = var.project_id
  region = var.region
}

provider "google-beta" {
  project = var.project_id
  region = var.region
}

provider "kubernetes" {
  host = module.gke.cluster_endpoint
  token = module.gke.cluster_token
  cluster_ca_certificate = module.gke.cluster_ca_certificate
}

provider "kubectl" {
  host = module.gke.cluster_endpoint
  token = module.gke.cluster_token
  cluster_ca_certificate = module.gke.cluster_ca_certificate
  load_config_file = false
}
