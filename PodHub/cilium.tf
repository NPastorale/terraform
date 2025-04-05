resource "helm_release" "cilium" {
  depends_on = [data.talos_cluster_health.talos]
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  version    = "1.17.2"
  chart      = "cilium"
  namespace  = "kube-system"
  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }
  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }
  set_list {
    name  = "securityContext.capabilities.ciliumAgent"
    value = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
  }
  set_list {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
  }
  set {
    name  = "cgroup.autoMount.enabled"
    value = "false"
  }
  set {
    name  = "cgroup.hostRoot"
    value = "/sys/fs/cgroup"
  }
  set {
    name  = "k8sServiceHost"
    value = "localhost" #Set to localhost if KubePrism is enabled, var.cluster_endpoint_host otherwise
  }
  set {
    name  = "k8sServicePort"
    value = 7445 #Set to 7445 if KubePrism is enabled, var.cluster_endpoint_port otherwise
  }
  set {
    name  = "clustermesh.apiserver.tls.auto.enabled"
    value = "false"
  }

  set {
    name  = "hubble.tls.auto.enabled"
    value = "false"
  }
  set {
    name  = "tls.ca.cert"
    value = base64encode(tls_self_signed_cert.ca_cert.cert_pem)
  }
  set {
    name  = "hubble.tls.server.cert"
    value = base64encode(tls_locally_signed_cert.server_cert.cert_pem)
  }
  set {
    name  = "hubble.tls.server.key"
    value = base64encode(tls_private_key.server_key.private_key_pem)
  }
}
