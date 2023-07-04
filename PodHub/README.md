# Instructions

After running `terraform apply`, run the following to export the kubectl and talosctl configuration

```
terraform output -raw kubeconfig > /home/$(whoami)/.kube/config
terraform output -raw talosconfig > /home/$(whoami)/.talos/config
```

# Cheat sheet

Reset nodes to maintenance mode

```
talosctl reset \
    --system-labels-to-wipe STATE \
    --system-labels-to-wipe EPHEMERAL \
    --reboot=true \
    --graceful=false \
    -n $(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | tr ' ' ',')
```

Delete all resources from Terraform's state

```

terraform state rm $(terraform state list)

```
