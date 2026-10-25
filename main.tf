# Each entry is an independent ALB module instance.
# Keep certificate secrets in Terraform Cloud sensitive variables, not tfvars.
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
}
