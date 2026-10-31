
# Existing GCP project
data "google_project" "current" {
  project_id = var.config.gcp_project_id
}

# Public global static IP
resource "google_compute_global_address" "frontend" {
  project      = var.config.gcp_project_id
  name         = "${var.config.name}-ip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

# New PROD-owned serverless NEG pointing to existing Cloud Run
resource "google_compute_region_network_endpoint_group" "cloud_run" {
  project               = var.config.gcp_project_id
  name                  = "${var.config.name}-neg"
  region                = var.config.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.config.cloud_run_service
  }
}

# Global backend service
resource "google_compute_backend_service" "cloud_run" {
  project               = var.config.gcp_project_id
  name                  = "${var.config.name}-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run.id
  }
}

# URL map
resource "google_compute_url_map" "frontend" {
  project         = var.config.gcp_project_id
  name            = "${var.config.name}-urlmap"
  default_service = google_compute_backend_service.cloud_run.id
}

# HTTPS server certificate
resource "google_compute_ssl_certificate" "frontend" {
  project     = var.config.gcp_project_id
  name_prefix = "${var.config.name}-cert-"
  certificate = var.config.alb_frontend_certificate_pem
  private_key = var.config.alb_frontend_private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}

# Client CA trust configuration
resource "google_certificate_manager_trust_config" "frontend" {
  project  = var.config.gcp_project_id
  name     = "${var.config.name}-trust"
  location = "global"

  trust_stores {
    trust_anchors {
      pem_certificate = var.config.alb_frontend_client_ca_pem
    }
  }
}

# Enforce frontend mutual TLS
resource "google_network_security_server_tls_policy" "frontend" {
  project    = var.config.gcp_project_id
  name       = "${var.config.name}-mtls"
  location   = "global"
  allow_open = false

  mtls_policy {
    client_validation_mode = "REJECT_INVALID"

    client_validation_trust_config = (
      "projects/${data.google_project.current.number}/locations/global/trustConfigs/${google_certificate_manager_trust_config.frontend.name}"
    )
  }
}

# Global HTTPS target proxy
resource "google_compute_target_https_proxy" "frontend" {
  project = var.config.gcp_project_id
  name    = "${var.config.name}-https-proxy"

  url_map          = google_compute_url_map.frontend.id
  ssl_certificates = [google_compute_ssl_certificate.frontend.id]

  server_tls_policy = google_network_security_server_tls_policy.frontend.id
}

# Public HTTPS forwarding rule
resource "google_compute_global_forwarding_rule" "frontend" {
  project               = var.config.gcp_project_id
  name                  = "${var.config.name}-https-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
  port_range            = "443"

  ip_address = google_compute_global_address.frontend.address
  target     = google_compute_target_https_proxy.frontend.id
}
