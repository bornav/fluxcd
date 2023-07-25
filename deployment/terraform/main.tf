resource "google_compute_instance" "instance-gcp-x86-01" {
  name = var.gcp_01.name
  allow_stopping_for_update = var.gcp_01.allow_stopping_for_update
  can_ip_forward      = var.gcp_01.can_ip_forward
  deletion_protection = var.gcp_01.deletion_protection
  enable_display      = var.gcp_01.enable_display
  machine_type = var.gcp_01.machine_type
  tags = var.gcp_01.tags
  zone = var.gcp_01.zone
  boot_disk {
    auto_delete = var.gcp_01.boot_disk.auto_delete
    device_name = var.gcp_01.boot_disk.device_name
    mode = var.gcp_01.boot_disk.mode
    initialize_params {
      image = var.gcp_01.boot_disk.initialize_params.image
      size  = var.gcp_01.boot_disk.initialize_params.size
      type  = var.gcp_01.boot_disk.initialize_params.type
    }
  }
  labels = {
    goog-ec-src = var.gcp_01.labels.goog-ec-src
  }
  metadata = {
    ssh-keys = var.gcp_01.metadata.ssh-keys
  }
  network_interface {
    network = google_compute_network.gc_network.self_link
    subnetwork = google_compute_subnetwork.gc_subnet.self_link
    access_config {
      network_tier = var.gcp_01.network_interface.access_config.network_tier
    }
  }
  scheduling {
    automatic_restart   = var.gcp_01.scheduling.automatic_restart
    on_host_maintenance = var.gcp_01.scheduling.on_host_maintenance
    preemptible         = var.gcp_01.scheduling.preemptible
    provisioning_model  = var.gcp_01.scheduling.provisioning_model
  }
  service_account {
    email  = var.gcp_01.service_account.email
    scopes = var.gcp_01.service_account.scopes
  }
  shielded_instance_config {
    enable_integrity_monitoring = var.gcp_01.shielded_instance_config.enable_integrity_monitoring
    enable_secure_boot          = var.gcp_01.shielded_instance_config.enable_secure_boot
    enable_vtpm                 = var.gcp_01.shielded_instance_config.enable_vtpm
  }
}
resource "google_compute_network" "gc_network"{
  name = var.gcp_01.gc_network.name
  auto_create_subnetworks = var.gcp_01.gc_network.auto_create_subnetworks
}
resource "google_compute_subnetwork" "gc_subnet" {
  name = var.gcp_01.gc_subnet.name
  ip_cidr_range = var.gcp_01.gc_subnet.ip_cidr_range
  region = var.gcp_01.gc_subnet.region
  network = google_compute_network.gc_network.id
}

resource "google_compute_firewall" "gc_firewall" {
  name    = "allow-all-traffic"
  network = google_compute_network.gc_network.name
  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-all-traffic"]
}

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.75.0"
    }
    oci = {
      source = "oracle/oci"
      version = "5.5.0"
    }
     aws = {
      source = "hashicorp/aws"
      version = "5.9.0"
    }
  }
}

provider "google" {
  project = "k3s-cluster-383907"
  credentials = file(var.credentials_gpc_01)
  region = var.gcp_01.region
  zone = var.gcp_01.zone
}
provider "oci" {
  # Configuration options
}
provider "aws" {
  # Configuration options
}
