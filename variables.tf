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