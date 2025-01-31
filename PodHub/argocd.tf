data "helm_template" "argocd" {
  name         = "argocd"
  repository   = "https://argoproj.github.io/argo-helm"
  kube_version = var.kubernetes_version
  version      = "7.3.11"
  chart        = "argo-cd"
  namespace    = "argocd"
}
