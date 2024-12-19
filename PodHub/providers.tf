terraform {
  cloud {
    organization = "Nahue"

    workspaces {
      name = "PodHub"
    }
  }
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
  }
}
