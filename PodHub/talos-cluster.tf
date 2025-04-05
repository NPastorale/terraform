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
  docs               = false
  examples           = false
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_endpoint_host}:${var.cluster_endpoint_port}"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
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
  on_destroy = {
    graceful = false
    reboot   = true
    reset    = true
  }
  config_patches = [
    templatefile("${path.module}/templates/installation.tftpl", {
      hostname = each.value.hostname
      disk     = each.value.disk
      image    = "factory.talos.dev/installer/${talos_image_factory_schematic.raspberry.id}:${var.talos_version}"
    }),
    file("${path.module}/patches/CNI.yaml"),
    file("${path.module}/patches/kubespan.yaml")
  ]
}

resource "talos_machine_configuration_apply" "raspberries" {
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.raspberries
  node                        = each.key
  on_destroy = {
    graceful = false
    reboot   = true
    reset    = true
  }
  config_patches = [
    templatefile("${path.module}/templates/installation.tftpl", {
      hostname = each.value.hostname
      disk     = each.value.disk
      image    = "factory.talos.dev/installer/${talos_image_factory_schematic.raspberry.id}:${var.talos_version}"
    }),
    file("${path.module}/patches/kubespan.yaml")
  ]
}

# resource "talos_machine_configuration_apply" "N100s" {
#   client_configuration        = talos_machine_secrets.secrets.client_configuration
#   machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
#   for_each                    = var.N100s
#   node                        = each.key
#   config_patches = [
#     templatefile("${path.module}/templates/installation.tftpl", {
#       hostname = each.value.hostname
#       disk     = each.value.disk
#     }),
#     # file("${path.module}/patches/iGPU-extension.yaml"),
#     # file("${path.module}/patches/cilium.yaml"),
#     file("${path.module}/patches/kubespan.yaml")
#   ]
# }

# data "talos_machine_configuration" "masita" {
#   cluster_name       = var.cluster_name
#   cluster_endpoint   = "https://10.10.20.5:${var.cluster_endpoint_port}"
#   machine_type       = "worker"
#   machine_secrets    = talos_machine_secrets.secrets.machine_secrets
#   talos_version      = var.talos_version
#   kubernetes_version = var.kubernetes_version
#   docs               = false
#   examples           = false
#   for_each           = var.masita
#   config_patches = [
#     templatefile("${path.module}/templates/installation.tftpl", {
#       hostname = each.value.hostname
#       disk     = each.value.disk
#       image    = "factory.talos.dev/installer/${talos_image_factory_schematic.x86.id}:${var.talos_version}"
#     }),
#     templatefile("${path.module}/templates/taints.tftpl", {
#       taints = each.value.taints
#     }),
#     templatefile("${path.module}/templates/labels.tftpl", {
#       labels = each.value.labels
#     }),
#     file("${path.module}/patches/cilium.yaml"),
#     file("${path.module}/patches/kubespan.yaml")
#   ]
# }

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = [for k, v in var.controlplanes : k][0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.bootstrap]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = [for k, v in var.controlplanes : k][0]
}

data "talos_image_factory_extensions_versions" "x86" {
  talos_version = var.talos_version
  filters = {
    names = [
      "i915-ucode",
      "intel-ucode"
  ] }
}

resource "talos_image_factory_schematic" "x86" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.x86.extensions_info.*.name
  } } })
}

data "talos_image_factory_overlays_versions" "raspberry" {
  talos_version = var.talos_version
  filters = {
    name = "rpi_generic"
  }
}

resource "talos_image_factory_schematic" "raspberry" {
  schematic = yamlencode({
    overlay = {
      image = data.talos_image_factory_overlays_versions.raspberry.overlays_info[0].image
      name  = data.talos_image_factory_overlays_versions.raspberry.overlays_info[0].name
    }
  })
}

data "talos_cluster_health" "talos" {
  client_configuration   = talos_machine_secrets.secrets.client_configuration
  control_plane_nodes    = [for k, v in var.controlplanes : k]
  endpoints              = [for k, v in var.controlplanes : k]
  skip_kubernetes_checks = true
  worker_nodes = concat(
    keys(var.raspberries),
    # keys(var.N100s),
    # keys(var.masita),
  )
}

data "talos_cluster_health" "kubernetes" {
  depends_on           = [helm_release.cilium]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  control_plane_nodes  = [for k, v in var.controlplanes : k]
  endpoints            = [for k, v in var.controlplanes : k]
  worker_nodes = concat(
    keys(var.raspberries),
    # keys(var.N100s),
    # keys(var.masita),
  )
}
