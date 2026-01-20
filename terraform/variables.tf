variable "project_id" {
  type = string
  default = "project-1"
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "zone" {
  type = string
  default = "us-central1-a"
}

variable "dataproc_region" {
  type = string
  default = "us-central1"
}

variable "k8s_namespace" {
  type = string
  default = "ci"
}

variable "artifact_repo_name" {
  type = string
  default = "project-1"
}

variable "gke_cluster_name" {
  type = string
  default = "gke-cluster"
}

variable "dataproc_cluster_name" {
  type = string
  default = "hadoop-cluster"
}

variable "github_repo_url" {
  type = string
  default = "https://github.com/sobolevn/python-code-disasters"
}

variable "jenkins_image_tag" {
  type = string
  default = "lts"
}

variable "sonarqube_image_tag" {
  type = string
  default = "latest"
}
