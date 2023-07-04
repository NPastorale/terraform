cluster_name          = "podhub"
cluster_endpoint_host = "podhub.nahue.ar"
cluster_endpoint_port = "6443"
talos_version         = "v1.4.6"
kubernetes_version    = "v1.27.3"

controlplanes = {
  "192.168.1.11" = {
    disk     = "/dev/mmcblk0"
    hostname = "absolute-overlord-1"
  },
  "192.168.1.12" = {
    disk     = "/dev/mmcblk0"
    hostname = "absolute-overlord-2"
  },
  "192.168.1.13" = {
    disk     = "/dev/mmcblk0"
    hostname = "absolute-overlord-3"
  }
}

raspberries = {
  "192.168.1.14" = {
    disk     = "/dev/mmcblk0"
    hostname = "abysmal-underling-1"
  },
  "192.168.1.15" = {
    disk     = "/dev/mmcblk0"
    hostname = "abysmal-underling-2"
  }
}

N100s = {
  # "192.168.1.30" = {
  #   disk     = "/dev/sda"
  #   hostname = "xenial-underling-1"
  # },
  "192.168.1.31" = {
    disk     = "/dev/sda"
    hostname = "xenial-underling-2"
  }
}
