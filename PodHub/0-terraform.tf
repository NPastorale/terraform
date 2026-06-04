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
      source  = "hashicorp/helm"
      version = "3.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.2.0"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.15.3"
    }
  }
}

provider "helm" {
  kubernetes = local.kubernetes_client_config
}

provider "kubernetes" {
  host                   = local.kubernetes_client_config.host
  cluster_ca_certificate = local.kubernetes_client_config.cluster_ca_certificate
  client_certificate     = local.kubernetes_client_config.client_certificate
  client_key             = local.kubernetes_client_config.client_key
}

provider "argocd" {
  username     = "admin"
  password     = data.kubernetes_secret_v1.argocd_admin.data["password"]
  port_forward = true
  kubernetes {
    host                   = local.kubernetes_client_config.host
    cluster_ca_certificate = local.kubernetes_client_config.cluster_ca_certificate
    client_certificate     = local.kubernetes_client_config.client_certificate
    client_key             = local.kubernetes_client_config.client_key
  }
}
