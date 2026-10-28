terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {}

# ---------------------------------------------------------------------------
# Billing
# ---------------------------------------------------------------------------

data "google_billing_account" "revolut" {
  display_name = "Revolut"
  open         = true
}

# ---------------------------------------------------------------------------
# Project
# ---------------------------------------------------------------------------

resource "google_project" "podhub" {
  name            = "Test project"
  project_id      = "test-project-12348762678"
  billing_account = data.google_billing_account.revolut.id
  deletion_policy = "DELETE"
}

# ---------------------------------------------------------------------------
# Cloud KMS API
# ---------------------------------------------------------------------------

resource "google_project_service" "cloudkms" {
  project            = google_project.podhub.project_id
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = true
}

# ---------------------------------------------------------------------------
# KMS Key Ring
# ---------------------------------------------------------------------------

resource "google_kms_key_ring" "vault" {
  project  = google_project.podhub.project_id
  name     = "vault"
  location = "europe-southwest1"

  depends_on = [
    google_project_service.cloudkms
  ]
}

# ---------------------------------------------------------------------------
# KMS Crypto Key used for Vault auto-unseal
# ---------------------------------------------------------------------------

resource "google_kms_crypto_key" "vault" {
  name            = "vault-auto-unseal"
  key_ring        = google_kms_key_ring.vault.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Service Account used by Vault
# ---------------------------------------------------------------------------

resource "google_service_account" "vault" {
  project = google_project.podhub.project_id

  account_id   = "vault-kms"
  display_name = "Vault Auto Unseal"
}

# ---------------------------------------------------------------------------
# Give Vault access to the KMS key
# ---------------------------------------------------------------------------

resource "google_kms_crypto_key_iam_member" "vault_encrypter_decrypter" {
  crypto_key_id = google_kms_crypto_key.vault.id

  role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member = google_service_account.vault.member
}

resource "google_kms_crypto_key_iam_member" "vault_viewer" {
  crypto_key_id = google_kms_crypto_key.vault.id

  role   = "roles/cloudkms.viewer"
  member = google_service_account.vault.member
}

# ---------------------------------------------------------------------------
# Service Account credentials
# ---------------------------------------------------------------------------

resource "google_service_account_key" "vault" {
  service_account_id = google_service_account.vault.name
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "vault_kms_config" {
  value = {
    project    = google_project.podhub.project_id
    region     = google_kms_key_ring.vault.location
    key_ring   = google_kms_key_ring.vault.name
    crypto_key = google_kms_crypto_key.vault.name
  }
}

output "vault_service_account_email" {
  value = google_service_account.vault.email
}

output "vault_service_account_credentials" {
  value     = base64decode(google_service_account_key.vault.private_key)
  sensitive = true
}
