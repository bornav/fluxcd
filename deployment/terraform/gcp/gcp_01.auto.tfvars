gcp_01 = {
    name = "instance-gcp-x86-01"
    region = "us-central1"
    zone = "us-central1-c"
    machine_type = "e2-micro"
    tags = ["http-server", "https-server","allow-all-traffic"]
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
      ssh-keys = "ubunut:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeIvrOE9lMNjGuW6pm0RMGET8ze+Qr9/R4fgXplguadgOPi1rys3mRXkxMLMPgLbKrSRACt33arRprfnSbA6YIMl6WdaOSJAh0uPHeD82tt90F2DuQKCqCLmjbQenaFrjBlTlKnSpRTZd0m+5nfHOSE4XCyIllULhBKh6wrNdulJ3X7ZrpqS3gS/P5R7jxghScjUR/Y+GmhuLroow85LgzGQuoDfanm6YQgTB9Y+vYzUIZWs6edAEkGesTUJdnAxUIrEssBZUiWfw/ZqwK+APiQ0cCjcr8PR4wHMo0gK2Xgspn6FoIpogQBCJreQ2gColot9uYZaE6qla3JtAP3qlcjstkbh0qploijz0AMLLM8njs6hK5XSnjLsvc68q1OfS8NREWCs2z7m7ZR3UbeKcl1P3UkPsbCnqTFao618ISb2ButR5yFROqmKdk4fcQajdlKRtvgMc6zC0OI5ApyLCCIhPwGDrTjMl1rrAL7O1/aV8jg2X1Efqg1g1UV3qsmnSNUUO30W0EMI63KlynOF9uSpuBTc5we2OIK2hOF6ty5wpb3Y6a+vNnEl8A4QqvhTA0DZB4miH1PGweAc5P1mrNHcmj3oBGh3FxkxH8dpltkP5lckIHcRHZEKdLrQN0y54aoE9mfm08q3StmS0PDFI1LhUaH7wIxCApMLl+TYIFFw=="
    }
    network_interface = {
      access_config = {
        network_tier = "STANDARD"
      }
    }
    scheduling = {
      automatic_restart = true
      on_host_maintenance = "MIGRATE"
      preemptible = false
      provisioning_model = "STANDARD"
    }
    service_account = {
      email = "278952645295-compute@developer.gserviceaccount.com"
      scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }
    shielded_instance_config = {
      enable_integrity_monitoring = true
      enable_secure_boot = false
      enable_vtpm = true
    }
    gc_network = {
      auto_create_subnetworks = false
      name = "k3s-network"
    }
    gc_subnet = {
      name = "k3s-subnetwork"
      ip_cidr_range = "10.20.0.0/24"
      region = "us-central1"
    }   
}