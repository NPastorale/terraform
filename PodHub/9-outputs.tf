# Dumps the talosctl client config so operators can manage the cluster remotely.
output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

# Dumps the admin kubeconfig for kubectl / CI access to the cluster.
output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

# Exposes the rendered auto-provisioned control-plane machine configurations (for audit/debug).
output "controlplane_configs" {
  value = [
    for ip, node in local.auto_nodes :
    data.talos_machine_configuration.this[ip].machine_configuration
    if node.role == "controlplane"
  ]
  sensitive = true
}

# Exposes the rendered auto-provisioned worker machine configurations (for audit/debug).
output "worker_configs" {
  value = [
    for ip, node in local.auto_nodes :
    data.talos_machine_configuration.this[ip].machine_configuration
    if node.role == "worker"
  ]
  sensitive = true
}

# Rendered machine configs for manually-applied nodes (manual=true).
# Grab a single node YAML with e.g.:
#   terraform output -json manual_configs | jq -r '."10.10.20.30"'
output "manual_configs" {
  description = "Map of node IP -> rendered Talos machine_configuration YAML for manual `talosctl apply-config`."
  value = {
    for ip, node in local.manual_nodes :
    ip => data.talos_machine_configuration.this[ip].machine_configuration
  }
  sensitive = true
}

# Helper metadata for manual nodes so operators know which installer image / hostname each config belongs to.
output "manual_nodes_info" {
  description = "Map of node IP -> { hostname, role, architecture, image } for manual nodes."
  value = {
    for ip, node in local.manual_nodes :
    ip => {
      hostname     = node.hostname
      role         = node.role
      architecture = node.architecture
      image        = local.node_image[ip]
    }
  }
}


# Re-formats the generated Talos machine secrets into the YAML shape expected by
# `talosctl cluster create --from-secrets`, so the cluster's trust material can be
# exported/reimported portably.
locals {
  ms = talos_machine_secrets.secrets.machine_secrets

  # Maps Terraform's internal certificate key names to the snake_case keys expected by talosctl
  cert_section_map = {
    etcd               = "etcd"
    k8s                = "k8s"
    k8s_aggregator     = "k8saggregator"
    k8s_serviceaccount = "k8sserviceaccount"
    os                 = "os"
  }

  # Reformats the certs map: renames sections via cert_section_map and renames "cert" keys to "crt"
  #to match the format expected by `talosctl secrets`
  certs = {
    for k, v in local.ms.certs :
    lookup(local.cert_section_map, k, k) => {
      for ik, iv in v :
      (ik == "cert" ? "crt" : ik) => iv
    }
  }

  # Collects bootstrap token and optional encryption secrets into a single map
  secrets = merge(
    { bootstraptoken = local.ms.secrets.bootstrap_token },
    (
      try(local.ms.secrets.secretbox_encryption_secret, null) != null &&
      try(local.ms.secrets.secretbox_encryption_secret, "") != ""
    ) ? { secretboxencryptionsecret = local.ms.secrets.secretbox_encryption_secret } : {},
    (
      try(local.ms.secrets.aescbc_encryption_secret, null) != null &&
      try(local.ms.secrets.aescbc_encryption_secret, "") != ""
    ) ? { aescbcencryptionsecret = local.ms.secrets.aescbc_encryption_secret } : {}
  )

  # Assembles the full secrets structure in the exact format expected by `talosctl cluster create --from-secrets`
  talos_secrets = {
    cluster    = local.ms.cluster
    secrets    = local.secrets
    trustdinfo = local.ms.trustdinfo
    certs      = local.certs
  }
}

output "talos_secrets_yaml" {
  description = "Talos-compatible secrets.yaml content (YAML string)."
  value       = yamlencode(local.talos_secrets)
  sensitive   = true
}
