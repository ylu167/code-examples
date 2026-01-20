variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "bucket_suffix" {
  type = string
}

resource "google_storage_bucket" "hadoop_bucket" {
  project = var.project_id
  name = "${var.project_id}-hadoop-data-${var.bucket_suffix}"
  location = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_object" "input_folder" {
  name = "input/.keep"
  content = "input"
  bucket = google_storage_bucket.hadoop_bucket.name
}

resource "google_storage_bucket_object" "output_folder" {
  name = "output/.keep"
  content = "output"
  bucket = google_storage_bucket.hadoop_bucket.name
}

resource "google_storage_bucket_object" "jars_folder" {
  name = "jars/.keep"
  content = "jars"
  bucket = google_storage_bucket.hadoop_bucket.name
}

resource "google_storage_bucket_object" "temp_folder" {
  name = "temp/.keep"
  content = "temp"
  bucket = google_storage_bucket.hadoop_bucket.name
}

output "bucket_name" {
  value = google_storage_bucket.hadoop_bucket.name
}

output "bucket_url" {
  value = google_storage_bucket.hadoop_bucket.url
}
