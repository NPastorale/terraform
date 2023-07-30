# Terraform scripts

This repository is intended to contain all the Terraform scripts that compose my infra.

## GitHub

This manages GitHub repos with some (definitely) sane defaults. It accepts the personalization of some common values for repositories, as well as secrets and variables to be utilized with GitHub Actions.

## PodHub

Administers the creation and update of a [Talos](https://www.talos.dev/) cluster. It is capable of bootsptrapping the cluster starting from just one or more machines running Talos in maintenance mode.
Additionally it also bootstraps [Cilium](https://cilium.io/) as a CNI and adds the necessary extentions to utilize Intel iGPUs.
Finally, it outputs the `kubeconfig` and `talosconfig` needed for manual administration of the cluster once provisioned.
