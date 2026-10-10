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