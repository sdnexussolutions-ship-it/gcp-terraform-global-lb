alb_zonal_negs = {
  "neg-nane1-a-lab-internal-alb-01" = {
    zone         = "northamerica-northeast1-a"
    network      = "default"
    subnetwork   = "default"
    default_port = 443

    network_endpoints = [
      {
        instance   = "internal-tcp-backend-01"
        ip_address = "10.162.0.2"
        port       = 443
      }
    ]
  }
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB HEALTH CHECKS
# --------------------------------------------------

alb_health_checks = {
  "hc-nane1-lab-internal-alb-01" = {
    protocol            = "TCP"
    port                = 443
    check_interval_sec  = 10
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB BACKEND SERVICES
# --------------------------------------------------

alb_backend_services = {
  "be-nane1-lab-internal-alb-01" = {
    protocol         = "HTTPS"
    timeout_sec      = 30
    health_check_key = "hc-nane1-lab-internal-alb-01"

    zonal_neg_keys = [
      "neg-nane1-a-lab-internal-alb-01"
    ]
  }
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB URL MAPS
# --------------------------------------------------

alb_url_maps = {
  "urlmap-nane1-lab-internal-alb-01" = {
    default_backend_service_key = "be-nane1-lab-internal-alb-01"
  }
}