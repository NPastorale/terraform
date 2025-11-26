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
      version = "0.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}
