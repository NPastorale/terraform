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
  description = "Talos machine-config *contract* version. Pin this to the Talos version the cluster was created with and do NOT bump it during OS upgrades; it only defines which config schema/defaults are generated. See talos_machine_configuration.talos_version in the provider docs."
  type        = string
}

variable "talos_installer_version" {
  description = "Talos OS version to install / upgrade to. Drives the installer image tag and the Image Factory lookups. This is the knob you bump for Talos OS upgrades (and the only one, for patch releases)."
  type        = string

  validation {
    condition     = can(regex("^v?[0-9]+\\.[0-9]+\\.[0-9]+$", var.talos_installer_version))
    error_message = "talos_installer_version must look like v1.14.4."
  }
}

variable "kubernetes_version" {
  description = "The version of kubernetes to use"
  type        = string
}

variable "drain_on_upgrade" {
  description = "Cordon and drain a node before rebooting it for a Talos OS upgrade (config-only changes never drain). Requires a reachable Kubernetes API. Set to false only when the API is unavailable and Talos still has to be upgraded."
  type        = bool
  default     = true
}

variable "write_talosconfig" {
  description = "Write the generated talosconfig to <module>/talosconfig on apply (mode 0600). The file is removed again by terraform destroy; regenerate it from secrets.yaml if needed."
  type        = bool
  default     = false
}

variable "healthcheck_enabled" {
  description = "Enable the Talos health gate that waits for the control plane before installing Cilium. Set to false only as an emergency escape hatch: it skips the gate and the Kubernetes node inventory, which lets you plan/apply against, or destroy, a cluster whose control plane is unhealthy."
  type        = bool
  default     = true
}

variable "nodes" {
  description = "All cluster nodes unified. Role determines patches, architecture determines image schematic. Set manual=true to only generate machine config (outputs) without provisioning via talos_machine.all / cluster bootstrap / health checks. protected=true (requires manual=true) manages the node with talos_machine.protected for config and OS upgrades, but its Delete is a no-op: on destroy Terraform never resets, wipes or reboots it. Protected nodes are excluded from talos_machine.all, bootstrap and the health gate."
  type = map(object({
    role         = string
    architecture = string
    disk         = string
    hostname     = string
    labels       = optional(map(string), {})
    taints       = optional(map(string), {})
    manual       = optional(bool, false)
    protected    = optional(bool, false)
  }))

  validation {
    condition     = length([for k, v in var.nodes : k if v.role == "controlplane" && coalesce(v.manual, false) == false && coalesce(v.protected, false) == false]) > 0
    error_message = "At least one controlplane node with manual=false is required to bootstrap the cluster (first_controlplane_ip)."
  }

  validation {
    condition     = alltrue([for k, v in var.nodes : !coalesce(v.protected, false) || coalesce(v.manual, false)])
    error_message = "protected = true requires manual = true. A protected node must never be applied, reset or wiped by Terraform (e.g. the ARG nodes, which have no physical access)."
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
