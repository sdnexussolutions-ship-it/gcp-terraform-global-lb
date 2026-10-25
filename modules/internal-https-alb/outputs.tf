output "frontend_ip_addresses" {
  description = "Reserved frontend IPs by Terraform map key"
  value       = { for key, address in google_compute_address.alb_frontend_ips : key => address.address }
}

output "url_map_ids" {
  description = "URL map IDs by Terraform map key"
  value       = { for key, url_map in google_compute_region_url_map.alb_url_maps : key => url_map.id }
}

output "backend_service_ids" {
  description = "Backend service IDs by Terraform map key"
  value       = { for key, service in google_compute_region_backend_service.alb_backend_services : key => service.id }
}
