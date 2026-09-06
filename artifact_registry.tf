resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = "global-lb-app"
  description   = "Docker repository for the Cloud Run application"
  format        = "DOCKER"

  depends_on = [
    google_project_service.required_apis
  ]
}