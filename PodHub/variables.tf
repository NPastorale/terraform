variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
}

variable "cluster_endpoint_host" {
  description = "The endpoint hostname for the Talos cluster"
  type        = string
}

variable "cluster_endpoint_port" {
  description = "The endpoint port for the Talos cluster"
  type        = string
}

variable "talos_version" {
  description = "The version of talos features to use"
  type        = string
}

variable "kubernetes_version" {
  description = "The version of kubernetes to use"
  type        = string
}

variable "controlplanes" {
  description = "A map of controlplane data"
  type = map(object({
    disk     = string
    hostname = string
  }))
}

variable "raspberries" {
  description = "A map of raspberries data"
  type = map(object({
    disk     = string
    hostname = string
  }))
}

variable "N100s" {
  description = "A map of N100s data"
  type = map(object({
    disk     = string
    hostname = string
  }))
  default = {}
}

variable "masita" {
  description = "A map of masita data"
  type = map(object({
    disk     = string
    hostname = string
    taints   = map(string)
    location = object({
      continent = string
      country   = string
      city      = string
    })
  }))
}

variable "porteño" {
  description = "A map of porteño data"
  type = map(object({
    disk     = string
    hostname = string
    taints   = map(string)
    location = object({
      continent = string
      country   = string
      city      = string
    })
  }))
}

variable "kms_service_account_base64" {
  description = "Base64-encoded service account JSON for KMS auth (provide as base64 string)"
  type        = string
  sensitive   = true
}

variable "vault_token_base64" {
  description = "Base64-encoded Vault token for external-secrets (provide as base64 string)"
  type        = string
  sensitive   = true
}
