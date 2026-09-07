resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "global-lb-cloud-run-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.app.name
  }

  depends_on = [
    google_cloud_run_v2_service.app
  ]
}

resource "google_compute_backend_service" "cloud_run_backend" {
  name                  = "global-lb-cloud-run-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg.id
  }

  depends_on = [
    google_compute_region_network_endpoint_group.cloud_run_neg
  ]
}

resource "google_compute_url_map" "app" {
  name = "global-lb-url-map"

  default_service = google_compute_backend_service.cloud_run_backend.id

  depends_on = [
    google_compute_backend_service.cloud_run_backend
  ]
}

resource "google_compute_target_http_proxy" "app" {
  name    = "global-lb-http-proxy"
  url_map = google_compute_url_map.app.id

  depends_on = [
    google_compute_url_map.app
  ]
}

resource "google_compute_global_address" "app" {
  name = "global-lb-ip"
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "global-lb-http-forwarding-rule"
  target                = google_compute_target_http_proxy.app.id
  port_range            = "80"
  ip_address            = google_compute_global_address.app.address
  load_balancing_scheme = "EXTERNAL_MANAGED"

  depends_on = [
    google_compute_target_http_proxy.app,
    google_compute_global_address.app
  ]
}