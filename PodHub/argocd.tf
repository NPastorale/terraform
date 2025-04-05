resource "helm_release" "argocd" {
  depends_on       = [data.talos_cluster_health.kubernetes]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = "7.8.23"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
}
