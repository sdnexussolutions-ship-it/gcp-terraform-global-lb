# Migrate existing root resource addresses to module addresses.
# Keep these moved blocks through the first successful migration apply.
# Review the plan before apply: MULE resources should MOVE, not be destroyed/recreated.

moved {
  from = google_compute_network_endpoint_group.alb_zonal_negs
  to   = module.mule_internal_alb.google_compute_network_endpoint_group.alb_zonal_negs
}

moved {
  from = google_compute_network_endpoint.alb_endpoints
  to   = module.mule_internal_alb.google_compute_network_endpoint.alb_endpoints
}

moved {
  from = google_compute_region_health_check.alb_health_checks
  to   = module.mule_internal_alb.google_compute_region_health_check.alb_health_checks
}

moved {
  from = google_compute_region_backend_service.alb_backend_services
  to   = module.mule_internal_alb.google_compute_region_backend_service.alb_backend_services
}

moved {
  from = google_compute_region_url_map.alb_url_maps
  to   = module.mule_internal_alb.google_compute_region_url_map.alb_url_maps
}

moved {
  from = google_compute_region_ssl_certificate.mule_sbx_alb_01_frontend_certificate
  to   = module.mule_internal_alb.google_compute_region_ssl_certificate.mule_sbx_alb_01_frontend_certificate
}

moved {
  from = google_compute_region_target_https_proxy.alb_target_https_proxies
  to   = module.mule_internal_alb.google_compute_region_target_https_proxy.alb_target_https_proxies
}

moved {
  from = google_compute_address.alb_frontend_ips
  to   = module.mule_internal_alb.google_compute_address.alb_frontend_ips
}

moved {
  from = google_compute_forwarding_rule.alb_forwarding_rules
  to   = module.mule_internal_alb.google_compute_forwarding_rule.alb_forwarding_rules
}

moved {
  from = google_certificate_manager_certificate.mule-sbx_alb_01_backend_client_cert
  to   = module.mule_internal_alb.google_certificate_manager_certificate.mule-sbx_alb_01_backend_client_cert
}

moved {
  from = google_network_security_backend_authentication_config.mule-sbx_alb_01_backend_auth
  to   = module.mule_internal_alb.google_network_security_backend_authentication_config.mule-sbx_alb_01_backend_auth
}

moved {
  from = google_certificate_manager_trust_config.mule-sbx_alb_01_frontend_trust
  to   = module.mule_internal_alb.google_certificate_manager_trust_config.mule-sbx_alb_01_frontend_trust
}

moved {
  from = google_network_security_server_tls_policy.mule-sbx_alb_01_frontend_mtls
  to   = module.mule_internal_alb.google_network_security_server_tls_policy.mule-sbx_alb_01_frontend_mtls
}
