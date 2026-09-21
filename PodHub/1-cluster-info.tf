# Generates the cluster's shared secrets (CA certs, tokens, bootstrap token).
# Consumed by every Talos machine config and by the kubeconfig/provider configs.
# Treat as highly sensitive; it is the root of trust for the whole cluster.
resource "talos_machine_secrets" "secrets" {
  talos_version = var.talos_version
}

# Renders the Talos machine configuration YAML for each node, merging both
# role-level static patches and per-node patches (install, hostname, labels, taints).
data "talos_machine_configuration" "this" {
  for_each           = var.nodes
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_endpoint_host}:${var.cluster_endpoint_port}"
  machine_type       = each.value.role
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches = concat(
    coalesce(each.value.manual, false) ? local.manual_patches_by_role[each.value.role] : local.static_patches_by_role[each.value.role],
    [
      templatefile("${path.module}/templates/UnattendedInstallConfig.yaml.tftpl", {
        disk  = each.value.disk
        image = "factory.talos.dev/installer/${lookup(local.architecture_role_to_schematic, "${each.value.architecture}-${each.value.role}")}:${var.talos_version}"
      }),
      templatefile("${path.module}/templates/HostnameConfig.yaml.tftpl", {
        hostname = each.value.hostname
      }),
    ],
    (
      length(each.value.labels) > 0 || (each.value.role == "worker" && length(each.value.taints) > 0)
      ? [templatefile("${path.module}/templates/KubeNodeConfig.yaml.tftpl", {
        labels = each.value.labels
        taints = each.value.role == "worker" ? each.value.taints : {}
      })]
      : []
    ),
  )
}

# Builds the talosctl client config (talosconfig) pointing at the cluster
# endpoint, so operators can run `talosctl` against the cluster post-apply.
data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.secrets.client_configuration
  endpoints            = local.controlplane_node_ips
}

locals {
  # Base patches applied to ALL auto-provisioned nodes regardless of role
  static_patches_base = [
    file("${path.module}/patches/KubeSpanConfig.yaml"),
    file("${path.module}/patches/RegistryMirrorConfig.yaml"),
  ]

  # Base patches for manually-applied nodes: same as auto but WITHOUT the
  # registry mirror (remote/manual nodes can't reach the local mirror).
  manual_patches_base = [
    file("${path.module}/patches/KubeSpanConfig.yaml"),
  ]

  # Additional patches applied ONLY to control plane nodes
  static_patches_controlplane_extra = concat(
    [
      file("${path.module}/patches/KubeAdmissionControlConfig.yaml"),
      file("${path.module}/patches/KubeFlannelCNIConfig.yaml"),
      file("${path.module}/patches/KubeProxyConfig.yaml"),
      file("${path.module}/patches/etcdMetrics.yaml"),
    ],
    var.cluster_vip_ip != null ? [
      templatefile("${path.module}/templates/Layer2VIPConfig.yaml.tftpl", {
        vip_ip   = var.cluster_vip_ip
        vip_link = var.cluster_vip_link
      })
    ] : [],
  )

  # Maps each role to its complete list of patches
  static_patches_by_role = {
    controlplane = concat(local.static_patches_base, local.static_patches_controlplane_extra)
    worker       = local.static_patches_base
  }

  # Maps each role to its manual-node patches (no RegistryMirror)
  manual_patches_by_role = {
    controlplane = concat(local.manual_patches_base, local.static_patches_controlplane_extra)
    worker       = local.manual_patches_base
  }

  # Split nodes by provisioning mode. data.talos_machine_configuration.this above
  # still iterates over ALL var.nodes so manual nodes get rendered configs,
  # but everything below that provisions or gates on a live cluster uses auto only.
  auto_nodes   = { for ip, n in var.nodes : ip => n if coalesce(n.manual, false) == false }
  manual_nodes = { for ip, n in var.nodes : ip => n if coalesce(n.manual, false) == true }

  # Convenience lookups derived from auto_nodes — used by bootstrap, health checks, and iteration
  first_controlplane_ip = [for ip, n in local.auto_nodes : ip if n.role == "controlplane"][0]
  controlplane_node_ips = [for ip, n in local.auto_nodes : ip if n.role == "controlplane"]
  worker_node_ips       = [for ip, n in local.auto_nodes : ip if n.role == "worker"]

  # Per-node resolved config: role, machine configuration from data source, and installer schematic ID
  node_config = {
    for ip, node in var.nodes : ip => {
      role         = node.role
      machine_type = data.talos_machine_configuration.this[ip].machine_configuration
      schematic_id = local.architecture_role_to_schematic["${node.architecture}-${node.role}"]
    }
  }

  # Installer image per node (used by talos_machine resource)
  node_image = {
    for ip, node in var.nodes : ip =>
    "factory.talos.dev/installer/${local.node_config[ip].schematic_id}:${var.talos_version}"
  }
}
