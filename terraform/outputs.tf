output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  value = module.gke.cluster_endpoint
  sensitive = true
}

output "jenkins_url" {
  value = module.kubernetes_apps.jenkins_url
}

output "sonarqube_url" {
  value = module.kubernetes_apps.sonarqube_url
}

output "jenkins_internal_url" {
  value = module.kubernetes_apps.jenkins_internal_url
}

output "sonarqube_internal_url" {
  value = module.kubernetes_apps.sonarqube_internal_url
}

output "dataproc_cluster_name" {
  value = module.dataproc.cluster_name
}

output "dataproc_master_instance" {
  value = module.dataproc.master_instance_name
}

output "gcs_bucket_name" {
  value = module.gcs.bucket_name
}

output "gcs_bucket_url" {
  value = module.gcs.bucket_url
}

output "jenkins_image" {
  value = module.artifact_registry.jenkins_image
}

output "sonarqube_image" {
  value = module.artifact_registry.sonarqube_image
}

output "jenkins_service_account" {
  value = module.iam.jenkins_sa_email
}

output "k8s_namespace" {
  value = module.kubernetes_apps.namespace
}

output "get_jenkins_password_command" {
  value = "kubectl -n ${var.k8s_namespace} exec -it deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
}

output "get_gke_credentials_command" {
  value = "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone ${var.zone} --project ${var.project_id}"
}

output "view_hadoop_results_command" {
  value = "gsutil ls gs://${module.gcs.bucket_name}/output/"
}

output "ssh_to_dataproc_master_command" {
  value = "gcloud compute ssh ${module.dataproc.master_instance_name} --zone=${var.dataproc_region}-a --project=${var.project_id}"
}

output "get_sonarqube_token_command" {
  value = "kubectl logs -n ${var.k8s_namespace} -l app=sonarqube-config --tail=100 | grep 'PROJECT Token generated:' | awk '{print $NF}'"
}

output "sonarqube_token" {
  value = "Run: terraform output -raw get_sonarqube_token_command | bash"
}

output "jenkins_env_project_id" {
  value = var.project_id
}

output "jenkins_env_region" {
  value = var.region
}

output "jenkins_env_cluster" {
  value = module.dataproc.cluster_name
}

output "jenkins_env_bucket" {
  value = module.gcs.bucket_name
}

output "jenkins_env_sonarqube" {
  value = "sonar"
}

output "jenkins_environment_vars" {
  value = jsonencode({
    SONARQUBE = "sonar"
    PROJECT_ID = var.project_id
    REGION = var.region
    CLUSTER = module.dataproc.cluster_name
    BUCKET = module.gcs.bucket_name
  })
}

output "jenkinsfile_environment_block" {
  value = <<-EOT
  environment {
    SONARQUBE = 'sonar'
    PROJECT_ID = '${var.project_id}'
    REGION = '${var.region}'
    CLUSTER = '${module.dataproc.cluster_name}'
    BUCKET = '${module.gcs.bucket_name}'
    OUT_DIR = "gs://$${BUCKET}/output/run-$${env.BUILD_NUMBER}-$${new Date().getTime()}"
  }
  EOT
}

output "next_steps" {
  value = <<-EOT
    ==================================================
    Terraform Deployment Completed Successfully!
    ==================================================

    Infrastructure deployed:
    - GKE Cluster: ${module.gke.cluster_name}
    - Dataproc Cluster: ${module.dataproc.cluster_name}
    - Jenkins: ${module.kubernetes_apps.jenkins_url}
    - SonarQube: ${module.kubernetes_apps.sonarqube_url}
    - GCS Bucket: ${module.gcs.bucket_name}

    1. Access Jenkins at: ${module.kubernetes_apps.jenkins_url}
    2. Get Jenkins password: kubectl -n ${var.k8s_namespace} exec -it deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
    3. Access SonarQube at: ${module.kubernetes_apps.sonarqube_url}
    4. Follow manual setup steps in README.md to configure the pipeline

    View Hadoop results:
    gsutil ls gs://${module.gcs.bucket_name}/output/
  EOT
}
