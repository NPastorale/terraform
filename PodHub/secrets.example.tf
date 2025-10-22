resource "kubernetes_namespace" "vault" {
  depends_on = [data.talos_cluster_health.kubernetes]
  metadata {
    name = "vault"
  }
}

resource "kubernetes_secret" "kms_auth" {
  depends_on = [kubernetes_namespace.vault]
  metadata {
    name      = "kms-auth"
    namespace = "vault"
  }
  data = {
    "sa-credentials.json" = base64decode("BASE64_ENCODED_SERVICE_ACCOUNT_JSON")
  }
  type = "Opaque"
}


resource "kubernetes_namespace" "external-secrets" {
  depends_on = [data.talos_cluster_health.kubernetes]
  metadata {
    name = "external-secrets"
  }
}

resource "kubernetes_secret" "vault-token" {
  depends_on = [kubernetes_namespace.external-secrets]
  metadata {
    name      = "vault-token"
    namespace = "external-secrets"
  }
  data = {
    "token" = base64decode("BASE64_ENCODED_VAULT_TOKEN")
  }
  type = "Opaque"
}
