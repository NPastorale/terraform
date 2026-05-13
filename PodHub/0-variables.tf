variable "cluster_name" {
  description = "The name of the Talos cluster"
  type        = string
}

variable "cluster_endpoint_host" {
  description = "The endpoint hostname for the Talos cluster"
  type        = string
}

variable "cluster_vip_ip" {
  description = "The VIP IP for the Talos cluster Layer 2 VIP"
  type        = string
  default     = null
}

variable "cluster_endpoint_port" {
  description = "The endpoint port for the Talos cluster"
  type        = string
  default     = "6443"
}

variable "talos_version" {
  description = "The version of talos features to use"
  type        = string
}

variable "kubernetes_version" {
  description = "The version of kubernetes to use"
  type        = string
}

variable "nodes" {
  description = "All cluster nodes unified. Role determines patches, architecture determines image schematic."
  type = map(object({
    role         = string
    architecture = string
    disk         = string
    hostname     = string
    labels       = optional(map(string), {})
    taints       = optional(map(string), {})
  }))
}

variable "kms_service_account_base64" {
  description = "Base64 encoded KMS service account key file"
  type        = string
  sensitive   = true
}

variable "vault_token_base64" {
  description = "Base64 encoded Vault token"
  type        = string
  sensitive   = true
}
