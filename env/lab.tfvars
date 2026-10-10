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