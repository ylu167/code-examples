variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "repository_name" {
  type = string
}

variable "apis_enabled" {
  type = list(string)
}

resource "google_artifact_registry_repository" "docker_repo" {
  project = var.project_id
  location = var.region
  repository_id = var.repository_name
  format = "DOCKER"

  depends_on = [var.apis_enabled]
}

resource "time_sleep" "wait_for_repo" {
  depends_on = [google_artifact_registry_repository.docker_repo]
  create_duration = "30s"
}

resource "null_resource" "push_jenkins_image" {
  triggers = {
    repo_id = google_artifact_registry_repository.docker_repo.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Configuring Docker authentication for Artifact Registry..."
      gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet

      echo "Creating temporary Dockerfile for Jenkins..."
      mkdir -p /tmp/jenkins-build
      cat > /tmp/jenkins-build/Dockerfile <<'DOCKERFILE'
FROM jenkins/jenkins:lts
DOCKERFILE

      echo "Building and pushing Jenkins image with buildx (amd64/x86_64)..."
      cd /tmp/jenkins-build
      docker buildx build \
        --platform linux/amd64 \
        --push \
        -t ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}/jenkins:latest \
        .

      echo "Cleaning up..."
      rm -rf /tmp/jenkins-build

      echo "Jenkins image pushed successfully with amd64 architecture!"
    EOT
  }

  depends_on = [time_sleep.wait_for_repo]
}

resource "null_resource" "push_sonarqube_image" {
  triggers = {
    repo_id = google_artifact_registry_repository.docker_repo.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Creating temporary Dockerfile for SonarQube..."
      mkdir -p /tmp/sonarqube-build
      cat > /tmp/sonarqube-build/Dockerfile <<'DOCKERFILE'
FROM sonarqube:latest
DOCKERFILE

      echo "Building and pushing SonarQube image with buildx (amd64/x86_64)..."
      cd /tmp/sonarqube-build
      docker buildx build \
        --platform linux/amd64 \
        --push \
        -t ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}/sonarqube:latest \
        .

      echo "Cleaning up..."
      rm -rf /tmp/sonarqube-build

      echo "SonarQube image pushed successfully with amd64 architecture!"
    EOT
  }

  depends_on = [null_resource.push_jenkins_image]
}

output "repository_id" {
  value = google_artifact_registry_repository.docker_repo.id
}

output "jenkins_image" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}/jenkins:latest"
}

output "sonarqube_image" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}/sonarqube:latest"
}

output "images_ready" {
  value = null_resource.push_sonarqube_image.id
}
