variable "namespace" {
  type = string
}

variable "jenkins_image" {
  type = string
}

variable "sonarqube_image" {
  type = string
}

variable "project_id" {
  type = string
}

variable "dataproc_cluster_name" {
  type = string
}

variable "dataproc_region" {
  type = string
}

variable "gcs_bucket" {
  type = string
}

variable "github_repo_url" {
  type = string
}

resource "kubernetes_namespace" "ci" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_persistent_volume_claim" "jenkins_home" {
  metadata {
    name = "jenkins-home"
    namespace = kubernetes_namespace.ci.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }

  timeouts {
    create = "10m"
  }

  wait_until_bound = false
}

resource "kubernetes_config_map" "jenkins_config" {
  metadata {
    name = "jenkins-config"
    namespace = kubernetes_namespace.ci.metadata[0].name
  }

  data = {
    "jenkins.yaml" = yamlencode({
      jenkins = {
        systemMessage = "Jenkins configured automatically via Terraform"
        numExecutors = 2
        scmCheckoutRetryCount = 2
      }
      unclassified = {
        location = {
          url = "http://jenkins.ci.svc.cluster.local:8080/"
        }
      }
    })

    "init-script.groovy" = <<-EOT
      import jenkins.model.Jenkins
      import hudson.model.FreeStyleProject
      import hudson.plugins.git.GitSCM
      import hudson.tasks.Shell

      println "Jenkins initialization script running..."

      def jenkins = Jenkins.instance

      println "Jenkins initialization complete!"
    EOT
  }
}

resource "kubernetes_deployment" "jenkins" {
  metadata {
    name = "jenkins"
    namespace = kubernetes_namespace.ci.metadata[0].name
    labels = {
      app = "jenkins"
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
  }

  wait_for_rollout = false

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "jenkins"
      }
    }

    template {
      metadata {
        labels = {
          app = "jenkins"
        }
      }

      spec {
        security_context {
          fs_group = 1000
        }

        container {
          name = "jenkins"
          image = var.jenkins_image

          port {
            container_port = 8080
            name = "http"
          }

          port {
            container_port = 50000
            name = "agent"
          }

          volume_mount {
            name = "jenkins-home"
            mount_path = "/var/jenkins_home"
          }

          volume_mount {
            name = "jenkins-config"
            mount_path = "/var/jenkins_home/casc_configs"
          }

          env {
            name = "JAVA_OPTS"
            value = "-Djenkins.install.runSetupWizard=false"
          }

          env {
            name = "CASC_JENKINS_CONFIG"
            value = "/var/jenkins_home/casc_configs/jenkins.yaml"
          }

          env {
            name = "GCP_PROJECT_ID"
            value = var.project_id
          }

          env {
            name = "DATAPROC_CLUSTER"
            value = var.dataproc_cluster_name
          }

          env {
            name = "DATAPROC_REGION"
            value = var.dataproc_region
          }
 
          env {
            name = "GCS_BUCKET"
            value = var.gcs_bucket
          }

          resources {
            requests = {
              cpu = "500m"
              memory = "1Gi"
            }
            limits = {
              cpu = "1"
              memory = "2Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/login"
              port = 8080
            }
            initial_delay_seconds = 90
            period_seconds = 10
            timeout_seconds = 5
            failure_threshold = 5
          }

          readiness_probe {
            http_get {
              path = "/login"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds = 10
            timeout_seconds = 5
            failure_threshold = 3
          }
        }

        volume {
          name = "jenkins-home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jenkins_home.metadata[0].name
          }
        }

        volume {
          name = "jenkins-config"
          config_map {
            name = kubernetes_config_map.jenkins_config.metadata[0].name
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "jenkins" {
  metadata {
    name = "jenkins"
    namespace = kubernetes_namespace.ci.metadata[0].name
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "jenkins"
    }

    port {
      name = "http"
      port = 8080
      target_port = 8080
    }

    port {
      name = "agent"
      port = 50000
      target_port = 50000
    }
  }
}


resource "kubernetes_deployment" "sonarqube" {
  metadata {
    name = "sonarqube"
    namespace = kubernetes_namespace.ci.metadata[0].name
    labels = {
      app = "sonarqube"
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
  }

  wait_for_rollout = false

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "sonarqube"
      }
    }

    template {
      metadata {
        labels = {
          app = "sonarqube"
        }
      }

      spec {
        container {
          name = "sonarqube"
          image = var.sonarqube_image

          port {
            container_port = 9000
          }

          env {
            name = "SONAR_ES_BOOTSTRAP_CHECKS_DISABLE"
            value = "true"
          }

          resources {
            requests = {
              cpu = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu = "1"
              memory = "4Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/api/system/status"
              port = 9000
            }
            initial_delay_seconds = 180
            period_seconds = 30
            timeout_seconds = 10
            failure_threshold = 5
          }

          readiness_probe {
            http_get {
              path = "/api/system/status"
              port = 9000
            }
            initial_delay_seconds = 120
            period_seconds = 30
            timeout_seconds = 10
            failure_threshold = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "sonarqube" {
  metadata {
    name = "sonarqube"
    namespace = kubernetes_namespace.ci.metadata[0].name
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "sonarqube"
    }

    port {
      port = 9000
      target_port = 9000
    }
  }
}


resource "time_sleep" "wait_for_lb" {
  depends_on = [
    kubernetes_service.jenkins,
    kubernetes_service.sonarqube
  ]

  create_duration = "60s"
}

data "kubernetes_service" "jenkins" {
  metadata {
    name = kubernetes_service.jenkins.metadata[0].name
    namespace = kubernetes_namespace.ci.metadata[0].name
  }

  depends_on = [time_sleep.wait_for_lb]
}

data "kubernetes_service" "sonarqube" {
  metadata {
    name = kubernetes_service.sonarqube.metadata[0].name
    namespace = kubernetes_namespace.ci.metadata[0].name
  }

  depends_on = [time_sleep.wait_for_lb]
}

output "jenkins_url" {
  value = length(data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress) > 0 ? (
    "http://${data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].ip}:8080"
  ) : "Pending - check kubectl get svc -n ci"
}

output "sonarqube_url" {
  description = "SonarQube external URL"
  value = length(data.kubernetes_service.sonarqube.status[0].load_balancer[0].ingress) > 0 ? (
    "http://${data.kubernetes_service.sonarqube.status[0].load_balancer[0].ingress[0].ip}:9000"
  ) : "Pending - check kubectl get svc -n ci"
}

output "jenkins_internal_url" {
  description = "Jenkins internal cluster URL"
  value = "http://jenkins.${var.namespace}.svc.cluster.local:8080"
}

output "sonarqube_internal_url" {
  description = "SonarQube internal cluster URL"
  value = "http://sonarqube.${var.namespace}.svc.cluster.local:9000"
}

resource "kubernetes_secret" "sonarqube_admin" {
  metadata {
    name = "sonarqube-admin"
    namespace = kubernetes_namespace.ci.metadata[0].name
  }

  data = {
    old-password = "admin"
    new-password = "Sonaqube123!"
  }

  type = "Opaque"
}

resource "kubernetes_job" "sonarqube_change_password" {
  metadata {
    name = "sonarqube-change-password"
    namespace = kubernetes_namespace.ci.metadata[0].name
  }

  wait_for_completion = false

  depends_on = [
    kubernetes_deployment.sonarqube,
    kubernetes_service.sonarqube,
    kubernetes_secret.sonarqube_admin
  ]

  spec {
    backoff_limit = 5

    template {
      metadata {
        labels = {
          app = "sonarqube-setup"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name = "password-changer"
          image = "curlimages/curl:latest"

          command = ["/bin/sh", "-c"]

          args = [<<-EOT
            set -e
            echo "Waiting for SonarQube to be ready..."

            for i in $(seq 1 60); do
              if curl -s -f http://sonarqube.ci.svc.cluster.local:9000/api/system/status > /dev/null 2>&1; then
                echo "SonarQube is ready!"
                break
              fi
              echo "Waiting... ($i/60)"
              sleep 5
            done

            sleep 10

            OLD_PASSWORD="$OLD_PASS"
            NEW_PASSWORD="$NEW_PASS"
            BASE_URL="http://sonarqube.ci.svc.cluster.local:9000/api"

            echo "=== Changing SonarQube Admin Password ==="

            response=$(curl -s -w "%%{http_code}" -o /tmp/change_pwd.txt \
              -u "admin:$OLD_PASSWORD" \
              -X POST \
              "$BASE_URL/users/change_password?login=admin&previousPassword=$OLD_PASSWORD&password=$NEW_PASSWORD")

            echo "Password change response: $response"

            if echo "$response" | grep -q "204"; then
              echo "Password changed successfully to: $NEW_PASSWORD"
            elif echo "$response" | grep -q "400"; then
              if grep -q "password" /tmp/change_pwd.txt 2>/dev/null; then
                echo "Password may have already been changed, testing new password..."
                test_response=$(curl -s -w "%%{http_code}" -o /dev/null \
                  -u "admin:$NEW_PASSWORD" \
                  "$BASE_URL/system/status")

                if echo "$test_response" | grep -q "200"; then
                  echo "New password already in use and working"
                else
                  echo "Password change failed"
                  cat /tmp/change_pwd.txt
                  exit 1
                fi
              fi
            else
              echo "Unexpected response"
              cat /tmp/change_pwd.txt
              exit 1
            fi

            echo "Password change process completed successfully!"
          EOT
          ]

          env {
            name = "OLD_PASS"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.sonarqube_admin.metadata[0].name
                key = "old-password"
              }
            }
          }

          env {
            name = "NEW_PASS"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.sonarqube_admin.metadata[0].name
                key = "new-password"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_job" "sonarqube_configure_project" {
  metadata {
    name = "sonarqube-configure-project"
    namespace = kubernetes_namespace.ci.metadata[0].name
  }

  wait_for_completion = false

  depends_on = [
    kubernetes_job.sonarqube_change_password
  ]

  spec {
    backoff_limit = 5

    template {
      metadata {
        labels = {
          app = "sonarqube-config"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name = "configurator"
          image = "curlimages/curl:latest"

          command = ["/bin/sh", "-c"]

          args = [<<-EOT
            set -e
            echo "Waiting for SonarQube to be ready..."

            for i in $(seq 1 60); do
              if curl -s -f http://sonarqube.ci.svc.cluster.local:9000/api/system/status > /dev/null 2>&1; then
                echo "SonarQube is ready!"
                break
              fi
              echo "Waiting... ($i/60)"
              sleep 5
            done

            echo "Waiting for password change to take effect..."
            sleep 15

            NEW_PASSWORD="$NEW_PASS"
            AUTH="admin:$NEW_PASSWORD"
            BASE_URL="http://sonarqube.ci.svc.cluster.local:9000/api"

            echo "=== Step 1: Create Project ==="
            project_response=$(curl -s -w "%%{http_code}" -o /tmp/project.txt \
              -u "$AUTH" \
              -X POST \
              "$BASE_URL/projects/create?name=Project+1&project=project-1")
            
            echo "Project creation response: $project_response"
            if echo "$project_response" | grep -q "200"; then
              echo "Project created successfully"
            elif grep -q "already exists" /tmp/project.txt 2>/dev/null; then
              echo "Project already exists"
            else
              cat /tmp/project.txt
            fi
            
            echo ""
            echo "=== Step 2: Generate PROJECT_ANALYSIS_TOKEN ==="
            token_response=$(curl -s -w "%%{http_code}" -o /tmp/token.txt \
              -u "$AUTH" \
              -X POST \
              "$BASE_URL/user_tokens/generate?name=jenkins-token&type=PROJECT_ANALYSIS_TOKEN&projectKey=project-1")
            
            echo "Token generation response: $token_response"
            if echo "$token_response" | grep -q "200"; then
              TOKEN=$(cat /tmp/token.txt | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
              echo "PROJECT_ANALYSIS_TOKEN generated: $TOKEN"
              echo "$TOKEN" > /tmp/jenkins-sonar-token.txt
            elif grep -q "already exists" /tmp/token.txt 2>/dev/null; then
              echo "Token already exists (this is OK, but you'll need to use existing token)"
              echo "no-token-retrievable" > /tmp/jenkins-sonar-token.txt
            else
              echo "Token generation failed"
              cat /tmp/token.txt
            fi

            echo ""
            echo "=== Step 3: Create Webhook ==="
            JENKINS_URL="http://jenkins.ci.svc.cluster.local:8080"

            webhook_response=$(curl -s -w "%%{http_code}" -o /tmp/webhook.txt \
              -u "$AUTH" \
              -X POST \
              "$BASE_URL/webhooks/create?name=jenkins-webhook&project=project-1&url=$${JENKINS_URL}/sonarqube-webhook/")

            echo "Webhook creation response: $webhook_response"
            if echo "$webhook_response" | grep -q "200"; then
              echo "Webhook created successfully"
            elif grep -q "already exists" /tmp/webhook.txt 2>/dev/null; then
              echo "Webhook already exists"
            else
              cat /tmp/webhook.txt
            fi

            echo ""
            echo "=== Configuration Summary ==="
            echo "Token Type: PROJECT_ANALYSIS_TOKEN (using user_tokens API)"
            echo "Token Name: jenkins-token"
            echo "Webhook: -> Jenkins"
            echo ""
            echo "Automation complete! Token saved to job logs."
          EOT
          ]

          env {
            name = "NEW_PASS"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.sonarqube_admin.metadata[0].name
                key = "new-password"
              }
            }
          }
        }
      }
    }
  }
}

output "namespace" {
  value = kubernetes_namespace.ci.metadata[0].name
}
