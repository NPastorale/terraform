resource "helm_release" "cilium" {
  depends_on = [data.talos_cluster_health.talos]
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  version    = "1.18.2"
  chart      = "cilium"
  namespace  = "kube-system"
  timeout    = 1800
  set = [{
    name  = "ipam.mode"
    value = "kubernetes"
    },
    {
      name  = "kubeProxyReplacement"
      value = "true"
      }, {
      name  = "cgroup.autoMount.enabled"
      value = "false"
      }, {
      name  = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
      }, {
      name  = "k8sServiceHost"
      value = "localhost" #Set to localhost if KubePrism is enabled, var.cluster_endpoint_host otherwise
      }, {
      name  = "k8sServicePort"
      value = 7445 #Set to 7445 if KubePrism is enabled, var.cluster_endpoint_port otherwise
      }, {
      name  = "clustermesh.apiserver.tls.auto.enabled"
      value = "false"
      }, {
      name  = "hubble.tls.auto.enabled"
      value = "false"
      }, {
      name  = "tls.ca.cert"
      value = base64encode(tls_self_signed_cert.ca_cert.cert_pem)
      }, {
      name  = "hubble.tls.server.cert"
      value = base64encode(tls_locally_signed_cert.server_cert.cert_pem)
      }, {
      name  = "hubble.tls.server.key"
      value = base64encode(tls_private_key.server_key.private_key_pem)
    },
    # NETKIT specific settings
    {
      name  = "bpf.datapathMode"
      value = "netkit"
      }, {
      name  = "bpf.masquerade"
      value = "true"
      }, {
      name  = "bpf.distributedLRU.enabled"
      value = "true"
      }, {
      name  = "bpfClockProbe"
      value = "true"
    }
    # End of NETKIT specific settings
  ]

  set_list = [{
    name  = "securityContext.capabilities.ciliumAgent"
    value = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
    }, {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
  }]
}
