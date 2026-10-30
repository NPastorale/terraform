#!/usr/bin/env bash
#
# import-secrets.sh
#
# Imports an existing Talos secrets YAML into the REAL local Terraform state
# (terraform.tfstate in this directory) WITHOUT touching any existing .tf files
# and WITHOUT evaluating the `ephemeral "talos_cluster_health"` gates (which block
# forever because the cluster does not exist yet).
#
# How it works:
#   - Creates a throwaway config in a temp dir whose `local` backend points at the
#     SAME state file as this module (PodHub/terraform.tfstate).
#   - That temp config contains ONLY the talos provider + the
#     `talos_machine_secrets.secrets` resource, so no cluster connection / health
#     check is ever evaluated.
#   - Runs `terraform import` there -> the resource lands directly in the real state.
#   - Removes the temp dir. No .tf files are modified; only terraform.tfstate is updated.
#
# Usage:
#   ./import-secrets.sh /path/to/secrets.yml [talos_version]
#
# The machine-config contract version is taken from the 2nd argument (defaults to
# v1.14.4). Keep it equal to `talos_version` in terraform.tfvars. The import records
# the secrets-file format version; the next plan bumps it to this value without
# rotating certificates.
#
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <path-to-secrets.yml> [talos_version]" >&2
  exit 2
fi

SECRETS_FILE="${1}"
TALOS_VERSION="${2:-}"
[[ -f "${SECRETS_FILE}" ]] || { echo "error: secrets file not found: ${SECRETS_FILE}" >&2; exit 1; }
SECRETS_FILE="$(cd "$(dirname "${SECRETS_FILE}")" && pwd)/$(basename "${SECRETS_FILE}")"

PODHUB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${PODHUB}/terraform.tfstate"

TMP="$(mktemp -d)"
cleanup() { rm -rf "${TMP}"; }
trap cleanup EXIT INT TERM

cat > "${TMP}/main.tf" <<EOF
terraform {
  backend "local" {
    path = "${STATE_FILE}"
  }
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0"
    }
  }
}

provider "talos" {}

resource "talos_machine_secrets" "secrets" {
  talos_version = "${TALOS_VERSION:-v1.14}"
}
EOF

echo ">> Importing ${SECRETS_FILE} into ${STATE_FILE}"
echo ">> (temp config at ${TMP})"
(
  cd "${TMP}"
  terraform init -input=false
  terraform import "talos_machine_secrets.secrets" "${SECRETS_FILE}"
)

echo ">> Done. Temp dir removed; terraform.tfstate updated."
