resource "google_cloud_run_v2_service" "service" {
  project             = var.project_id
  name                = var.name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  deletion_protection = false # Lab only; change to true for production.

  template {
    containers {
      image = var.image
      ports {
        container_port = var.container_port
      }
    }
  }
}

# Lab access model: network ingress is restricted, but Cloud Run IAM is not.
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
