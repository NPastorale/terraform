# Human-readable cluster name (used in certs, talosconfig, namespaces).
cluster_name = "PodHub"
# VIP/endpoint IP clients and nodes use to reach the API server.
cluster_endpoint_host = "10.10.20.15"
cluster_vip_ip        = "10.10.20.15"
cluster_vip_link      = "end0"
# Talos OS version all nodes are installed with (must match installer images).
talos_version = "v1.14.1"
# Kubernetes version Talos will boot (must be compatible with talos_version).
kubernetes_version = "v1.37.0"

# The set of physical/virtual nodes. Keyed by IP; each entry picks its role
# (controlplane/worker), architecture (selects the Image Factory schematic),
# install disk, hostname, and optional k8s labels/taints.
nodes = {
  "10.10.20.11" = {
    role         = "controlplane" # First control-plane node is used to bootstrap.
    architecture = "arm64_rpi"    # Picks talos_image_factory_schematic.arm64_generic.
    disk         = "/dev/mmcblk0" # Target disk for the Talos installer.
    hostname     = "absolute-overlord-1"
    labels = {
      "topology.kubernetes.io/region" = "ESP"
      "topology.kubernetes.io/zone"   = "Barcelona"
    }
  }
  "10.10.20.12" = {
    role         = "controlplane"
    architecture = "arm64_rpi"
    disk         = "/dev/mmcblk0"
    hostname     = "absolute-overlord-2"
    labels = {
      "topology.kubernetes.io/region" = "ESP"
      "topology.kubernetes.io/zone"   = "Barcelona"
    }
  }
  "10.10.20.13" = {
    role         = "controlplane"
    architecture = "arm64_rpi"
    disk         = "/dev/mmcblk0"
    hostname     = "absolute-overlord-3"
    labels = {
      "topology.kubernetes.io/region" = "ESP"
      "topology.kubernetes.io/zone"   = "Barcelona"
    }
  }
  "10.10.20.21" = {
    role         = "worker"
    architecture = "arm64_rpi"
    disk         = "/dev/mmcblk0"
    hostname     = "abysmal-underling-1"
    labels = {
      "topology.kubernetes.io/region" = "ESP"
      "topology.kubernetes.io/zone"   = "Barcelona"
    }
  }
  "10.10.20.22" = {
    role         = "worker"
    architecture = "arm64_rpi"
    disk         = "/dev/mmcblk0"
    hostname     = "abysmal-underling-2"
    labels = {
      "topology.kubernetes.io/region" = "ESP"
      "topology.kubernetes.io/zone"   = "Barcelona"
    }
  }
  "192.168.0.100" = {
    role         = "worker"
    architecture = "x86_intel"
    disk         = "/dev/mmcblk0"
    hostname     = "chaotic-underling-1"
    manual       = true
    labels = {
      "topology.kubernetes.io/region" = "ARG"
      "topology.kubernetes.io/zone"   = "CABA"
    }
  }
  "192.168.1.5" = {
    role         = "worker"
    architecture = "x86_intel"
    disk         = "/dev/mmcblk0"
    hostname     = "macabre-underling-1"
    manual       = true
    labels = {
      "topology.kubernetes.io/region" = "ARG"
      "topology.kubernetes.io/zone"   = "Rosario"
    }
  }
}

# GCP KMS service-account JSON (base64) used by Vault for auto-unseal. SENSITIVE.
kms_service_account_base64 = "PLACEHOLDER_FOR_GCP_KMS_SERVICE_ACCOUNT_JSON_BASE64"

# Vault token (base64) used by the External Secrets Operator. SENSITIVE.
vault_token_base64 = "PLACEHOLDER_FOR_VAULT_TOKEN_BASE64"
