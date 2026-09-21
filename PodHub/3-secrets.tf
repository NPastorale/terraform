# Creates the "vault" namespace that holds Vault-related secrets.
# ignore_changes keeps it stable across applies once created.
resource "kubernetes_namespace_v1" "vault" {
  depends_on = [ephemeral.talos_cluster_health.kubernetes]
  metadata {
    name = "vault"
  }
  lifecycle {
    ignore_changes = all
  }
}

# Creates the "external-secrets" namespace for the External Secrets Operator + token.
resource "kubernetes_namespace_v1" "external_secrets" {
  depends_on = [ephemeral.talos_cluster_health.kubernetes]
  metadata {
    name = "external-secrets"
  }
  lifecycle {
    ignore_changes = all
  }
}

# KMS service-account credentials (GCP) used by Vault's KMS auto-unseal.
# Sourced from var.kms_service_account_base64; lives in the vault namespace.
resource "kubernetes_secret_v1" "kms_auth" {
  depends_on = [kubernetes_namespace_v1.vault]
  metadata {
    name      = "kms-auth"
    namespace = "vault"
  }
  data = {
    "sa-credentials.json" = base64decode(var.kms_service_account_base64)
  }
  type = "Opaque"
  lifecycle {
    ignore_changes = all
  }
}

# Vault token consumed by the External Secrets Operator to read secrets from Vault.
# Sourced from var.vault_token_base64; lives in the external-secrets namespace.
resource "kubernetes_secret_v1" "vault_token" {
  depends_on = [kubernetes_namespace_v1.external_secrets]
  metadata {
    name      = "vault-token"
    namespace = "external-secrets"
  }
  data = {
    "token" = base64decode(var.vault_token_base64)
  }
  type = "Opaque"
  lifecycle {
    ignore_changes = all
  }
}
