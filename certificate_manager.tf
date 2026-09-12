resource "google_certificate_manager_certificate_map" "app" {
  name        = "global-lb-cert-map"
  description = "Certificate map for glb-prd.igmfinancial.net"

  depends_on = [
    google_project_service.required_apis
  ]
}

resource "google_certificate_manager_certificate_map_entry" "app" {
  name        = "glb-prd-igmfinancial-net"
  description = "Certificate map entry for glb-prd.igmfinancial.net"

  map      = google_certificate_manager_certificate_map.app.name
  hostname = "glb-prd.igmfinancial.net"

  certificates = [
    "projects/${var.gcp_project_id}/locations/global/certificates/glb-prd-igmfinancial-net"
  ]
}

resource "google_compute_target_https_proxy" "app" {
  name    = "global-lb-https-proxy"
  url_map = google_compute_url_map.app.id

  certificate_map = "//certificatemanager.googleapis.com/projects/${var.gcp_project_id}/locations/global/certificateMaps/${google_certificate_manager_certificate_map.app.name}"
}