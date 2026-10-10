
# --------------------------------------------------
# ZONAL NETWORK ENDPOINT GROUPS
# Regional Internal Application Load Balancer
# --------------------------------------------------

resource "google_compute_network_endpoint_group" "alb_zonal_negs" {

  for_each = var.alb_zonal_negs

  name                  = each.key
  zone                  = each.value.zone
  network               = each.value.network
  subnetwork            = each.value.subnetwork
  network_endpoint_type = "GCE_VM_IP_PORT"

  default_port = each.value.default_port
}

# --------------------------------------------------
# NEG NETWORK ENDPOINTS
# Register VM IP addresses and ports into the NEGs
# --------------------------------------------------

resource "google_compute_network_endpoint" "alb_endpoints" {

  for_each = {
    for endpoint in flatten([
      for neg_name, neg in var.alb_zonal_negs : [
        for index, ep in neg.network_endpoints : {
          key        = "${neg_name}-${index}"
          neg_name   = neg_name
          zone       = neg.zone
          instance   = ep.instance
          ip_address = ep.ip_address
          port       = ep.port
        }
      ]
    ]) : endpoint.key => endpoint
  }

  network_endpoint_group = google_compute_network_endpoint_group.alb_zonal_negs[each.value.neg_name].name

  zone       = each.value.zone
  instance   = each.value.instance
  ip_address = each.value.ip_address
  port       = each.value.port
}
