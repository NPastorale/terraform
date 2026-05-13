cluster_name          = "PodHub"
cluster_endpoint_host = "192.168.64.15"
talos_version         = "v1.12.4"
kubernetes_version    = "v1.35.3"

nodes = {
  "192.168.64.15" = {
    role         = "controlplane"
    architecture = "arm64_generic"
    disk         = "/dev/vda"
    hostname     = "absolute-overlord-1"
    labels = {
      "topology.kubernetes.io/region" = "ESP"
      "topology.kubernetes.io/zone"   = "Barcelona"
    }
  }
  "192.168.64.16" = {
    role         = "worker"
    architecture = "arm64_generic"
    disk         = "/dev/vda"
    hostname     = "abysmal-underling-1"
    labels = {
      "topology.kubernetes.io/region" = "ESP"
      "topology.kubernetes.io/zone"   = "Barcelona"
    }
  }
}

kms_service_account_base64 = "YXNk"

vault_token_base64 = "YXNk"
