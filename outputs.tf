output "mule_frontend_ip_addresses" {
  value = try(module.internal_albs["mule"].frontend_ip_addresses, {})
}

output "mule_backend_service_ids" {
  value = try(module.internal_albs["mule"].backend_service_ids, {})
}

output "internal_alb_frontend_ips" {
  value = {
    for name, alb in module.internal_albs :
    name => alb.frontend_ip_addresses
  }
}