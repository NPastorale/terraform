# Generates the cluster's shared secrets (CA certs, tokens, bootstrap token).
# Consumed by every Talos machine config and by the kubeconfig/provider configs.
# Treat as highly sensitive; it is the root of trust for the whole cluster.
resource "talos_machine_secrets" "secrets" {
  talos_version = var.talos_version
}

# Renders the Talos machine configuration YAML for each node, merging both
# role-level static patches and per-node patches (install, hostname, labels, taints).
# Kept as a data source so the rendered configs can be exposed as outputs (notably
# `manual_configs` for the protected ARG nodes). talos_machine uses the ephemeral
# variant below instead, see the comment there.
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
  config_patches     = local.node_config_patches[each.key]
}

# Same generated configuration, but ephemeral. talos_machine consumes it through the
# write-only `machine_configuration_wo` argument, so the YAML never reaches state and
# a Kubernetes version bump (which only rewrites the component image tags inside the
# YAML) does not show up as an in-place update on every machine.
#
# This does not weaken drift detection: the provider compares the normalized
# `machine_configuration_hash` on every plan, and `ignore_kubernetes_upgrade_drift`
# strips the version tags from it, so only `talos_cluster` reports the upgrade while
# any other config change (patches, labels, contract) still triggers an update.
ephemeral "talos_machine_configuration" "auto" {
  for_each           = local.auto_nodes
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_endpoint_host}:${var.cluster_endpoint_port}"
  machine_type       = each.value.role
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches     = local.node_config_patches[each.key]
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

  # Complete patch list per node. Shared by the data source (outputs) and the
  # ephemeral resource that feeds talos_machine, so both render the same YAML.
  node_config_patches = {
    for ip, node in var.nodes : ip => concat(
      coalesce(node.manual, false) ? local.manual_patches_by_role[node.role] : local.static_patches_by_role[node.role],
      [
        templatefile("${path.module}/templates/UnattendedInstallConfig.yaml.tftpl", {
          disk  = node.disk
          image = "factory.talos.dev/installer/${lookup(local.architecture_role_to_schematic, "${node.architecture}-${node.role}")}:${var.talos_installer_version}"
        }),
        templatefile("${path.module}/templates/HostnameConfig.yaml.tftpl", {
          hostname = node.hostname
        }),
      ],
      (
        length(node.labels) > 0 || (node.role == "worker" && length(node.taints) > 0)
        ? [templatefile("${path.module}/templates/KubeNodeConfig.yaml.tftpl", {
          labels = node.labels
          taints = node.role == "worker" ? node.taints : {}
        })]
        : []
      ),
    )
  }

  # Split nodes by provisioning mode. data.talos_machine_configuration.this above
  # still iterates over ALL var.nodes so manual nodes get rendered configs,
  # but everything below that provisions or gates on a live cluster uses auto only.
  # protected nodes are excluded defensively: even if `manual` were accidentally
  # dropped, Terraform must never create a talos_machine (and therefore never reset
  # or wipe) a node without physical access.
  auto_nodes = {
    for ip, n in var.nodes : ip => n
    if coalesce(n.manual, false) == false && coalesce(n.protected, false) == false
  }
  manual_nodes = { for ip, n in var.nodes : ip => n if coalesce(n.manual, false) == true }

  # Convenience lookups derived from auto_nodes — used by bootstrap, health checks, and iteration
  first_controlplane_ip = [for ip, n in local.auto_nodes : ip if n.role == "controlplane"][0]
  controlplane_node_ips = [for ip, n in local.auto_nodes : ip if n.role == "controlplane"]

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
    "factory.talos.dev/installer/${local.node_config[ip].schematic_id}:${var.talos_installer_version}"
  }
}
