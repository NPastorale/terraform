cluster_name          = "podhub"
cluster_endpoint_host = "podhub.nahue.ar"
cluster_endpoint_port = "6443"
talos_version         = "v1.7.5"
kubernetes_version    = "v1.30.2"

controlplanes = {
  "10.10.20.11" = {
    disk     = "/dev/mmcblk0"
    hostname = "absolute-overlord-1"
  },
  "10.10.20.12" = {
    disk     = "/dev/mmcblk0"
    hostname = "absolute-overlord-2"
  },
  "10.10.20.13" = {
    disk     = "/dev/mmcblk0"
    hostname = "absolute-overlord-3"
  }
}

raspberries = {
  "10.10.20.21" = {
    disk     = "/dev/mmcblk0"
    hostname = "abysmal-underling-1"
  },
  "10.10.20.22" = {
    disk     = "/dev/mmcblk0"
    hostname = "abysmal-underling-2"
  }
}

N100s = {
  "10.10.20.31" = {
    disk     = "/dev/sda"
    hostname = "xenial-underling-1"
  },
  "10.10.20.32" = {
    disk     = "/dev/sda"
    hostname = "xenial-underling-2"
  }
}

masita = {
  "192.168.100.48" = {
    disk     = "/dev/mmcblk0"
    hostname = "macabre-underling-1"
    taints = {
      "location" = "Argentina:NoSchedule"
    }
    location = {
      continent = "SA"
      country   = "AR"
      city      = "Rosario"
    }
  }
}
