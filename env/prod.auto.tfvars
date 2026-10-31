
# PROD Global External HTTPS ALB

# Do not deploy LAB internal ALBs in PROD
internal_albs = {}

# Reuse existing LAB Cloud Run service
# Do not create another Cloud Run service in PROD
cloud_run_services = {}

global_external_albs = {
  prod = {
    name              = "glb-prod-global-alb"
    domain_name       = "glb-prd.igmfinancial.net"
    cloud_run_service = "mule-dev-cloudrun"
  }
}
