---
layout: post
title: "Talos Linux Kubernetes on GCP spot instances with MIG auto-healing"
category: tech
---

# Talos Linux Kubernetes on GCP spot instances

I built a small Terraform + Makefile project that spins up a Talos Linux Kubernetes cluster on GCP spot instances, with Managed Instance Groups handling automatic recovery when nodes get preempted. The code is at [github.com/alanlaird/gcplabs/spot-talos](https://github.com/alanlaird/gcplabs/tree/main/spot-talos).

## Why Talos

[![Talos Linux](_posts/img/talos-logo.svg)](https://www.talos.dev/)

Talos Linux is a minimal, immutable OS [designed specifically for running Kubernetes](https://www.talos.dev/). There's no SSH, no package manager, no shell — the entire OS is managed through a gRPC API (`talosctl`). This makes it a good fit for ephemeral cloud VMs: there's nothing to configure or drift, and the OS footprint is tiny enough to boot comfortably on a 20GB disk.

The tradeoff is that the setup flow is different from a typical K8s install. Instead of SSHing in and running kubeadm, you generate a machine config locally and push it to the node over the Talos API while it's in "maintenance mode" right after boot.

## Architecture

- 1 control plane node (spot), managed by a MIG with target size 1
- 2 worker nodes (spot), managed by a separate MIG
- Reserved static IP for the control plane — so the K8s API endpoint stays stable across MIG-initiated restarts
- TCP health check on port 50000 (Talos API) — MIG uses this to detect preempted instances and replace them
- Talos machine configs embedded as `user-data` in instance templates — replacement instances self-configure on boot without any manual intervention

The static IP is the key piece. Talos machine configs bake in the control plane endpoint at generation time. If the IP changed every time the control plane was preempted, the kubeconfig and worker configs would all go stale. With a reserved IP, the endpoint is stable forever and MIG can replace the control plane instance transparently.

## How it works

`make up` runs a two-phase terraform apply:

1. **Phase 1** — provisions the network, static IP, health check, and MIGs. Nodes come up in Talos maintenance mode with no machine config yet.
2. **genconfig** — generates Talos machine configs targeting the reserved static IP.
3. **Phase 2** — embeds the configs as `user-data` in the instance templates. MIG detects the template change and replaces all instances. The new instances boot, read their config from metadata, and self-configure.
4. Wait for the Talos API, bootstrap etcd, fetch kubeconfig.

After that, spot preemptions are handled entirely by MIG. A preempted node gets replaced with a fresh instance from the template, which self-configures and rejoins the cluster. Workers rejoin automatically; if the control plane is replaced, `make recover` waits for the K8s API to come back and re-fetches kubeconfig.

```bash
make up         # create cluster (~10 min first time)
make status     # kubectl get nodes/pods + GCP resource list + cost estimate
make recover    # re-fetch kubeconfig after control plane replacement
make history    # show spot preemption events for this cluster
make stop_billing  # destroy everything including image and GCS bucket
```

## Cost

`make status` prints a live cost estimate:

```
── Billing (estimates) ────────────────────────────────────────────
  Static IP 34.125.6.72: IN_USE (free while attached)
  VMs (3x e2-medium spot)       $0.030/hr  $0.72/day  $21.60/month
  Disks (3x 20GB PD)            $0.003/hr  $0.08/day   $2.40/month
  Image + GCS                          —        —       $0.10/month
  Total                         $0.033/hr  $0.80/day  $24.10/month
  (spot prices are estimates; actual prices vary by region)
```

Three e2-medium spot nodes in us-west4 runs about $24/month. To cut that down:

| Config | Monthly estimate |
|---|---|
| 3× e2-medium (default) | ~$24 |
| 2× e2-medium (1 worker) | ~$17 |
| 3× e2-small | ~$12 |
| 2× e2-small (1 worker) | ~$8 |

For a lab that sits idle most of the time, `make stop_billing` + `make up` is the cheapest option — it leaves only the Talos image in GCS (~$0.10/month) and takes about 10 minutes to restore.

One thing to note: the static IP is billed at ~$0.01/hr (~$7.30/month) when the cluster is down but the IP is still reserved. `make stop_billing` runs `terraform destroy` first (which releases the IP) before cleaning up the image and bucket.

## Spot preemption in practice

GCP preemption rates vary a lot by region, machine type, and time of day. `us-central1` (Iowa) is GCP's most popular region and tends to see more preemption. I moved this cluster to `us-west4` (Las Vegas) which is a smaller, less-saturated region.

```bash
make history  # shows preemption events filtered to this cluster
```

For e2-medium, preemptions are infrequent enough that MIG auto-healing handles them without any visible impact on workloads — the node just comes back a few minutes later. The control plane is more disruptive since etcd has to come back up, but with a static IP the cluster recovers cleanly without touching any config files.

## Notes

- **No SSH anywhere** — Talos is managed entirely through `talosctl` on port 50000. If you need to debug a node, `talosctl dmesg` and `talosctl logs` are your friends.
- **Secrets** — `talos/` and `kubeconfig.yaml` are gitignored. They contain cluster credentials so back them up somewhere if you care about continuity.
- **Single-zone** — the cluster runs in a single zone, which keeps inter-node latency low and simplifies the MIG setup, but means a zone outage takes everything down. Fine for a lab.

Code: [github.com/alanlaird/gcplabs/spot-talos](https://github.com/alanlaird/gcplabs/tree/main/spot-talos)
