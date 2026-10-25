# Root module: orchestration only. All ALB resources live in the reusable child module.
module "mule_internal_alb" {
  source = "./modules/internal-https-alb"

  gcp_project_id                     = var.gcp_project_id
  region                             = var.region
  alb_zonal_negs                     = var.alb_zonal_negs
  alb_health_checks                  = var.alb_health_checks
  alb_backend_services               = var.alb_backend_services
  alb_url_maps                       = var.alb_url_maps
  alb_target_https_proxies           = var.alb_target_https_proxies
  alb_frontend_certificate_pem       = var.alb_frontend_certificate_pem
  alb_frontend_private_key_pem       = var.alb_frontend_private_key_pem
  alb_frontend_ips                   = var.alb_frontend_ips
  alb_forwarding_rules               = var.alb_forwarding_rules
  alb_backend_client_certificate_pem = var.alb_backend_client_certificate_pem
  alb_backend_client_private_key_pem = var.alb_backend_client_private_key_pem
  alb_frontend_client_ca_pem         = var.alb_frontend_client_ca_pem
}
