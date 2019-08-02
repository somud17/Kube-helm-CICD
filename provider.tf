provider "google" {
    credentials = "${file("../gce/defaultkey.json")}"
    project     = "${var.project-name}"
    region      = "${var.region}"
}