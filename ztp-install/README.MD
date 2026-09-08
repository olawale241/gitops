# OpenShift ZTP with ACM + Argo CD

This repository provides the **Day-1 OpenShift Zero Touch Provisioning (ZTP)** configuration for deploying OpenShift clusters through ACM.

The design uses:

* ACM on the Hub
* Argo CD on the ACM Hub to initiate ZTP
* Agent-based OpenShift installation
* BareMetalHost
* NMState
* Vault Secrets Operator
* OpenShift GitOps / Argo CD on the spoke

## Architecture

```text
ACM HUB
  │
  │ Hub Argo CD
  ▼
ztp-install
  │
  ├── AgentClusterInstall
  ├── InfraEnv
  ├── ClusterDeployment
  ├── ManagedCluster
  ├── KlusterletAddonConfig
  ├── BareMetalHosts
  ├── NMStateConfig
  └── Vault provisioning secrets
          │
          ▼
       OpenShift
        ztp3
          │
          │ Day-2 bootstrap
          ▼
     Spoke Argo CD
          │
          ▼
    cluster-config repo
          │
          ▼
       Day-2
```

## Repository Structure

```text
ztp-install/
├── baremetalhost/
│   ├── control-plane/
│   │   ├── master-0.yaml
│   │   ├── master-1.yaml
│   │   └── master-2.yaml
│   └── workers/
│       ├── worker-0.yaml
│       ├── worker-1.yaml
│       └── worker-2.yaml
│
├── base/
│   ├── cluster/
│   ├── secrets/
│   └── extra-manifests/
│
└── overlays/
    └── ztp3/
        ├── kustomization.yaml
        ├── namespace.yaml
        ├── cluster-patch.yaml
        ├── nmstate/
        └── node patches
```

## Deployment Flow

The ACM Hub Argo CD application points to:

```text
ztp-install/overlays/ztp3
```

Argo CD applies the ZTP manifests to the ACM Hub.

ACM then provisions the `ztp3` cluster using the Agent-based Installer.

Once the spoke is installed, the extra manifests bootstrap:

1. OpenShift GitOps
2. Vault Secrets Operator
3. Vault authentication
4. The Day-2 Argo CD repository Secret
5. The Day-2 Argo CD Application

The spoke Argo CD then takes ownership of the Day-2 configuration.

## Vault

Vault is used for secrets rather than storing credentials directly in Git.

### ZTP provisioning secrets

```text
acm/ztp3/pull-secret
acm/ztp3/bmc
```

These are synchronized by Vault Secrets Operator into the `ztp3` namespace.

The resulting Kubernetes Secrets are:

```text
pull-secret
bmc-credentials
```

### Day-2 Git repository

The spoke uses:

```text
acm/ztp3/day2/git
```

to create the Argo CD repository Secret:

```text
cluster-config-repository
```

This allows the spoke Argo CD to authenticate to the Day-2 Git repository without storing Git credentials in the ZTP repository.

## Ownership Model

### ACM Hub

ACM owns the **Day-1 lifecycle**:

```text
Cluster creation
BareMetalHost
InfraEnv
AgentClusterInstall
NMState
ManagedCluster
Klusterlet
```

### Spoke Argo CD

The spoke owns **Day-2 configuration**:

```text
Operators
Operator configuration
Applications
Policies
Network configuration
Storage configuration
Monitoring
Logging
Other cluster configuration
```

The Hub does **not** manage the Day-2 ApplicationSet.

## Deploy

From the ACM Hub:

```bash
oc apply -k overlays/ztp3
```

Validate the rendered manifests before applying:

```bash
oc kustomize overlays/ztp3
```

## Cluster Customization

Cluster-specific values are maintained under:

```text
overlays/ztp3/
```

This includes:

* Cluster name
* Base domain
* BMC addresses
* Boot MAC addresses
* NMState configuration
* Node-specific configuration

The base configuration remains reusable for additional clusters.

## Design Principle

The overall lifecycle is intentionally split:

```text
             DAY 1
        ────────────────
        ACM Hub Argo CD
               │
               ▼
        ACM / Agent Install
               │
               ▼
             Spoke
               │
        ────────────────
             DAY 2
        ────────────────
               │
               ▼
        Spoke Argo CD
               │
               ▼
       cluster-config Git
```

**ACM provisions the cluster.
The spoke Argo CD manages the cluster after installation.**

