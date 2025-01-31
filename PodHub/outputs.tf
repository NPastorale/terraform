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
