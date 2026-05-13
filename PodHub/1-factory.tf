locals {
  # System extensions required by ALL nodes regardless of architecture but only used for worker nodes
  common-extensions = [
    "siderolabs/iscsi-tools"
  ]

  # Extensions for control plane nodes
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

}

data "talos_image_factory_extensions_versions" "controlplane" {
  count         = length(local.controlplane-extensions) > 0 ? 1 : 0
  talos_version = var.talos_version
  exact_filters = {
    names = local.controlplane-extensions
  }
}

resource "talos_image_factory_schematic" "controlplane" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = length(local.controlplane-extensions) > 0 ? data.talos_image_factory_extensions_versions.controlplane[0].extensions_info.*.name : []
      }
    }
  })
}


data "talos_image_factory_extensions_versions" "x86_intel" {
  count         = length(local.x86-intel-extensions) > 0 ? 1 : 0
  talos_version = var.talos_version
  exact_filters = {
    names = concat(local.common-extensions, local.x86-intel-extensions)
  }
}

resource "talos_image_factory_schematic" "x86_intel" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = length(local.x86-intel-extensions) > 0 ? data.talos_image_factory_extensions_versions.x86_intel[0].extensions_info.*.name : []
      }
    }
  })
}

data "talos_image_factory_extensions_versions" "x86_nvidia" {
  count         = length(local.x86-nvidia-extensions) > 0 ? 1 : 0
  talos_version = var.talos_version
  exact_filters = {
    names = concat(local.common-extensions, local.x86-nvidia-extensions)
  }
}

resource "talos_image_factory_schematic" "x86_nvidia" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = length(local.x86-nvidia-extensions) > 0 ? data.talos_image_factory_extensions_versions.x86_nvidia[0].extensions_info.*.name : []
      }
    }
  })
}

data "talos_image_factory_extensions_versions" "arm64_generic" {
  count         = length(local.arm64-generic-extensions) > 0 ? 1 : 0
  talos_version = var.talos_version
  exact_filters = {
    names = concat(local.common-extensions, local.arm64-generic-extensions)
  }
}

resource "talos_image_factory_schematic" "arm64_generic" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = length(local.arm64-generic-extensions) > 0 ? data.talos_image_factory_extensions_versions.arm64_generic[0].extensions_info.*.name : []
      }
    }
  })
}

data "talos_image_factory_extensions_versions" "arm64_rpi" {
  count         = length(local.arm64-rpi-extensions) > 0 ? 1 : 0
  talos_version = var.talos_version
  exact_filters = {
    names = concat(local.common-extensions, local.arm64-rpi-extensions)
  }
}

data "talos_image_factory_overlays_versions" "arm64_rpi" {
  talos_version = var.talos_version
  filters = {
    name = "rpi_generic"
  }
}

resource "talos_image_factory_schematic" "arm64_rpi" {
  schematic = yamlencode({
    overlay = {
      image = data.talos_image_factory_overlays_versions.arm64_rpi.overlays_info[0].image
      name  = data.talos_image_factory_overlays_versions.arm64_rpi.overlays_info[0].name
    }
    customization = {
      systemExtensions = {
        officialExtensions = length(local.arm64-rpi-extensions) > 0 ? data.talos_image_factory_extensions_versions.arm64_rpi[0].extensions_info.*.name : []
      }
    }
  })
}

locals {
  # Maps each node role/architecture variant to its schematic ID from the Talos Image Factory
  architecture_to_schematic = {
    controlplane  = talos_image_factory_schematic.controlplane.id
    x86_intel     = talos_image_factory_schematic.x86_intel.id
    x86_nvidia    = talos_image_factory_schematic.x86_nvidia.id
    arm64_generic = talos_image_factory_schematic.arm64_generic.id
    arm64_rpi     = talos_image_factory_schematic.arm64_rpi.id
  }
}
