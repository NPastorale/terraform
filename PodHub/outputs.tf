output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "controlplane_config" {
  value = [
    for k in talos_machine_configuration_apply.controlplane : k.machine_configuration
  ]
  sensitive = true
}

output "raspberries_config" {
  value = [
    for k in talos_machine_configuration_apply.raspberries : k.machine_configuration
  ]
  sensitive = true
}

# output "N100s_config" {
#   value = [
#     for k in talos_machine_configuration_apply.N100s : k.machine_configuration
#   ]
#   sensitive = true
# }

output "masita_config" {
  value = [
    for k in data.talos_machine_configuration.masita : k.machine_configuration
  ]
  sensitive = true
}

output "porteño_config" {
  value = [
    for k in data.talos_machine_configuration.porteño : k.machine_configuration
  ]
  sensitive = true
}


# Output secrets in a format compatible with talosctl
locals {
  ms = talos_machine_secrets.secrets.machine_secrets
  cert_section_map = {
    etcd               = "etcd"
    k8s                = "k8s"
    k8s_aggregator     = "k8saggregator"
    k8s_serviceaccount = "k8sserviceaccount"
    os                 = "os"
  }
  certs = {
    for k, v in local.ms.certs :
    lookup(local.cert_section_map, k, k) => {
      for ik, iv in v :
      (ik == "cert" ? "crt" : ik) => iv
    }
  }
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
