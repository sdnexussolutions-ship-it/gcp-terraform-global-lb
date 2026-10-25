output "mule_frontend_ip_addresses" {
  value = module.mule_internal_alb.frontend_ip_addresses
}

output "mule_backend_service_ids" {
  value = module.mule_internal_alb.backend_service_ids
}
