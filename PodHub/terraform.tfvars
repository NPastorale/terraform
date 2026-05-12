cluster_name          = "PodHub"
cluster_endpoint_host = "192.168.64.15"
cluster_endpoint_port = "6443"
talos_version         = "v1.12.4"
kubernetes_version    = "v1.35.3"

controlplanes = {
  "192.168.64.15" = {
    disk     = "/dev/vda"
    hostname = "absolute-overlord-1"
    location = {
      region = "ESP"
      zone   = "Barcelona"
    }
  }
}

# raspberries = {
# "192.168.64.14" = {
#   disk     = "/dev/vda"
#   hostname = "abysmal-underling-1"
#   location = {
#     region = "ESP"
#     zone   = "Barcelona"
#   }
# }
# }

N100s = {
  "192.168.64.16" = {
    disk     = "/dev/vda"
    hostname = "abysmal-underling-1"
    location = {
      region = "ESP"
      zone   = "Barcelona"
    }
  }
}

# masita = {
#   "192.168.100.181" = {
#     disk     = "/dev/mmcblk0"
#     hostname = "macabre-underling-1"
#     taints = {
#       "region" = "ARG:NoSchedule"
#     }
#     location = {
#       region = "ARG"
#       zone   = "Rosario"
#     }
#   }
# }

# porteño = {
#   "192.168.0.100" = {
#     disk     = "/dev/mmcblk0"
#     hostname = "chaotic-underling-1"
#     taints = {
#       "region" = "ARG:NoSchedule"
#     }
#     location = {
#       region = "ARG"
#       zone   = "CABA"
#     }
#   }
# }
