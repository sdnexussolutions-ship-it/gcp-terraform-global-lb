resource "google_cloud_run_v2_service" "app" {
  name     = "global-lb-app"
  location = var.region
  deletion_protection = false

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

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.gcp_project_id
  location = var.region
  name     = google_cloud_run_v2_service.app.name

  role   = "roles/run.invoker"
  member = "allUsers"
}