terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.69.1"
    }
  }
}

provider "google" {
  project = "k3s-cluster-383907"
  credentials = "${file("credentials.json")}"
  region = "us-central1"
  zone = "us-central1-c"
}