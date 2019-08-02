resource "google_compute_network" "jenkube_network" {
  name = "${var.network}"
}
