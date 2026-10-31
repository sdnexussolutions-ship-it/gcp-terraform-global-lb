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

# Global External HTTPS ALB outputs
output "global_external_albs" {
  description = "Outputs for global external HTTPS ALBs"

  value = {
    for key, alb in module.global_external_albs :
    key => {
      global_ip_address = alb.global_ip_address
      https_url         = alb.https_url
      backend_service   = alb.backend_service_id
      serverless_neg    = alb.serverless_neg_id
    }
  }
}
