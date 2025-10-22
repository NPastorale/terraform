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

Get data-created configs

```
terraform output -json porteño_config | jq -r '.[0]' | yq -y > porteño.yaml
```

Get secrets

```
terraform output -raw talos_secrets_yaml | yq -y > tfsecrets.yaml
```

```mermaid
flowchart LR
A_ArgoCD[ArgoCD]
    subgraph S100[Wave -100]
        direction TB
        A_CertManager[Cert-manager]
        A_NFS_CSI[NFS-CSI]
        A_NFS_CSI_Config[NFS-CSI-config]
        A_ExternalSecrets[External-secrets]
    end

    subgraph S90[Wave -90]
        direction TB
        B_CertManager_VaultConfig[vault-config]
        B_MetalLB[MetalLB]
    end

    subgraph S80[Wave -80]
        direction TB
        C_MetalLB_Config["metallb-config"]
        C_Ingress["Internal Ingress Controller"]
    end

    subgraph S70[Wave -70]
        direction TB
        D_Vault["Vault"]
    end

    subgraph S60[Wave -60]
        direction TB
        E_External_secrets_config["External secrets config"]
    end

    %% Connect stage groups to show flow between stages
    A_ArgoCD --> A_CertManager
    A_ArgoCD --> A_NFS_CSI
    A_ArgoCD --> A_NFS_CSI_Config
    A_ArgoCD --> A_ExternalSecrets

    A_CertManager --> B_MetalLB
    A_CertManager --> B_CertManager_VaultConfig

    B_MetalLB --> C_MetalLB_Config
    B_MetalLB --> C_Ingress

    C_Ingress --> D_Vault
    B_CertManager_VaultConfig --> D_Vault

    D_Vault --> E_External_secrets_config

    %% Optional styling for clarity
    classDef stage fill:#aaa,stroke:#333,stroke-width:1px;
    class S100,S90,S80,S70,S60 stage;
```
