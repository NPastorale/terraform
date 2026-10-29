# Human-readable cluster name (used in certs, talosconfig, namespaces).
cluster_name = "PodHub"
# VIP/endpoint IP clients and nodes use to reach the API server.
cluster_endpoint_host = "10.10.20.15"
cluster_vip_ip        = "10.10.20.15"
cluster_vip_link      = "end0"
# Machine-config CONTRACT version: the schema/defaults used to render machine
# configs. Pin it to the version the cluster was created with; do not bump it
# for OS upgrades. Only bump it deliberately (e.g. when moving to a new Talos
# minor) as a separate apply.
talos_version = "v1.14.4"
# Talos OS version installed on / upgraded to. Bump this for Talos upgrades.
# Must exist on the Image Factory for the chosen schematics/extensions.
talos_installer_version = "v1.14.4"
# Kubernetes version Talos will boot (must be compatible with the Talos version;
# Talos 1.14 supports Kubernetes 1.33 - 1.37).
kubernetes_version = "v1.37.1"

# The set of physical/virtual nodes. Keyed by IP; each entry picks its role
# (controlplane/worker), architecture (selects the Image Factory schematic),
# install disk, hostname, and optional k8s labels/taints.
nodes = {
  "10.10.20.11" = {
    role         = "controlplane" # First control-plane node is used to bootstrap.
    architecture = "arm64_rpi"    # Picks the arm64_rpi-controlplane Image Factory schematic.
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
    protected    = true # NO physical access: Terraform must never apply config to,
    # reset, wipe or destroy this node. It rejoins via KubeSpan.
    labels = {
      "topology.kubernetes.io/region" = "ARG"
      "topology.kubernetes.io/zone"   = "CABA"
    }
    taints = {
      "topology.kubernetes.io/region" = "ARG:NoSchedule"
    }
  }
  "192.168.1.5" = {
    role         = "worker"
    architecture = "x86_intel"
    disk         = "/dev/mmcblk0"
    hostname     = "macabre-underling-1"
    manual       = true
    protected    = true # NO physical access: Terraform must never apply config to,
    # reset, wipe or destroy this node. It rejoins via KubeSpan.
    labels = {
      "topology.kubernetes.io/region" = "ARG"
      "topology.kubernetes.io/zone"   = "Rosario"
    }
    taints = {
      "topology.kubernetes.io/region" = "ARG:NoSchedule"
    }
  }
}

# GCP KMS service-account JSON (base64) used by Vault for auto-unseal. SENSITIVE.
kms_service_account_base64 = "PLACEHOLDER_FOR_GCP_KMS_SERVICE_ACCOUNT_JSON_BASE64"

# Vault token (base64) used by the External Secrets Operator. SENSITIVE.
vault_token_base64 = "PLACEHOLDER_FOR_VAULT_TOKEN_BASE64"
