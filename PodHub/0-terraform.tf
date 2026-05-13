terraform {
  # cloud {
  #   organization = "Nahue"

  #   workspaces {
  #     name = "PodHub"
  #   }
  # }
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    argocd = {
      source = "argoproj-labs/argocd"
    }
  }
}
