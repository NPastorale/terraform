output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "controlplane_configs" {
  value = [
    for ip, config in talos_machine_configuration_apply.all :
    config.machine_configuration
    if var.nodes[ip].role == "controlplane"
  ]
  sensitive = true
}

output "worker_configs" {
  value = [
    for ip, config in talos_machine_configuration_apply.all :
    config.machine_configuration
    if var.nodes[ip].role == "worker"
  ]
  sensitive = true
}

# output "raspberries_config" {
#   value = [
#     for k in talos_machine_configuration_apply.raspberries : k.machine_configuration
#   ]
#   sensitive = true
# }

# output "N100s_config" {
#   value = [
#     for k in talos_machine_configuration_apply.N100s : k.machine_configuration
#   ]
#   sensitive = true
# }

# output "masita_config" {
#   value = [
#     for k in data.talos_machine_configuration.masita : k.machine_configuration
#   ]
#   sensitive = true
# }

# output "porteño_config" {
#   value = [
#     for k in data.talos_machine_configuration.porteño : k.machine_configuration
#   ]
#   sensitive = true
# }


# Output secrets in a format compatible with talosctl
locals {
  # Shorthand reference to the machine secrets object for reuse below.
  ms = talos_machine_secrets.secrets.machine_secrets

  # Maps Terraform's internal certificate key names to the snake_case keys expected by talosctl.
  # talosctl uses "k8saggregator", "k8sserviceaccount" etc. while Terraform uses "k8s_aggregator".
  cert_section_map = {
    etcd               = "etcd"
    k8s                = "k8s"
    k8s_aggregator     = "k8saggregator"
    k8s_serviceaccount = "k8sserviceaccount"
    os                 = "os"
  }

  # Reformats the certs map: renames sections via cert_section_map and renames "cert" keys to "crt"
  # to match the format expected by `talosctl secrets`.
  certs = {
    for k, v in local.ms.certs :
    lookup(local.cert_section_map, k, k) => {
      for ik, iv in v :
      (ik == "cert" ? "crt" : ik) => iv
    }
  }

  # Collects bootstrap token and optional encryption secrets into a single map.
  # The conditional checks ensure we only include encryption keys when they are actually set,
  # avoiding null entries that would break YAML serialization.
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

  # Assembles the full secrets structure in the exact format expected by `talosctl cluster create --from-secrets`.
  # Mirroring the upstream secrets.yaml schema so the output can be piped directly into talosctl commands.
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
