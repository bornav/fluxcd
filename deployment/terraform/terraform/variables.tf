variable gcp_01 {
    type = object({
        name = string
        region = string
        zone = string
        machine_type = string
        tags = list(string)
        allow_stopping_for_update = bool
        can_ip_forward      = bool
        deletion_protection = bool
        enable_display      = bool
        boot_disk = object({
          auto_delete = bool
          device_name = string
          mode = string
          initialize_params = object({
            image = string
            size = number
            type = string
          })
        })
        labels = object({
          goog-ec-src = string
        })
        metadata = object({
          ssh-keys = string
        })
        network_interface = object({
        #   network = 
        #   subnetwork = 
          access_config = object({
            network_tier = string
          })
        })
        scheduling = object({
          automatic_restart = bool
          on_host_maintenance = string
          preemptible = bool
          provisioning_model = string
        })
        service_account = object({
          email = string
          scopes = list(string)
        })
        shielded_instance_config = object({
          enable_integrity_monitoring = bool
          enable_secure_boot = bool
          enable_vtpm = bool
        })
        gc_network = object({
          name = string
          auto_create_subnetworks = bool
        })
        gc_subnet = object({
          name = string
          ip_cidr_range = string
          region = string
        #   network = 
        })
    })
    default = {
        name = "instance-gcp-x86-01"
        region = "us-central1"
        zone = "us-central1-c"
        machine_type = "e2-micro"
        tags = ["http-server", "https-server"]
        allow_stopping_for_update = true
        can_ip_forward      = true
        deletion_protection = false
        enable_display      = false
        boot_disk = {
          auto_delete = true
          device_name = "instance-gcp-x86-01"
          mode = "READ_WRITE"
          initialize_params = {
            image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20230617"
            size  = 30
            type  = "pd-standard"
          }
        }
        labels = {
          goog-ec-src = "vm_add-tf"
        }
        metadata = {
          ssh-keys = ""
        }
        network_interface = {
        #   network = google_compute_network.k3s_network.self_link ##!!!!
        #   subnetwork = google_compute_subnetwork.k3s_subnet.self_link ##!!!!
          access_config = {
            network_tier = ""
          }
        }
        scheduling = {
          automatic_restart = true
          on_host_maintenance = ""
          preemptible = false
          provisioning_model = ""
        }
        service_account = {
          email = ""
          scopes = []
        }
        shielded_instance_config = {
          enable_integrity_monitoring = true
          enable_secure_boot = false
          enable_vtpm = true
        }
        gc_network = {
          name = "default"
          auto_create_subnetworks = true
        }
        gc_subnet = {
          name = "default"
          ip_cidr_range = "10.0.0.0/24"
          region = "us-central1"
        }
    }
}
variable "credentials_gpc_01" {}
