variable "project_id" {
  type = string
}

resource "google_service_account" "jenkins_sa" {
  project = var.project_id
  account_id = "jenkins-sa"
}

resource "google_project_iam_member" "jenkins_dataproc_editor" {
  project = var.project_id
  role = "roles/dataproc.editor"
  member = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

resource "google_project_iam_member" "jenkins_dataproc_worker" {
  project = var.project_id
  role = "roles/dataproc.worker"
  member = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

resource "time_sleep" "wait_for_iam" {
  depends_on = [
    google_project_iam_member.jenkins_dataproc_editor,
    google_project_iam_member.jenkins_dataproc_worker,
    google_project_iam_member.jenkins_storage_admin,
    google_project_iam_member.jenkins_logging_writer,
    google_project_iam_member.jenkins_monitoring_writer,
    google_project_iam_member.jenkins_sa_user,
    google_project_iam_member.jenkins_artifact_registry_reader
  ]

  create_duration = "60s"
}

resource "google_project_iam_member" "jenkins_storage_admin" {
  project = var.project_id
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

resource "google_project_iam_member" "jenkins_logging_writer" {
  project = var.project_id
  role = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

resource "google_project_iam_member" "jenkins_monitoring_writer" {
  project = var.project_id
  role = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

resource "google_project_iam_member" "jenkins_sa_user" {
  project = var.project_id
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

resource "google_project_iam_member" "jenkins_artifact_registry_reader" {
  project = var.project_id
  role = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

output "jenkins_sa_email" {
  value = google_service_account.jenkins_sa.email
}

output "jenkins_sa_name" {
  value = google_service_account.jenkins_sa.name
}

output "iam_wait_id" {
  value = time_sleep.wait_for_iam.id
}
