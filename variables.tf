variable "gcp_project_id" {
  description = "GCP project ID where resources will be deployed"
  type        = string
}
variable "region" {
  description = "GCP region for regional resources"
  type        = string
  default     = "us-central1"
}