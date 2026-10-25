variable "gcp_project_id" {
  description = "GCP project ID where resources will be deployed"
  type        = string
}

variable "region" {
  description = "GCP region for the Regional Internal Application Load Balancer"
  type        = string
  default     = "northamerica-northeast1"
}

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

variable "alb_frontend_client_ca_pem" {
  description = "Trusted CA certificate for frontend mTLS client authentication"
  type        = string
  sensitive   = true
}

variable "internal_albs" {
  description = "Named independent internal HTTPS ALB configurations; each value contains the existing ALB map inputs."
  type        = map(any)
}
