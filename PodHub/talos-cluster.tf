resource "talos_machine_secrets" "secrets" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_endpoint_host}:${var.cluster_endpoint_port}"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_endpoint_host}:${var.cluster_endpoint_port}"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.secrets.client_configuration
  endpoints            = [for k, v in var.controlplanes : k]
}

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each                    = var.controlplanes
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/templates/installation.tftpl", { hostname = each.value.hostname, disk = each.value.disk }),
    templatefile("${path.module}/templates/cilium.tftpl", { cilium_manifest = indent(8, data.helm_template.cilium.manifest) }),
    file("${path.module}/patches/VIP.yaml"),
    file("${path.module}/patches/control-plane-label.yaml"),
    file("${path.module}/patches/cilium.yaml"),
    file("${path.module}/patches/kubespan.yaml")
  ]
}

resource "talos_machine_configuration_apply" "raspberries" {
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.raspberries
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/templates/installation.tftpl", {
      hostname = each.value.hostname
      disk     = each.value.disk
    }),
    file("${path.module}/patches/cilium.yaml"),
    file("${path.module}/patches/kubespan.yaml")
  ]
}

resource "talos_machine_configuration_apply" "N100s" {
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.N100s
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/templates/installation.tftpl", {
      hostname = each.value.hostname
      disk     = each.value.disk
    }),
    file("${path.module}/patches/iGPU-extension.yaml"),
    file("${path.module}/patches/cilium.yaml"),
    file("${path.module}/patches/kubespan.yaml")
  ]
}

resource "talos_machine_configuration_apply" "masita" {
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.masita
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/templates/installation.tftpl", {
      hostname = each.value.hostname
      disk     = each.value.disk
    }),
    file("${path.module}/patches/cilium.yaml"),
    file("${path.module}/patches/kubespan.yaml")
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = [for k, v in var.controlplanes : k][0]
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [talos_machine_bootstrap.bootstrap]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = [for k, v in var.controlplanes : k][0]
  wait                 = true
}
