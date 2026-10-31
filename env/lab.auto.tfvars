internal_albs = {
  mule = {

    # ----------------------------------------
    # VM-BASED ZONAL NEGs
    # ----------------------------------------
    alb_zonal_negs = {
      "neg-nane1-mule-sbx-alb-01" = {
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

    # ----------------------------------------
    # CLOUD RUN SERVERLESS NEGs
    # ----------------------------------------
    alb_serverless_negs = {
      "neg-nane1-mule-dev-cloudrun-01" = {
        cloud_run_service = "mule-dev-cloudrun"
      }
    }

    # --------------------------------------------------
    # REGIONAL INTERNAL ALB HEALTH CHECKS
    # --------------------------------------------------

    alb_health_checks = {

      "hc-nane1-mule-sbx-alb-01" = {
        protocol            = "TCP"
        port                = 443
        check_interval_sec  = 5
        timeout_sec         = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
    # --------------------------------------------------
    # REGIONAL INTERNAL ALB BACKEND SERVICES
    # --------------------------------------------------

    alb_backend_services = {

      "be-nane1-mule-sbx-alb-01" = {
        protocol         = "HTTPS"
        timeout_sec      = 30
        health_check_key = "hc-nane1-mule-sbx-alb-01"
        zonal_neg_keys   = ["neg-nane1-mule-sbx-alb-01"]
        backend_auth_key = "mule-sbx-alb-01"
      }

      "be-nane1-mule-dev-alb-01" = {
        protocol            = "HTTP"
        timeout_sec         = 30
        serverless_neg_keys = ["neg-nane1-mule-dev-cloudrun-01"]
      }
    }
    # --------------------------------------------------
    # REGIONAL INTERNAL ALB URL MAPS
    # --------------------------------------------------

    alb_url_maps = {
      "urlmap-nane1-mule-sbx-alb-01" = {
        default_backend_service_key = "be-nane1-mule-sbx-alb-01"
        path_rules = {
          "/test1" = "be-nane1-mule-sbx-alb-01"
          "/test2" = "be-nane1-mule-dev-alb-01"
        }
      }
    }
    # --------------------------------------------------
    # REGIONAL INTERNAL ALB TARGET HTTPS PROXIES
    # --------------------------------------------------

    alb_target_https_proxies = {

      "https-proxy-nane1-mule-sbx-alb-01" = {
        url_map_key           = "urlmap-nane1-mule-sbx-alb-01"
        ssl_certificate_key   = "mule-sbx-alb-01"
        server_tls_policy_key = "mule-sbx-alb-01"
      }
    }
    # --------------------------------------------------
    # REGIONAL INTERNAL ALB FRONTEND IP ADDRESSES
    # --------------------------------------------------

    alb_frontend_ips = {

      "ip-nane1-mule-sbx-alb-01" = {
        address_type = "INTERNAL"
        subnetwork   = "default"
      }
    }
    # --------------------------------------------------
    # REGIONAL INTERNAL ALB FORWARDING RULES
    # --------------------------------------------------
    alb_forwarding_rules = {

      "fr-nane1-mule-sbx-alb-01" = {
        network         = "default"
        subnetwork      = "default"
        ip_address_key  = "ip-nane1-mule-sbx-alb-01"
        https_proxy_key = "https-proxy-nane1-mule-sbx-alb-01"
        port            = 443
      }
    }

  }
}
# --------------------------------------------------
# Cloud Run
# --------------------------------------------------

cloud_run_services = {
  "mule-dev-cloudrun" = {
    image          = "us-docker.pkg.dev/cloudrun/container/hello"
    container_port = 8080
  }
}