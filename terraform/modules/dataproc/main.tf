variable "project_id" {
  type = string
}

variable "region" {
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

variable "iam_wait" {
  type = string
  default = ""
}

resource "google_dataproc_cluster" "hadoop_cluster" {
  name = var.cluster_name
  region = var.region
  project = var.project_id

  cluster_config {
    master_config {
      num_instances = 1
      machine_type = "n2-standard-2"

      disk_config {
        boot_disk_type = "pd-standard"
        boot_disk_size_gb = 100
      }
    }

    worker_config {
      num_instances = 2
      machine_type = "n2-standard-2"

      disk_config {
        boot_disk_type = "pd-standard"
        boot_disk_size_gb = 100
      }
    }

    software_config {
      image_version = "2.2-debian12"

      optional_components = ["DOCKER"]

      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "false"
      }
    }

    gce_cluster_config {
      service_account = var.jenkins_sa_email

      service_account_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]

      internal_ip_only = false

      tags = ["dataproc", "hadoop"]

      metadata = {
        "enable-oslogin" = "true"
      }
    }

    endpoint_config {
      enable_http_port_access = true
    }
  }

  depends_on = [var.apis_enabled, var.iam_wait]

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

output "cluster_name" {
  value = google_dataproc_cluster.hadoop_cluster.name
}

output "master_instance_name" {
  value = "${google_dataproc_cluster.hadoop_cluster.cluster_config[0].master_config[0].instance_names[0]}"
}

output "cluster_bucket" {
  value = google_dataproc_cluster.hadoop_cluster.cluster_config[0].bucket
}
