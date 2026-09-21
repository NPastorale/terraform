# Talos Image Factory definitions. Talos is immutable, so any kernel modules /
# system extensions (GPU drivers, iSCSI, firmware) must be baked into a custom
# installer image per node architecture. Each schematic below pins a set of
# extensions; its ID is later embedded in the per-node install patch.
#
# Schematics are keyed by "<architecture>-<role>" so that control plane nodes
# on a given architecture get both the architecture-specific extensions/overlays
# AND any control-plane-only extensions, while workers get the architecture
# extensions plus common worker extensions (e.g. iscsi-tools).

locals {
  # System extensions required by ALL worker nodes regardless of architecture
  common-extensions = [
    "siderolabs/iscsi-tools"
  ]

  # Extensions for control plane nodes (applied on top of architecture extensions)
  controlplane-extensions = []

  # Extensions for x86 Intel nodes (no dedicated GPU)
  x86-intel-extensions = [
    "siderolabs/i915",
    "siderolabs/intel-ucode"
  ]

  # Extensions for x86 nodes with NVIDIA GPUs
  x86-nvidia-extensions = [
    "siderolabs/i915",
    "siderolabs/intel-ucode",
    "siderolabs/nvidia-container-toolkit-production",
    "siderolabs/nonfree-kmod-nvidia-production"
  ]

  # Extensions for generic ARM64 nodes
  arm64-generic-extensions = []

  # Extensions for Raspberry Pi ARM64 nodes
  arm64-rpi-extensions = []

  # ---------------------------------------------------------------------------
  # Data-driven schematic definitions
  # ---------------------------------------------------------------------------

  # Extensions per architecture
  arch_extensions = {
    arm64_rpi     = local.arm64-rpi-extensions
    x86_intel     = local.x86-intel-extensions
    x86_nvidia    = local.x86-nvidia-extensions
    arm64_generic = local.arm64-generic-extensions
  }

  # Extensions per role (added on top of architecture extensions)
  role_extensions = {
    controlplane = local.controlplane-extensions
    worker       = local.common-extensions
  }

  # Overlay per architecture (nil if no overlay needed)
  arch_overlays = {
    arm64_rpi = "rpi_generic"
  }

  # Generate all architecture × role combinations
  schematics = {
    for combo in setproduct(keys(local.arch_extensions), keys(local.role_extensions)) :
    "${combo[0]}-${combo[1]}" => {
      extensions = concat(local.arch_extensions[combo[0]], local.role_extensions[combo[1]])
      overlay    = lookup(local.arch_overlays, combo[0], null)
    }
  }
}

# Resolve overlays once per architecture that needs one
data "talos_image_factory_overlays_versions" "this" {
  for_each      = toset([for k, v in local.schematics : v.overlay if v.overlay != null])
  talos_version = var.talos_version
  filters = {
    name = each.key
  }
}

# Resolve extension versions for combinations that have extensions
data "talos_image_factory_extensions_versions" "this" {
  for_each      = { for k, v in local.schematics : k => v if length(v.extensions) > 0 }
  talos_version = var.talos_version
  exact_filters = {
    names = each.value.extensions
  }
}

# Create one schematic per architecture × role combination
resource "talos_image_factory_schematic" "this" {
  for_each = local.schematics
  schematic = yamlencode({
    overlay = each.value.overlay != null ? {
      image = data.talos_image_factory_overlays_versions.this[each.value.overlay].overlays_info[0].image
      name  = data.talos_image_factory_overlays_versions.this[each.value.overlay].overlays_info[0].name
    } : null
    customization = {
      systemExtensions = {
        officialExtensions = try(data.talos_image_factory_extensions_versions.this[each.key].extensions_info.*.name, [])
      }
    }
  })
}

# Lookup table: "<architecture>-<role>" -> schematic ID
locals {
  architecture_role_to_schematic = {
    for k, v in talos_image_factory_schematic.this : k => v.id
  }
}
