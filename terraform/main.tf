resource "random_id" "bucket_suffix" {
  byte_length = 4
}

module "apis" {
  source = "./modules/apis"
  project_id = var.project_id
}

module "iam" {
  source = "./modules/iam"
  project_id = var.project_id
  depends_on = [module.apis]
}

module "artifact_registry" {
  source = "./modules/artifact-registry"
  project_id = var.project_id
  region = var.region
  repository_name = var.artifact_repo_name
  apis_enabled = module.apis.enabled_apis
}

module "gke" {
  source = "./modules/gke"
  project_id = var.project_id
  region = var.region
  zone = var.zone
  cluster_name = var.gke_cluster_name
  jenkins_sa_email = module.iam.jenkins_sa_email
  apis_enabled = module.apis.enabled_apis
}

module "dataproc" {
  source = "./modules/dataproc"
  project_id = var.project_id
  region = var.dataproc_region
  cluster_name = var.dataproc_cluster_name
  jenkins_sa_email = module.iam.jenkins_sa_email
  apis_enabled = module.apis.enabled_apis
  iam_wait = module.iam.iam_wait_id
}

module "gcs" {
  source = "./modules/gcs"
  project_id = var.project_id
  region = var.region
  bucket_suffix = random_id.bucket_suffix.hex
  depends_on = [module.apis]
}

resource "null_resource" "compile_mapreduce_jar" {
  triggers = {
    dataproc_cluster = module.dataproc.cluster_name
    gcs_bucket = module.gcs.bucket_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      cd ${path.module}/hadoop
      chmod +x compile_on_dataproc.sh
      ./compile_on_dataproc.sh ${var.project_id} ${module.dataproc.cluster_name} ${var.dataproc_region} ${module.gcs.bucket_name}
    EOT
  }

  depends_on = [
    module.dataproc,
    module.gcs
  ]
}

module "kubernetes_apps" {
  source = "./modules/kubernetes-apps"

  namespace = var.k8s_namespace
  jenkins_image = module.artifact_registry.jenkins_image
  sonarqube_image = module.artifact_registry.sonarqube_image
  project_id = var.project_id
  dataproc_cluster_name = module.dataproc.cluster_name
  dataproc_region = var.dataproc_region
  gcs_bucket = module.gcs.bucket_name
  github_repo_url = var.github_repo_url

  depends_on = [
    module.gke,
    module.artifact_registry,
    module.dataproc,
    module.gcs,
    null_resource.compile_mapreduce_jar
  ]
}
