
# --------------------------------------------------
# ZONAL NETWORK ENDPOINT GROUPS
# Regional Internal Application Load Balancer
# --------------------------------------------------

resource "google_compute_network_endpoint_group" "alb_zonal_negs" {

  for_each = var.alb_zonal_negs

  name                  = each.key
  zone                  = each.value.zone
  network               = each.value.network
  subnetwork            = each.value.subnetwork
  network_endpoint_type = "GCE_VM_IP_PORT"

  default_port = each.value.default_port
}

# --------------------------------------------------
# NEG NETWORK ENDPOINTS
# Register VM IP addresses and ports into the NEGs
# --------------------------------------------------

resource "google_compute_network_endpoint" "alb_endpoints" {

  for_each = {
    for endpoint in flatten([
      for neg_name, neg in var.alb_zonal_negs : [
        for index, ep in neg.network_endpoints : {
          key        = "${neg_name}-${index}"
          neg_name   = neg_name
          zone       = neg.zone
          instance   = ep.instance
          ip_address = ep.ip_address
          port       = ep.port
        }
      ]
    ]) : endpoint.key => endpoint
  }

  network_endpoint_group = google_compute_network_endpoint_group.alb_zonal_negs[each.value.neg_name].name

  zone       = each.value.zone
  instance   = each.value.instance
  ip_address = each.value.ip_address
  port       = each.value.port
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB HEALTH CHECKS
# --------------------------------------------------

resource "google_compute_region_health_check" "alb_health_checks" {

  for_each = var.alb_health_checks

  name   = each.key
  region = var.region

  check_interval_sec  = each.value.check_interval_sec
  timeout_sec         = each.value.timeout_sec
  healthy_threshold   = each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold

  tcp_health_check {
    port = each.value.port
  }
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB BACKEND SERVICES
# --------------------------------------------------

resource "google_compute_region_backend_service" "alb_backend_services" {

  for_each = var.alb_backend_services

  name                  = each.key
  region                = var.region
  protocol              = each.value.protocol
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = each.value.timeout_sec

  health_checks = [
    google_compute_region_health_check.alb_health_checks[
      each.value.health_check_key
    ].id
  ]
  dynamic "backend" {
    for_each = each.value.zonal_neg_keys

    content {
      group = google_compute_network_endpoint_group.alb_zonal_negs[
        backend.value
      ].id

      balancing_mode  = "RATE"
      max_rate        = 100
      capacity_scaler = 1.0
    }
  }
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB URL MAPS
# --------------------------------------------------

resource "google_compute_region_url_map" "alb_url_maps" {

  for_each = var.alb_url_maps

  name   = each.key
  region = var.region

  default_service = google_compute_region_backend_service.alb_backend_services[
    each.value.default_backend_service_key
  ].id
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB FRONTEND SSL CERTIFICATE
# --------------------------------------------------

resource "google_compute_region_ssl_certificate" "alb_frontend_certificate" {

  name   = "cert-nane1-lab-internal-alb-01"
  region = var.region

  certificate = var.alb_frontend_certificate_pem
  private_key = var.alb_frontend_private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}