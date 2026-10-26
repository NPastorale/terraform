# Manages each auto-provisioned Talos node: applies machine configuration and keeps the OS version in sync.
# On destroy it resets/reboots the machines so the metal can be re-provisioned cleanly.
# Nodes with manual=true are excluded here — their configs are rendered by
# data.talos_machine_configuration.this but only exposed via outputs for manual `talosctl apply-config`.
#
# Upgrade sequencing: every instance here is updated in parallel (Terraform default
# parallelism is 10). Rebooting all control planes at once drops etcd quorum, so run
# OS upgrades with `terraform apply -parallelism=1` (or per-node -target applies).
# Draining makes that even more important: without it every node would be cordoned
# and drained at the same time, and a PDB or single-replica workload could deadlock
# the whole upgrade.
#
# drain_on_upgrade: cordon/drain the node before rebooting it for an OS upgrade. It
# only runs on image changes, never on config-only updates. The kubeconfig comes from
# the ephemeral resource below, which is generated locally from the machine secrets,
# so it also works on the very first bootstrap (no cluster access required).
#
# CAVEAT (provider 0.12.0): on a from-scratch Create the provider applies the config
# and then still runs its upgrade path when the running (maintenance) Talos version
# differs from `image`. With drain_on_upgrade=true it tries to cordon/drain through
# the kubeconfig, but the cluster does not exist yet, so the create fails with
# "draining node: ... connect: network is unreachable". When the first apply also
# bumps `talos_installer_version`, run it with `-var drain_on_upgrade=false`; the
# upgrade itself still happens, only the drain is skipped. Later applies never drain
# unless `image` changes.
resource "talos_machine" "all" {
  for_each                        = local.auto_nodes
  node                            = each.key
  client_configuration            = talos_machine_secrets.secrets.client_configuration
  machine_configuration_wo        = ephemeral.talos_machine_configuration.managed[each.key].machine_configuration
  image                           = local.node_image[each.key]
  drain_on_upgrade                = var.drain_on_upgrade
  kubeconfig_wo                   = ephemeral.talos_cluster_kubeconfig.this.kubeconfig_raw
  ignore_kubernetes_upgrade_drift = true
  on_destroy = {
    # Control planes use graceful=false. In Talos's reset sequence drain/cleanup are
    # best-effort, but the etcd "leave" phase is NOT: if it fails, the whole reset
    # aborts and the node is not wiped. The last remaining etcd member can never
    # leave, so a graceful reset of the final control plane is impossible and blocks
    # `terraform destroy`. Remove the etcd member manually after a control-plane
    # scale-down instead (see README).
    # Workers have no etcd membership, so graceful only drains them (best-effort).
    # Note: reset=true wipes the disk, which is destructive on physical nodes.
    graceful = each.value.role != "controlplane"
    reboot   = true
    reset    = true
  }
}

# Protected nodes (the remote ARG workers) are managed for config and OS upgrades, but
# must never be reset. on_destroy.reset = false makes the provider's Delete a no-op:
# `terraform destroy` only removes them from state (no STATE/EPHEMERAL wipe, no reboot).
# They are re-adopted by a targeted apply if they are ever dropped from state:
#   terraform apply -target='talos_machine.protected'
# drain_on_upgrade is false: these nodes may not have rejoined the cluster yet when the
# provider runs its create/adoption path, and a failed drain would abort the upgrade.
# Drain them manually (kubectl drain) before a planned upgrade if desired.
#
# The ARG nodes are only reachable over KubeSpan from the control planes, not from the
# machine running Terraform. Connect to the cluster endpoint (the VIP) and let apid
# proxy the request to `node` over the mesh; `node` stays the node's own IP.
resource "talos_machine" "protected" {
  for_each = local.protected_nodes

  depends_on = [talos_cluster.this]

  node                            = each.key
  endpoint                        = var.cluster_endpoint_host
  client_configuration            = talos_machine_secrets.secrets.client_configuration
  machine_configuration_wo        = ephemeral.talos_machine_configuration.managed[each.key].machine_configuration
  image                           = local.node_image[each.key]
  kubeconfig_wo                   = ephemeral.talos_cluster_kubeconfig.this.kubeconfig_raw
  drain_on_upgrade                = false
  ignore_kubernetes_upgrade_drift = true

  on_destroy = {
    reset    = false
    reboot   = false
    graceful = false
  }
}

# Bootstraps the Kubernetes control plane on the first control-plane node.
# Must run after all machine configs are applied; creates the initial etcd cluster.
resource "talos_cluster" "this" {
  depends_on           = [talos_machine.all]
  kubernetes_version   = var.kubernetes_version
  node                 = local.first_controlplane_ip
  client_configuration = talos_machine_secrets.secrets.client_configuration
  control_plane_nodes  = local.controlplane_node_ips
}

# Admin kubeconfig, generated locally from the machine secrets (the provider signs an
# admin certificate with the cluster CA; it does not call the cluster). Because it does
# not depend on a running API, it can feed the providers below AND talos_machine's
# drain logic without creating a cycle, and it is usable on the first bootstrap.
# The raw kubeconfig is write-only, so no certificate material is stored in state.
ephemeral "talos_cluster_kubeconfig" "this" {
  machine_secrets = talos_machine_secrets.secrets.machine_secrets
  cluster_name    = var.cluster_name
  endpoint        = "https://${var.cluster_endpoint_host}:${var.cluster_endpoint_port}"
}

locals {
  # Decoded Kubernetes client configuration for use by Terraform providers
  # The raw kubeconfig contains base64-encoded certs; this decodes them into plain PEM
  # so they can be consumed directly by provider blocks without additional decoding
  kubernetes_client_config = {
    host                   = ephemeral.talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
    cluster_ca_certificate = base64decode(ephemeral.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
    client_certificate     = base64decode(ephemeral.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(ephemeral.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  }
}

# Node inventory as currently registered in Kubernetes. The health gates below use
# this instead of var.nodes so that:
#   * nodes that do not exist yet (scale-up) are not waited for at plan time, and
#   * nodes Terraform does not manage (manual=true, e.g. the remote ARG workers)
#     can never gate an apply.
# On a from-scratch apply this read can fail before it starts: talos_cluster completes
# once the *Talos* layer is healthy (etcd, apid, kubelet), not when kube-apiserver or
# the Layer2 VIP are serving, and the Kubernetes provider does not retry a refused
# connection. Accepted workaround: run `terraform apply` a second time — the cluster
# is up by then and the apply continues from here.
#
# Tracking issue for a control-plane-only health mode, which would replace this
# inventory (and remove the need for the second apply):
#   https://github.com/siderolabs/terraform-provider-talos/issues/221
#
# count = 0 with healthcheck_enabled = false: this inventory is the only thing besides
# the gate itself that needs a functioning control plane, so disabling the gate must
# also skip the read. That is the escape hatch for destroying or repairing a broken
# cluster (API up, but node/etcd state inconsistent).
data "kubernetes_nodes" "current" {
  count      = var.healthcheck_enabled ? 1 : 0
  depends_on = [talos_cluster.this]
}

locals {
  # Empty when the health gate is disabled.
  current_nodes = try(data.kubernetes_nodes.current[0].nodes, [])

  # Control planes currently registered in Kubernetes *and* Ready, with the IPs
  # Kubernetes itself reports for them. Derived from the cluster, not from var.nodes:
  #   * a control plane being added is not registered yet -> not waited for at plan
  #     time, so scale-up no longer deadlocks;
  #   * a control plane being removed is still registered and still an etcd member ->
  #     it stays in the list, so the plan passes and `on_destroy.graceful` can make it
  #     leave etcd during the apply;
  #   * workers (including the manual/remote ARG nodes) are never part of this list.
  # A NotReady control plane is excluded: the etcd subset assertion then fails
  # immediately (instead of hanging for the full timeout), which is the correct
  # signal to remove the member before applying.
  controlplane_label = "node-role.kubernetes.io/control-plane"

  registered_controlplane_ips = flatten([
    for node in local.current_nodes : [
      for addr in node.status[0].addresses : addr.address
      if addr.type == "InternalIP"
    ]
    if try(node.metadata[0].labels[local.controlplane_label], null) != null &&
    anytrue([
      for cond in node.status[0].conditions : cond.status == "True"
      if cond.type == "Ready"
    ])
  ])

  # Fallback for the very first apply, where nothing is registered yet.
  healthcheck_controlplane_ips = (
    length(local.registered_controlplane_ips) > 0
    ? local.registered_controlplane_ips
    : local.controlplane_node_ips
  )
}

# Ephemeral health gate: waits until Talos reports the control plane healthy
# (etcd, apid, kubelet) before proceeding to install Cilium. Not stored in state.
# Emergency escape hatch: `-var healthcheck_enabled=false` skips the gate (and the
# node inventory above), which is what makes `terraform destroy` possible on a
# cluster whose control plane/etcd is already broken.
ephemeral "talos_cluster_health" "talos" {
  count                  = var.healthcheck_enabled ? 1 : 0
  depends_on             = [talos_cluster.this]
  client_configuration   = talos_machine_secrets.secrets.client_configuration
  control_plane_nodes    = local.healthcheck_controlplane_ips
  endpoints              = local.healthcheck_controlplane_ips
  skip_kubernetes_checks = true
  timeout                = "15m"
}

# There is deliberately no second "kubernetes" health gate here.
#
# Talos's DefaultClusterChecks() asserts that the expected node set matches the
# cluster exactly (K8sAllNodesReportedAssertion): omitting workers fails with
# "unexpected nodes with IPs [...]", while listing a node that does not exist yet
# blocks until the timeout. There is no partial list that works, and listing the
# manual/remote workers would let them gate every apply.
#
# API readiness is covered by the Helm release below (the provider talks to the API
# and waits for the Cilium DaemonSet), and `talos_cluster` already runs the Talos
# layer checks on create. Whole-cluster verification, if wanted, belongs in CI after
# the apply — see the README (`talosctl health` must list *every* node).
