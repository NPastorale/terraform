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

variable "cluster_vip_link" {
  description = "The primary network interface (link) for the Talos cluster Layer 2 VIP, e.g. end0/eth0. Must match exactly one link on each control plane node. Required only when cluster_vip_ip is set."
  type        = string
  default     = null
  validation {
    condition     = (var.cluster_vip_ip == null) == (var.cluster_vip_link == null)
    error_message = "cluster_vip_ip and cluster_vip_link must be set together: either both provided or both omitted."
  }
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
  description = "All cluster nodes unified. Role determines patches, architecture determines image schematic. Set manual=true to only generate machine config (outputs) without provisioning via talos_machine / cluster bootstrap / health checks."
  type = map(object({
    role         = string
    architecture = string
    disk         = string
    hostname     = string
    labels       = optional(map(string), {})
    taints       = optional(map(string), {})
    manual       = optional(bool, false)
  }))

  validation {
    condition     = length([for k, v in var.nodes : k if v.role == "controlplane" && coalesce(v.manual, false) == false]) > 0
    error_message = "At least one controlplane node with manual=false is required to bootstrap the cluster (first_controlplane_ip)."
  }
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
