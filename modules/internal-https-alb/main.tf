# Read information about our existing GCP project
data "google_project" "current" {
  project_id = var.config.gcp_project_id
}
locals {
  # Add new authentication mappings here when introducing additional ALBs.
  backend_auth_ids = {
    mule-sbx-alb-01 = google_network_security_backend_authentication_config.mule-sbx_alb_01_backend_auth.id
  }
}


# --------------------------------------------------
# ZONAL NETWORK ENDPOINT GROUPS
# Regional Internal Application Load Balancer
# --------------------------------------------------

resource "google_compute_network_endpoint_group" "alb_zonal_negs" {

  for_each = var.config.alb_zonal_negs

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
      for neg_name, neg in var.config.alb_zonal_negs : [
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

  for_each = var.config.alb_health_checks

  name   = each.key
  region = var.config.region

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

  for_each = var.config.alb_backend_services

  name                  = each.key
  region                = var.config.region
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

  # Backend TLS and mutual TLS authentication
  tls_settings {

    sni = "glb-prd.igmfinancial.net"

    subject_alt_names {
      dns_name = "glb-prd.igmfinancial.net"
    }

    authentication_config = "//networksecurity.googleapis.com/${local.backend_auth_ids[each.value.backend_auth_key]}"
  }
}

# --------------------------------------------------
# REGIONAL INTERNAL ALB URL MAPS
# --------------------------------------------------

resource "google_compute_region_url_map" "alb_url_maps" {

  for_each = var.config.alb_url_maps

  name   = each.key
  region = var.config.region

  default_service = google_compute_region_backend_service.alb_backend_services[
    each.value.default_backend_service_key
  ].id

  dynamic "host_rule" {
    for_each = length(each.value.path_rules) > 0 ? [1] : []

    content {
      hosts        = ["*"]
      path_matcher = "path-matcher-1"
    }
  }

  dynamic "path_matcher" {
    for_each = length(each.value.path_rules) > 0 ? [1] : []

    content {
      name = "path-matcher-1"

      default_service = google_compute_region_backend_service.alb_backend_services[
        each.value.default_backend_service_key
      ].id

      dynamic "path_rule" {
        for_each = each.value.path_rules

        content {
          paths = [path_rule.key]

          service = google_compute_region_backend_service.alb_backend_services[
            path_rule.value
          ].id
        }
      }
    }
  }
}


# --------------------------------------------------
# MULE SBX ALB 1 - FRONTEND SSL CERTIFICATE
# --------------------------------------------------

resource "google_compute_region_ssl_certificate" "mule_sbx_alb_01_frontend_certificate" {

  name   = "cert-nane1-mule-sbx-alb-01"
  region = var.config.region

  certificate = var.config.alb_frontend_certificate_pem
  private_key = var.config.alb_frontend_private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}


resource "google_compute_region_target_https_proxy" "alb_target_https_proxies" {

  for_each = var.config.alb_target_https_proxies

  name   = each.key
  region = var.config.region

  url_map = google_compute_region_url_map.alb_url_maps[
    each.value.url_map_key
  ].id



  # --------------------------------------------------
  # FRONTEND SSL CERTIFICATE MAPPING
  # Selects the HTTPS certificate for each ALB.
  # --------------------------------------------------

  ssl_certificates = [
    {
      mule-sbx-alb-01 = google_compute_region_ssl_certificate.mule_sbx_alb_01_frontend_certificate.id
    }[each.value.ssl_certificate_key]
  ]

  # --------------------------------------------------
  # FRONTEND mTLS SERVER TLS POLICY MAPPING
  # Selects the client authentication policy for each ALB.
  # --------------------------------------------------

  server_tls_policy = {
    mule-sbx-alb-01 = google_network_security_server_tls_policy.mule-sbx_alb_01_frontend_mtls.id
  }[each.value.server_tls_policy_key]
}

# --------------------------------------------------
# REGIONAL INTERNAL ALB FRONTEND IP RESERVATIONS
# --------------------------------------------------

resource "google_compute_address" "alb_frontend_ips" {

  for_each = var.config.alb_frontend_ips

  name         = each.key
  region       = var.config.region
  address_type = each.value.address_type
  subnetwork   = each.value.subnetwork

  purpose = "GCE_ENDPOINT"
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB FORWARDING RULES
# --------------------------------------------------

resource "google_compute_forwarding_rule" "alb_forwarding_rules" {
  for_each = var.config.alb_forwarding_rules

  name                  = each.key
  region                = var.config.region
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = each.value.network

  subnetwork = each.value.subnetwork

  ip_address = google_compute_address.alb_frontend_ips[
    each.value.ip_address_key
  ].address

  target = google_compute_region_target_https_proxy.alb_target_https_proxies[
    each.value.https_proxy_key
  ].id

  ip_protocol = "TCP"
  port_range  = tostring(each.value.port)
}



# --------------------------------------------------
# MULE SBX ALB 1 - BACKEND MTLS CLIENT CERTIFICATE
# --------------------------------------------------

resource "google_certificate_manager_certificate" "mule-sbx_alb_01_backend_client_cert" {

  name     = "cert-nane1-mule-sbx-alb-backend-client-01"
  location = var.config.region

  scope = "CLIENT_AUTH"

  self_managed {
    pem_certificate = var.config.alb_backend_client_certificate_pem
    pem_private_key = var.config.alb_backend_client_private_key_pem
  }
}




# --------------------------------------------------
# MULE-SBX ALB 1 - BACKEND MTLS AUTHENTICATION CONFIG
# --------------------------------------------------

resource "google_network_security_backend_authentication_config" "mule-sbx_alb_01_backend_auth" {

  name     = "backend-auth-nane1-mule-sbx-alb-01"
  location = var.config.region

  well_known_roots = "PUBLIC_ROOTS"

  client_certificate = google_certificate_manager_certificate.mule-sbx_alb_01_backend_client_cert.id
}


# --------------------------------------------------
# MULE SBX ALB 1 - FRONTEND MTLS TRUST CONFIG
# --------------------------------------------------

resource "google_certificate_manager_trust_config" "mule-sbx_alb_01_frontend_trust" {
  name     = "trust-nane1-mule-alb-frontend-01"
  location = var.config.region

  trust_stores {
    trust_anchors {
      pem_certificate = var.config.alb_frontend_client_ca_pem
    }
  }
}


# --------------------------------------------------
# MULE SBX ALB 1 - FRONTEND MTLS SERVER TLS POLICY
# --------------------------------------------------

resource "google_network_security_server_tls_policy" "mule-sbx_alb_01_frontend_mtls" {
  name     = "tls-policy-nane1-mule-sbx-alb-frontend-01"
  location = var.config.region

  allow_open = false

  mtls_policy {
    client_validation_mode = "REJECT_INVALID"

    client_validation_trust_config = "projects/${data.google_project.current.number}/locations/${var.config.region}/trustConfigs/${google_certificate_manager_trust_config.mule-sbx_alb_01_frontend_trust.name}"
  }
}





