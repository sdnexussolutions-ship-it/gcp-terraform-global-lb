resource "google_cloud_run_v2_service" "app" {
  name     = "global-lb-app"
  location = var.region

  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.app.repository_id}/global-lb-app:latest"

      ports {
        container_port = 8080
      }
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_artifact_registry_repository.app
  ]
}