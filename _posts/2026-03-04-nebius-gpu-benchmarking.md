---
layout: post
title: "GPU cluster benchmarking on Nebius with Terraform, Ansible, and NCCL"
---

# GPU cluster benchmarking on Nebius

I built a small toolkit for spinning up GPU nodes on [Nebius AI Cloud](https://nebius.com), running NCCL all-reduce benchmarks, and tearing everything down — all from a single `make` command. The code is at [github.com/alanlaird/gpulabs/nebius](https://github.com/alanlaird/gpulabs/tree/main/nebius).

[![Nebius GPU cluster architecture](_posts/img/nebius-cluster-scheme.svg)](https://nebius.com/blog/posts/how-we-build-reliable-clusters)

## Why Nebius

Nebius is a GPU-native cloud spun out of Yandex. Their eu-north1 region has H100 SXM nodes connected via NVIDIA Quantum-2 InfiniBand at 400 Gbps per node — the same fabric you'd get in a datacenter GPU cluster. Pricing is competitive: L40S nodes start at ~$1.55/hr, H100 single-GPU at ~$2.30/hr, and full 8×H100 IB nodes at ~$18.40/hr.

[![Nebius InfiniBand fabric topology](_posts/img/nebius-ib-topology.gif)](https://nebius.com/blog/posts/leveraging-nvidia-gb200-nvl72-gpu-interconnect)

## The setup

The repo has three projects:

| Directory | What it does |
|-----------|-------------|
| `basic/` | Provision two GPU nodes, nothing else |
| `nccl-docker/` | Provision + Docker + NCCL benchmarks |
| `nccl/` | Bare-metal NCCL (no Docker) |

Everything is driven by Terraform + Ansible. `make create` handles the full lifecycle:

1. **Terraform** provisions two GPU instances and their boot disks, auto-selecting the latest Ubuntu CUDA image and available subnet via shell scripts
2. **Ansible** installs Docker + NVIDIA Container Toolkit, pulls the NCCL test image, extracts binaries for MPI use, and sets up inter-node SSH
3. The Nebius GPU image ships with OpenMPI pre-installed at `/usr/mpi/gcc/openmpi-4.1.9a1` — no apt-install needed

```bash
make create             # two L40S nodes, ~$3.10/hr total
make create NODE_TYPE=h100     # H100 single-GPU nodes
make create NODE_TYPE=h100-ib  # H100 8×GPU InfiniBand nodes
make test               # run NCCL benchmark
make destroy            # stop billing
```

## Benchmark results — L40S over TCP

The NCCL test uses the [CoreWeave nccl-tests image](https://github.com/coreweave/nccl-tests), running `all_reduce_perf` across two nodes.

```
#  Rank  0  NVIDIA L40S  node 1
#  Rank  1  NVIDIA L40S  node 2

       size    time    algbw   busbw
         8B    86us    0.00    0.00
       128K    475us   0.28    0.28
         1M   1290us   0.81    0.81
        32M   23103us  1.45    1.45
       128M   92698us  1.45    1.45

# Avg bus bandwidth: 0.478 GB/s
```

Peak of **1.45 GB/s** (~11.6 Gbps) — essentially hitting the ceiling of a 10GbE TCP link. The latency at small sizes (~86 µs) is pure network overhead with no NVLink or IB.

This is a useful baseline. It shows what you're leaving on the table compared to InfiniBand: a 400 Gbps IB fabric would push this to ~40 GB/s busbw at large sizes.

## InfiniBand nodes

The 8×H100 IB node type requires creating a `nebius_compute_v1_gpu_cluster` resource that attaches both nodes to a shared InfiniBand fabric:

```hcl
resource "nebius_compute_v1_gpu_cluster" "ib_cluster" {
  count             = var.infiniband_fabric != "" ? 1 : 0
  parent_id         = var.parent_id
  name              = "nccl-docker-ib-cluster"
  infiniband_fabric = var.infiniband_fabric
}
```

eu-north1 has four H100 IB fabrics (`fabric-2` through `fabric-6`). eu-west1 has H200 IB on `fabric-5`. Each region uses its own naming convention — `me-west1` uses `me-west1-a`, not `fabric-*`.

[![Nebius GPU cluster topology diagram](_posts/img/nebius-cluster-scheme2.svg)](https://nebius.com/blog/posts/how-we-build-reliable-clusters)

One operational gotcha: when an IB node gets stuck in `STARTING` state, `terraform destroy` fails because the Nebius API rejects delete requests for resources in transient states. The fix is to go around Terraform directly:

```bash
make force-destroy  # uses nebius CLI + cleans terraform state
```

## Runtime InfiniBand detection

The MPI wrapper script deployed to each node auto-detects IB at runtime:

```bash
if ls /sys/class/infiniband/ 2>/dev/null | grep -q .; then
    MPI_TRANSPORT_ARGS=""
    NCCL_TRANSPORT_VARS="-x NCCL_IB_DISABLE=0"
else
    MPI_TRANSPORT_ARGS="--mca btl_tcp_if_include eth0"
    NCCL_TRANSPORT_VARS="-x NCCL_SOCKET_IFNAME=eth0"
fi
```

This means the same wrapper script works correctly on both TCP and IB nodes without manual reconfiguration.

## What's next

IB capacity on eu-north1 was exhausted during testing. The toolkit is ready — just needs a quota increase on H200 (eu-west1) or a slot to open up on H100. Once those run I'll post the IB numbers.

Code: [github.com/alanlaird/gpulabs/nebius](https://github.com/alanlaird/gpulabs/tree/main/nebius)
