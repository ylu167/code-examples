variable "project_id" {
  type = string
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "dataproc.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false

  timeouts {
    create = "10m"
    update = "10m"
  }
}

output "enabled_apis" {
  value = [for api in google_project_service.required_apis : api.service]
}
