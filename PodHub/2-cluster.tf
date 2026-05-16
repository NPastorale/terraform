resource "talos_machine_configuration_apply" "all" {
  for_each                    = var.nodes
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  machine_configuration_input = local.node_config[each.key].machine_type
  node                        = each.key
  on_destroy = {
    graceful = false
    reboot   = true
    reset    = true
  }
  config_patches = local.per_node_patches[each.key]
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.all]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = local.first_controlplane_ip
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = local.first_controlplane_ip
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

ephemeral "talos_cluster_health" "talos" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  control_plane_nodes  = local.controlplane_node_ips
  endpoints            = local.controlplane_node_ips
  health_check_level   = "k8s"
  worker_nodes         = local.worker_node_ips
}

ephemeral "talos_cluster_health" "kubernetes" {
  depends_on           = [helm_release.cilium]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  control_plane_nodes  = local.controlplane_node_ips
  endpoints            = local.controlplane_node_ips
  worker_nodes         = local.worker_node_ips
}
