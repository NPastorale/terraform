resource "helm_release" "argocd" {
  depends_on       = [data.talos_cluster_health.kubernetes]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = "8.6.1"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 1800
  values = [
    yamlencode({
      configs = {
        cm = {
          "resource.customizations.health.argoproj.io_Application" = <<-EOT
            hs = {}
            hs.status = "Progressing"
            hs.message = ""
            if obj.status ~= nil then
              if obj.status.health ~= nil then
                hs.status = obj.status.health.status
                if obj.status.health.message ~= nil then
                  hs.message = obj.status.health.message
                end
                local syncStatus = (obj.status.sync and obj.status.sync.status or nil)
                if hs.status == "Healthy" and syncStatus ~= "Synced" then
                  hs.status = "Progressing"
                end
              end
            end
            return hs
          EOT
        }
      }
    })
  ]
}


resource "argocd_application" "app_of_apps" {
  depends_on = [helm_release.argocd]

  metadata {
    name      = "app-of-apps"
    namespace = "argocd"
  }

  spec {
    destination {
      namespace = "argocd"
      server    = "https://kubernetes.default.svc"
    }

    project = "default"

    source {
      path            = "argocd"
      repo_url        = "https://github.com/NPastorale/kubernetes"
      target_revision = "feature/cluster-bootstrap"
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }
      sync_options = ["CreateNamespace=true", "ApplyOutOfSyncOnly=true"]
      retry {
        limit = 10
      }
    }
  }
}
