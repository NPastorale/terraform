cluster_name          = "PodHub"
cluster_endpoint_host = "podhub.nahue.ar"
cluster_endpoint_port = "6443"
talos_version         = "v1.12.6"
kubernetes_version    = "v1.35.3"

controlplanes = {
  "10.10.20.11" = {
    disk     = "/dev/mmcblk0"
    hostname = "absolute-overlord-1"
    location = {
      region = "ESP"
      zone   = "Barcelona"
    }
  },
  "10.10.20.12" = {
    disk     = "/dev/mmcblk0"
    hostname = "absolute-overlord-2"
    location = {
      region = "ESP"
      zone   = "Barcelona"
    }
  },
  "10.10.20.13" = {
    disk     = "/dev/mmcblk0"
    hostname = "absolute-overlord-3"
    location = {
      region = "ESP"
      zone   = "Barcelona"
    }
  }
}

raspberries = {
  "10.10.20.21" = {
    disk     = "/dev/mmcblk0"
    hostname = "abysmal-underling-1"
    location = {
      region = "ESP"
      zone   = "Barcelona"
    }
  },
  "10.10.20.22" = {
    disk     = "/dev/mmcblk0"
    hostname = "abysmal-underling-2"
    location = {
      region = "ESP"
      zone   = "Barcelona"
    }
  }
}

N100s = {
  # "10.10.20.31" = {
  #   disk     = "/dev/sda"
  #   hostname = "xenial-underling-1"
  # },
  # "10.10.20.32" = {
  #   disk     = "/dev/sda"
  #   hostname = "xenial-underling-2"
  # }
}

masita = {
  "192.168.100.181" = {
    disk     = "/dev/mmcblk0"
    hostname = "macabre-underling-1"
    taints = {
      "region" = "ARG:NoSchedule"
    }
    location = {
      region = "ARG"
      zone   = "Rosario"
    }
  }
}

porteño = {
  "192.168.0.100" = {
    disk     = "/dev/mmcblk0"
    hostname = "chaotic-underling-1"
    taints = {
      "region" = "ARG:NoSchedule"
    }
    location = {
      region = "ARG"
      zone   = "CABA"
    }
  }
}
