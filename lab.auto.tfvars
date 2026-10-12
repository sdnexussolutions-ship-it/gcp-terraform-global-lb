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
# --------------------------------------------------
# REGIONAL INTERNAL ALB TARGET HTTPS PROXIES
# --------------------------------------------------

alb_target_https_proxies = {
  "https-proxy-nane1-lab-internal-alb-01" = {
    url_map_key = "urlmap-nane1-lab-internal-alb-01"
  }
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB FRONTEND IP ADDRESSES
# --------------------------------------------------

alb_frontend_ips = {
  "ip-nane1-lab-internal-alb-01" = {
    address_type = "INTERNAL"
    subnetwork   = "default"
  }
}
# --------------------------------------------------
# REGIONAL INTERNAL ALB FORWARDING RULES
# --------------------------------------------------

alb_forwarding_rules = {
  "fr-nane1-lab-internal-alb-01" = {
    network         = "default"
    subnetwork      = "default"
    ip_address_key  = "ip-nane1-lab-internal-alb-01"
    https_proxy_key = "https-proxy-nane1-lab-internal-alb-01"
    port            = 443
  }
}
# Learning VPC configurations
learning_vpcs = {
  "terraform-learning-vpc-01" = {
    auto_create_subnetworks = false
  }

  "terraform-learning-vpc-02" = {
    auto_create_subnetworks = false
  }
}

# Learning subnet configurations
learning_subnets = {
  "web-subnet" = {
    vpc_name      = "terraform-learning-vpc-01"
    region        = "northamerica-northeast1"
    ip_cidr_range = "10.10.1.0/24"
  }

  "app-subnet" = {
    vpc_name      = "terraform-learning-vpc-01"
    region        = "northamerica-northeast1"
    ip_cidr_range = "10.10.2.0/24"
  }

  "dev-subnet" = {
    vpc_name      = "terraform-learning-vpc-02"
    region        = "northamerica-northeast1"
    ip_cidr_range = "10.20.1.0/24"
  }
}
