
output "global_ip_address" {
  description = "Public IP address of the global external HTTPS ALB"
  value       = google_compute_global_address.frontend.address
}

output "https_proxy_id" {
  description = "Global target HTTPS proxy ID"
  value       = google_compute_target_https_proxy.frontend.id
}

output "backend_service_id" {
  description = "Global backend service ID"
  value       = google_compute_backend_service.cloud_run.id
}

output "serverless_neg_id" {
  description = "PROD serverless NEG ID"
  value       = google_compute_region_network_endpoint_group.cloud_run.id
}

output "https_url" {
  description = "HTTPS URL for testing"
  value       = "https://${var.config.domain_name}"
}
