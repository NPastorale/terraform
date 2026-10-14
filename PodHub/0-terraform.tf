# Core Terraform settings: required provider sources and pinned versions.
# Versions are frozen to guarantee reproducible applies across machines/CI.
# (The Terraform Cloud "cloud{}" block is commented out; state is local.)
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
      version = "0.12.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.4.1"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.17.0"
    }
  }
}

# Helm provider pointed at the freshly bootstrapped cluster. It reuses the
# decoded kubeconfig (local.kubernetes_client_config) so Helm can talk to the API.
provider "helm" {
  kubernetes = local.kubernetes_client_config
}

# Kubernetes provider used by the kubernetes_* resources (namespaces, secrets).
# Credentials are taken from the Talos-issued kubeconfig, decoded into plain PEM.
provider "kubernetes" {
  host                   = local.kubernetes_client_config.host
  cluster_ca_certificate = local.kubernetes_client_config.cluster_ca_certificate
  client_certificate     = local.kubernetes_client_config.client_certificate
  client_key             = local.kubernetes_client_config.client_key
}

# ArgoCD provider authenticates as the admin user using the initial admin
# secret from the ArgoCD install. port_forward=true lets it reach the ArgoCD
# API server through a local kubectl port-forward (no ingress required).
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
