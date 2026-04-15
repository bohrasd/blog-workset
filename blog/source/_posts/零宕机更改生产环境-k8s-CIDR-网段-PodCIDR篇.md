---
title: 零宕机更改生产环境 k8s CIDR 网段(PodCIDR篇)
date: 2024-11-21 17:12:45
tags:
- kubernetes
- CNI
- tailscale
---

上一篇文章我们介绍了如何更改 ServiceCIDR，这篇文章我们来介绍如何更改 PodCIDR。

## 更改 podCIDR 一些前提知识

首先我们需要看一下 kops 集群的 IPAM 机制：

IPAM (IP Address Management) 可以由 kubernetes (kube-controller-manager) 或 CNI 插件 (如 Calico, Cillium) 提供。kops 集群默认使用 kube-controller-manager 来管理 IPAM。但从 k8s 团队的角度来看，CIDR 不应该被更改 [参考](https://github.com/kubernetes/kubernetes/issues/75461#issuecomment-475387323). 我们尝试过如果更改了 kube-controller-manager 的配置，它就起不起来了。

### Calico

Calico 默认会接管 IPAM，以下是 kOps 生成的 CNI 配置：

```json
{
  "name": "k8s-pod-network",
  "cniVersion": "0.3.1",
  "plugins": [
    {
      "type": "calico",
      ...
      "ipam": {
        "assign_ipv4": "true",
        "assign_ipv6": "false",
        "type": "calico-ipam"
      },
      ...
    }
  ]
}
```

### Cilium

Cilium 的 IPAM 默认由 kube-controller-manager 管理。`cluster-pool` 模式（Cilium 的 IPAM 管理功能）在 kOps 中不受支持，这意味着 Cilium 需要独立管理 IPAM，而不是通过 kOps。此外，即使使用 cluster-pool 模式，Cilium 也不建议更改 podCIDR。

## 迁移步骤

Calico 支持通过 IPPool 来支持多个 CIDR，因此我们可以添加一个新的 CIDR 并删除旧的 CIDR。

在滚动更新之前，扩展 CoreDNS 和 pod-identity-webhook 是必要的，以处理可能的跨节点连接问题。

### 步骤：
- 创建 172.16.0.0/13 的 IPPool
- 禁用默认的 100.96.0.0/11 IPPool
- 滚动重启所有工作负载以使 PodIP 在 172.16.0.0/13
- 更改 kops 配置并滚动重启：
  - 将 `nonMasqueradeCIDR` 从 100.64.0.0/10 改到 172.16.0.0/12
  - 将 `podCIDR` 从 100.96.0.0/11 改到 172.16.0.0/13
  - 禁用 kube-controller-manager 的 IPAM `allocateNodeCIDRs: false`（kOps 集群），否则 kube-controller-manager 会拒绝启动
    ```
    failed to mark cidr[100.96.18.0/24] at idx [0] as occupied for node: i-xxxxxxx: cidr 100.96.18.0/24 is out the range of cluster cidr 172.16.0.0/13" controller="node-ipam-controller"
    ```
    - 通过禁用它，kube-controller-manager 将停止为每个节点分配 podCIDR，之后将由 CNI 负责 IPAM。
  - 删除旧的 IPPool
