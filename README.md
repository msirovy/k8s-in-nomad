# LAB: Nomad-k0s Edge Orchestrator
A minimalist, high-resilience setup using Nomad to orchestrate k0s clusters across distributed edge locations.

## Concept: 

 * **Resilience at the Edge**: This architecture treats Nomad as the primary control plane because of its ability to handle unreliable networking between data centers and edge nodes.

 * **Simple Workloads**: Deployed directly via Nomad across all edge locations for maximum efficiency and low overhead.

 * **Kubernetes API on Demand**: For customers requiring the standard K8s API, a dedicated k0s cluster is provisioned on specific nodes using Nomad. This provides a familiar API without the complexity of a full-scale K8s bootstrap.


## Repository Structure

```bash

├── ansible.cfg       # Ansible configuration for base provisioning
├── init-deb13.yml    # Playbook for OS preparation (Debian 13 Trixie)
├── inventory         # Host definitions (Edge / Server nodes)
└── jobs              # Nomad job specifications
    ├── k0s_cp.hcl    # Job for k0s Control Plane
    └── k0s_workers.hcl # Job for k0s Worker nodes
```

## Quick Start

 1. Host Provisioning

  Targeting Debian 13. The Ansible playbook prepares the OS, tunes the kernel for container workloads, and installs the Nomad agent.

  ```bash
  ansible-playbook -i inventory init-deb13.yml
  ```

 2. Bootstrap nomad token on the master node
 
 ```bash
 # You should know this

 ```

 3. Deploying k0s via Nomad
  
 Nomad manages the k0s lifecycle. To provide a K8s endpoint, run the control plane job:

 ```bash
 nomad job run jobs/k0s_cp.hcl
 ```

 3. Scaling k0s Workers
 
 Deploy workers to the required edge nodes to join the k0s cluster:

 ```bash
 nomad job run jobs/k0s_workers.hcl
 ```


## Technical ideas

 * **Network Resilience**: Leverages Nomad’s ability to function over unstable links (even with long time disconnection).

 * **Zero Overhead**: Uses k0s for its simplicity and full k8s compatibility. It makes declarative deployment by nomad simple.

 * **Minimalizing Blast Radius**: Standard K8s is inherently fragile due to its complex, tightly-coupled control plane. By running multiple and small k0s as a Nomad jobs, I isolate failures and prevent a single cluster issue from impacting the entire infrastructure.

 * **Standat API**: k8s is the standart server/cluster UI, it is a good idea to provide it to custommer.

## Targets

 * Validate that is possible to run k8s as a workload in nomad with all the common stuff (monitoring, argocd, ingress, ...) + second day operations (upgrade, add/remove node/DC)
 * Check if multiple workers can run on single HW node
 * Name pros and cons
