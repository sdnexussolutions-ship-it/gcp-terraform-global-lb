# Read information about our existing GCP project
data "google_project" "current" {
  project_id = var.gcp_project_id
}
locals {
  backend_auth_ids = {
    production      = google_network_security_backend_authentication_config.alb_backend_auth.id
    learning-alb-01 = google_network_security_backend_authentication_config.learning_alb_01_backend_auth.id
    learning-alb-02 = google_network_security_backend_authentication_config.learning_alb_02_backend_auth.id
  }
}


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
resource "google_compute_region_ssl_certificate" "learning_alb_02_frontend_certificate" {
  name        = "cert-nane1-learning-alb-02"
  region      = var.region
  certificate = var.alb_frontend_certificate_pem
  private_key = var.alb_frontend_private_key_pem
  lifecycle { create_before_destroy = true }
}

# --------------------------------------------------
# LEARNING ALB 1 - FRONTEND SSL CERTIFICATE
# --------------------------------------------------

resource "google_compute_region_ssl_certificate" "learning_alb_01_frontend_certificate" {

  name   = "cert-nane1-learning-alb-01"
  region = var.region

  certificate = var.alb_frontend_certificate_pem
  private_key = var.alb_frontend_private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB TARGET HTTPS PROXIES
# --------------------------------------------------

resource "google_compute_region_target_https_proxy" "alb_target_https_proxies" {

  for_each = var.alb_target_https_proxies

  name   = each.key
  region = var.region

  url_map = google_compute_region_url_map.alb_url_maps[
    each.value.url_map_key
  ].id

  ssl_certificates = [
    {
      production      = google_compute_region_ssl_certificate.alb_frontend_certificate.id
      learning-alb-01 = google_compute_region_ssl_certificate.learning_alb_01_frontend_certificate.id
      learning-alb-02 = google_compute_region_ssl_certificate.learning_alb_02_frontend_certificate.id
    }[each.value.ssl_certificate_key]
  ]

  server_tls_policy = {
    production      = google_network_security_server_tls_policy.alb_frontend_mtls.id
    learning-alb-01 = google_network_security_server_tls_policy.learning_alb_01_frontend_mtls.id
    learning-alb-02 = google_network_security_server_tls_policy.learning_alb_02_frontend_mtls.id
  }[each.value.server_tls_policy_key]
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB FRONTEND IP RESERVATIONS
# --------------------------------------------------

resource "google_compute_address" "alb_frontend_ips" {

  for_each = var.alb_frontend_ips

  name         = each.key
  region       = var.region
  address_type = each.value.address_type
  subnetwork   = each.value.learning_vpc ? google_compute_subnetwork.learning_subnets[each.value.subnetwork].id : each.value.subnetwork

  purpose = "GCE_ENDPOINT"
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB FORWARDING RULES
# --------------------------------------------------

resource "google_compute_forwarding_rule" "alb_forwarding_rules" {
  for_each = var.alb_forwarding_rules

  name                  = each.key
  region                = var.region
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = each.value.learning_vpc ? google_compute_network.learning_vpcs[each.value.network].id : each.value.network

  subnetwork = each.value.learning_vpc ? google_compute_subnetwork.learning_subnets[each.value.subnetwork].id : each.value.subnetwork

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
# BACKEND MTLS - ALB CLIENT CERTIFICATE
# --------------------------------------------------

resource "google_certificate_manager_certificate" "alb_backend_client_cert" {

  name     = "cert-nane1-lab-alb-backend-client-01"
  location = var.region

  scope = "CLIENT_AUTH"

  self_managed {
    pem_certificate = var.alb_backend_client_certificate_pem
    pem_private_key = var.alb_backend_client_private_key_pem
  }
}

# --------------------------------------------------
# LEARNING ALB 1 - BACKEND MTLS CLIENT CERTIFICATE
# --------------------------------------------------

resource "google_certificate_manager_certificate" "learning_alb_01_backend_client_cert" {

  name     = "cert-nane1-learning-alb-backend-client-01"
  location = var.region

  scope = "CLIENT_AUTH"

  self_managed {
    pem_certificate = var.alb_backend_client_certificate_pem
    pem_private_key = var.alb_backend_client_private_key_pem
  }
}
# --------------------------------------------------
# BACKEND MTLS - AUTHENTICATION CONFIG
# --------------------------------------------------

resource "google_network_security_backend_authentication_config" "alb_backend_auth" {

  name     = "backend-auth-nane1-lab-internal-alb-01"
  location = var.region

  well_known_roots = "PUBLIC_ROOTS"

  client_certificate = google_certificate_manager_certificate.alb_backend_client_cert.id
}

# --------------------------------------------------
# LEARNING ALB 1 - BACKEND MTLS AUTHENTICATION CONFIG
# --------------------------------------------------

resource "google_network_security_backend_authentication_config" "learning_alb_01_backend_auth" {

  name     = "backend-auth-nane1-learning-alb-01"
  location = var.region

  well_known_roots = "PUBLIC_ROOTS"

  client_certificate = google_certificate_manager_certificate.learning_alb_01_backend_client_cert.id
}
# --------------------------------------------------
# FRONTEND MTLS - TRUST CONFIG
# --------------------------------------------------

resource "google_certificate_manager_trust_config" "alb_frontend_trust" {
  name     = "trust-nane1-lab-alb-frontend-01"
  location = var.region

  trust_stores {
    trust_anchors {
      pem_certificate = var.alb_frontend_client_ca_pem
    }
  }
}
# --------------------------------------------------
# LEARNING ALB 1 - FRONTEND MTLS TRUST CONFIG
# --------------------------------------------------

resource "google_certificate_manager_trust_config" "learning_alb_01_frontend_trust" {
  name     = "trust-nane1-learning-alb-frontend-01"
  location = var.region

  trust_stores {
    trust_anchors {
      pem_certificate = var.alb_frontend_client_ca_pem
    }
  }
}
# --------------------------------------------------
# FRONTEND MTLS - SERVER TLS POLICY
# --------------------------------------------------

resource "google_network_security_server_tls_policy" "alb_frontend_mtls" {
  name     = "tls-policy-nane1-lab-alb-frontend-01"
  location = var.region

  allow_open = false

  mtls_policy {
    client_validation_mode = "REJECT_INVALID"

    client_validation_trust_config = "projects/${data.google_project.current.number}/locations/${var.region}/trustConfigs/${google_certificate_manager_trust_config.alb_frontend_trust.name}"
  }
}
# --------------------------------------------------
# LEARNING ALB 1 - FRONTEND MTLS SERVER TLS POLICY
# --------------------------------------------------

resource "google_network_security_server_tls_policy" "learning_alb_01_frontend_mtls" {
  name     = "tls-policy-nane1-learning-alb-frontend-01"
  location = var.region

  allow_open = false

  mtls_policy {
    client_validation_mode = "REJECT_INVALID"

    client_validation_trust_config = "projects/${data.google_project.current.number}/locations/${var.region}/trustConfigs/${google_certificate_manager_trust_config.learning_alb_01_frontend_trust.name}"
  }
}

# Create multiple learning VPCs
resource "google_compute_network" "learning_vpcs" {
  for_each = var.learning_vpcs

  name                    = each.key
  auto_create_subnetworks = each.value.auto_create_subnetworks
}

resource "google_compute_subnetwork" "learning_subnets" {
  for_each = var.learning_subnets

  name          = each.key
  region        = each.value.region
  ip_cidr_range = each.value.ip_cidr_range
  network       = google_compute_network.learning_vpcs[each.value.vpc_name].id

  purpose = each.value.purpose
  role    = each.value.role
}

# --------------------------------------------------
# VPC PEERING - LEARNING VPC 1 TO DEFAULT VPC
# --------------------------------------------------

resource "google_compute_network_peering" "learning_vpc_01_to_default" {
  name = "peer-learning-vpc01-to-default"

  network = google_compute_network.learning_vpcs[
    "terraform-learning-vpc-01"
  ].self_link

  peer_network = "projects/${var.gcp_project_id}/global/networks/default"
}

# --------------------------------------------------
# VPC PEERING - DEFAULT VPC TO LEARNING VPC 1
# --------------------------------------------------

resource "google_compute_network_peering" "default_to_learning_vpc_01" {
  name = "peer-default-to-learning-vpc01"

  network = "projects/${var.gcp_project_id}/global/networks/default"

  peer_network = google_compute_network.learning_vpcs[
    "terraform-learning-vpc-01"
  ].self_link
}

resource "google_certificate_manager_certificate" "learning_alb_02_backend_client_cert" {
  name     = "cert-nane1-learning-alb-backend-client-02"
  location = var.region
  scope    = "CLIENT_AUTH"
  self_managed {
    pem_certificate = var.alb_backend_client_certificate_pem
    pem_private_key = var.alb_backend_client_private_key_pem
  }
}

resource "google_network_security_backend_authentication_config" "learning_alb_02_backend_auth" {
  name               = "backend-auth-nane1-learning-alb-02"
  location           = var.region
  well_known_roots   = "PUBLIC_ROOTS"
  client_certificate = google_certificate_manager_certificate.learning_alb_02_backend_client_cert.id
}
resource "google_certificate_manager_trust_config" "learning_alb_02_frontend_trust" {
  name     = "trust-nane1-learning-alb-frontend-02"
  location = var.region
  trust_stores {
    trust_anchors {
      pem_certificate = var.alb_frontend_client_ca_pem
    }
  }
}

resource "google_network_security_server_tls_policy" "learning_alb_02_frontend_mtls" {
  name       = "tls-policy-nane1-learning-alb-frontend-02"
  location   = var.region
  allow_open = false
  mtls_policy {
    client_validation_mode         = "REJECT_INVALID"
    client_validation_trust_config = "projects/${data.google_project.current.number}/locations/${var.region}/trustConfigs/${google_certificate_manager_trust_config.learning_alb_02_frontend_trust.name}"
  }
}



resource "google_compute_network_peering" "learning_vpc_02_to_default" {
  name         = "peer-learning-vpc02-to-default"
  network      = google_compute_network.learning_vpcs["terraform-learning-vpc-02"].self_link
  peer_network = "projects/${var.gcp_project_id}/global/networks/default"
}

resource "google_compute_network_peering" "default_to_learning_vpc_02" {
  name         = "peer-default-to-learning-vpc02"
  network      = "projects/${var.gcp_project_id}/global/networks/default"
  peer_network = google_compute_network.learning_vpcs["terraform-learning-vpc-02"].self_link
}
