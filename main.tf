# ------------------------------------------
# INTERNAL HTTPS APPLICATION LOAD BALANCERS
# ------------------------------------------

module "internal_albs" {
  source   = "./modules/internal-https-alb"
  for_each = var.internal_albs

  config = merge(each.value, {
    gcp_project_id                     = var.gcp_project_id
    region                             = var.region
    alb_frontend_certificate_pem       = var.alb_frontend_certificate_pem
    alb_frontend_private_key_pem       = var.alb_frontend_private_key_pem
    alb_backend_client_certificate_pem = var.alb_backend_client_certificate_pem
    alb_backend_client_private_key_pem = var.alb_backend_client_private_key_pem
    alb_frontend_client_ca_pem         = var.alb_frontend_client_ca_pem
  })

  depends_on = [module.cloud_run]
}

# ------------------------------------------
# CLOUD RUN SERVICES
# ------------------------------------------

module "cloud_run" {
  source   = "./modules/cloud-run"
  for_each = var.cloud_run_services

  name           = each.key
  project_id     = var.gcp_project_id
  region         = var.region
  image          = each.value.image
  container_port = each.value.container_port
}


# Global External HTTPS Application Load Balancers
module "global_external_albs" {
  source   = "./modules/global-external-https-alb"
  for_each = var.global_external_albs

  config = merge(each.value, {
    gcp_project_id               = var.gcp_project_id
    region                       = var.region
    alb_frontend_certificate_pem = var.alb_frontend_certificate_pem
    alb_frontend_private_key_pem = var.alb_frontend_private_key_pem
    alb_frontend_client_ca_pem   = var.alb_frontend_client_ca_pem
  })
}
