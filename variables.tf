variable "gcp_project_id" {
  description = "GCP project ID where resources will be deployed"
  type        = string
}

variable "region" {
  description = "GCP region for the Regional Internal Application Load Balancer"
  type        = string
  default     = "northamerica-northeast1"
}

variable "alb_zonal_negs" {
  description = "Zonal Network Endpoint Groups and their VM endpoints"

  type = map(object({
    zone         = string
    network      = string
    subnetwork   = string
    default_port = number

    network_endpoints = list(object({
      instance   = string
      ip_address = string
      port       = number
    }))
  }))

  default = {}
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB HEALTH CHECKS
# --------------------------------------------------

variable "alb_health_checks" {
  description = "Regional health checks for the Internal Application Load Balancer"

  type = map(object({
    protocol            = string
    port                = number
    check_interval_sec  = number
    timeout_sec         = number
    healthy_threshold   = number
    unhealthy_threshold = number
  }))

  default = {}
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB BACKEND SERVICES
# --------------------------------------------------

variable "alb_backend_services" {
  description = "Regional backend services for the Internal Application Load Balancer"

  type = map(object({
    protocol         = string
    timeout_sec      = number
    health_check_key = string
    zonal_neg_keys   = list(string)
  }))

  default = {}
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB URL MAPS
# --------------------------------------------------

variable "alb_url_maps" {
  description = "Regional URL maps for the Internal Application Load Balancer"

  type = map(object({
    default_backend_service_key = string
  }))

  default = {}
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB TARGET HTTPS PROXIES
# --------------------------------------------------

variable "alb_target_https_proxies" {
  description = "Regional target HTTPS proxies for the Internal Application Load Balancer"

  type = map(object({
    url_map_key = string
  }))

  default = {}
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB FRONTEND TLS CERTIFICATE
# --------------------------------------------------

variable "alb_frontend_certificate_pem" {
  description = "PEM-encoded frontend server certificate and chain"
  type        = string
  sensitive   = true
  default     = null
}

variable "alb_frontend_private_key_pem" {
  description = "PEM-encoded frontend server private key"
  type        = string
  sensitive   = true
  default     = null
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB FRONTEND IP ADDRESSES
# --------------------------------------------------

variable "alb_frontend_ips" {
  description = "Regional internal IP reservations for Application Load Balancer frontends"

  type = map(object({
    address_type = string
    subnetwork   = string
  }))
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB FORWARDING RULES
# --------------------------------------------------

variable "alb_forwarding_rules" {
  description = "Regional internal ALB frontend forwarding rules"

  type = map(object({
    network         = string
    subnetwork      = string
    ip_address_key  = string
    https_proxy_key = string
    port            = number
  }))
}
# --------------------------------------------------
# BACKEND MTLS CERTIFICATE MATERIAL
# --------------------------------------------------

variable "alb_backend_client_certificate_pem" {
  description = "PEM certificate presented by the ALB to the backend"
  type        = string
  sensitive   = true
}

variable "alb_backend_client_private_key_pem" {
  description = "Private key for the ALB backend client certificate"
  type        = string
  sensitive   = true
}