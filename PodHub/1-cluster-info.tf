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
  config_patches     = local.static_patches_by_role["controlplane"]
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
  config_patches     = local.static_patches_by_role["worker"]
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.secrets.client_configuration
  endpoints            = [var.cluster_endpoint_host]
}

locals {
  # Base patches applied to ALL nodes regardless of role
  static_patches_base = [
    file("${path.module}/patches/kubespan.yaml"),
    file("${path.module}/patches/registry-mirrors.yaml"),
  ]

  # Additional patches applied ONLY to control plane nodes
  static_patches_controlplane_extra = concat(
    [
      file("${path.module}/patches/admissionControl.yaml"),
      file("${path.module}/patches/CNI.yaml"),
    ],
    var.cluster_vip_ip != null ? [
      templatefile("${path.module}/templates/vip.tftpl.yaml", {
        vip_ip = var.cluster_vip_ip
      })
    ] : [],
  )

  # Maps each role to its complete list of patches
  # Used when generating the Talos machine configuration per role
  static_patches_by_role = {
    controlplane = concat(local.static_patches_base, local.static_patches_controlplane_extra)
    worker       = local.static_patches_base
  }

  # Maps logical role names to the pre-generated Talos machine configuration YAML
  # Avoids repeating the data source lookup in every per-node resource
  role_to_machine_config = {
    controlplane = data.talos_machine_configuration.controlplane.machine_configuration
    worker       = data.talos_machine_configuration.worker.machine_configuration
  }

  # Convenience lookups derived from var.nodes — used by bootstrap, health checks, and iteration
  first_controlplane_ip = [for ip, n in var.nodes : ip if n.role == "controlplane"][0]
  controlplane_node_ips = [for ip, n in var.nodes : ip if n.role == "controlplane"]
  worker_node_ips       = [for ip, n in var.nodes : ip if n.role == "worker"]

  # Per-node resolved config: role, raw machine configuration, and installer schematic ID
  node_config = {
    for ip, node in var.nodes : ip => {
      role         = node.role
      machine_type = local.role_to_machine_config[node.role]
      schematic_id = local.architecture_to_schematic[node.architecture]
    }
  }

  # Per-node config patches combining installation target, hostname, labels, and taints
  per_node_patches = {
    for ip, node in var.nodes : ip => concat(
      [
        templatefile("${path.module}/templates/installation.tftpl.yaml", {
          disk = node.disk
          # Installer image includes the schematic ID so the node boots with the right extensions.
          image = "factory.talos.dev/installer/${local.node_config[ip].schematic_id}:${var.talos_version}"
        }),
        templatefile("${path.module}/templates/hostname.tftpl.yaml", {
          hostname = node.hostname
        }),
      ],
      local.node_labels_patch[ip],
      local.worker_taints_patch[ip],
    )
  }

  # Generates a labels patch per node (if any labels are defined), otherwise an empty list
  node_labels_patch = {
    for ip, node in var.nodes : ip => (
      length(node.labels) > 0
      ? [templatefile("${path.module}/templates/labels.tftpl.yaml", { labels = node.labels })]
      : []
    )
  }

  # Generates a taints patch per worker node (if any taints are defined), otherwise an empty list
  # Control plane nodes never receive taint patches
  worker_taints_patch = {
    for ip, node in var.nodes : ip => (
      node.role == "worker" && length(node.taints) > 0
      ? [templatefile("${path.module}/templates/taints.tftpl.yaml", { taints = node.taints })]
      : []
    )
  }
}
