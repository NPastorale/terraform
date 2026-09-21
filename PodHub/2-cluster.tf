# Manages each auto-provisioned Talos node: applies machine configuration and keeps the OS version in sync.
# On destroy it resets/reboots the machines so the metal can be re-provisioned cleanly.
# Nodes with manual=true are excluded here — their configs are rendered by
# data.talos_machine_configuration.this but only exposed via outputs for manual `talosctl apply-config`.
resource "talos_machine" "all" {
  for_each                        = local.auto_nodes
  node                            = each.key
  client_configuration            = talos_machine_secrets.secrets.client_configuration
  machine_configuration           = data.talos_machine_configuration.this[each.key].machine_configuration
  image                           = local.node_image[each.key]
  drain_on_upgrade                = false
  ignore_kubernetes_upgrade_drift = true
  on_destroy = {
    graceful = false
    reboot   = true
    reset    = true
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

# Fetches the admin kubeconfig for the now-bootstrapped cluster. Its decoded
# contents feed the helm/kubernetes/argocd providers (local.kubernetes_client_config).
resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_cluster.this]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = var.cluster_endpoint_host
}

locals {
  # Decoded Kubernetes client configuration for use by Terraform providers
  # The raw kubeconfig contains base64-encoded certs; this decodes them into plain PEM
  # so they can be consumed directly by provider blocks without additional decoding
  kubernetes_client_config = {
    host                   = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
    client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  }
}

# Ephemeral health gate: waits until Talos reports the cluster healthy
# (control-plane + workers) before proceeding to install Cilium. Not stored in state.
ephemeral "talos_cluster_health" "talos" {
  depends_on             = [talos_cluster.this]
  client_configuration   = talos_machine_secrets.secrets.client_configuration
  control_plane_nodes    = local.controlplane_node_ips
  endpoints              = local.controlplane_node_ips
  skip_kubernetes_checks = true
  # worker_nodes           = local.worker_node_ips
}

# Second ephemeral health gate: re-checks cluster health after Cilium is up,
# gating the namespace/secret/ArgoCD resources that follow.
ephemeral "talos_cluster_health" "kubernetes" {
  depends_on           = [helm_release.cilium]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  control_plane_nodes  = local.controlplane_node_ips
  endpoints            = local.controlplane_node_ips
  worker_nodes         = local.worker_node_ips
  timeout              = "10s"
}
