---
title: 零宕机更改生产环境 k8s CIDR 网段(ServiceCIDR篇)
date: 2024-11-21 17:12:45
tags:
- kubernetes
- CNI
- tailscale
---

## 背景：kops 默认 CIDR 与 Tailscale 的 CIDR 的冲突
kOps 管理的集群将 100.64.0.0/13 用作默认的 Service CIDR，将 100.96.0.0/11 用作默认的 Cluster CIDR（PodCIDR），而 Tailscale 在 100.64.0.0/10 范围内分配地址，范围从 100.64.0.0 到 100.127.255.255。这导致 Tailscale 的子网与 kOps 的默认 CIDR 重叠，我们没法装 Tailscale Operator, 但我们又得用。

## 概念
### Service IP

它是由 kube-apiserver 分配的虚拟 IP。每个节点上的 `kube-proxy`（如果使用 kube-proxy）会为这个虚拟 IP 定义 iptables 规则。
一些众所周知的服务 IP：

- kube-apiserver: `kubernetes.default.svc.cluster.local` (x.x.0.1)
- kube-dns: `kube-dns.kube-system.svc.cluster.local` (x.x.0.10)

例如：服务 foo-bar 的一组规则(172.24.121.68) NAT 到 pods (172.18.244.100/172.18.249.115)
```
-A KUBE-SERVICES -d 172.24.121.68/32 -p tcp -m comment --comment "example-ns/foo-bar:app cluster IP" -m tcp --dport 4000 -j KUBE-SVC-WWWWWWWWWW

-A KUBE-SVC-WWWWWWWWWW ! -s 172.16.0.0/13 -d 172.24.121.68/32 -p tcp -m comment --comment "example-ns/foo-bar:app cluster IP" -m tcp --dport 4000 -j KUBE-MARK-MASQ

-A KUBE-SVC-WWWWWWWWWW -m comment --comment "example-ns/foo-bar:app -> 172.18.244.100:4000" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-XXXXXXXXX

-A KUBE-SVC-WWWWWWWWWW -m comment --comment "example-ns/foo-bar:app -> 172.18.249.115:4000" -j KUBE-SEP-YYYYYYYYY
```

### Pod IP
实际分配给 Pod 的网络接口的 IP，由 IPAM（IP 地址管理）组件分配。它由 CNI 实现，以克服跨节点通信的问题，使用路由/隧道等方式，但不能用 NAT。

## 更改 serviceCIDR
我们想要实现的是更改 Service CIDR，而不影响 ingress-nginx Service。所以这个 Service 还得保留旧的 ClusterIP。这个可以由 [Extend Service IP Ranges](https://kubernetes.io/docs/tasks/network/extend-service-ip-ranges/) 这个功能来实现。

### 步骤
- 升级集群到 k8s 1.29 以启用 `MultiCIDRServiceAllocator` 功能门控和 `networking.k8s.io/v1alpha1` API
```
kubeAPIServer:
    featureGates:
  	MultiCIDRServiceAllocator: "true"
    runtimeConfig:
  	networking.k8s.io/v1alpha1: "true"
kubelet:
    featureGates:
  	MultiCIDRServiceAllocator: "true"
```
- 然后我们使用 kops 将 `serviceCIDR` 从 `100.64.0.0/13` 更改为 `172.24.0.0/15`
- 在 master 滚动更新完成后，重新创建所有 `ClusterIP` 服务（就是把所有 Service yaml get 出来然后 apply。最好先单独重建 kube-apiserver 和 coredns 服务，apiserver 删除后会自动重建）

### 提示与技巧
- 在重新创建所有服务时，要排除掉 Headless 的服务（也就是 ClusterIP: None 的服务）！以防它们被分配了 IP。
- 如果你域名很多，不想一口气更改所有 DNS 记录，可以把 LoadBalancer 类型的 Service 先留着。比如 AWS 重新创建 LB 服务就会删掉之前的 LB 地址，你就得把所有域名指向新的 LB 地址。
- `kubernetes.default` 服务会自动重建。
- 重建 kube-dns 服务后，要重启所有 Pod 以加载新的 DNS 服务器到 /etc/resolv.conf。
- serviceCIDR 最小允许 /24 CIDR，否则会报错事件：`ClusterIPOutOfRange`。/32 CIDR 不行。

```yaml
apiVersion: networking.k8s.io/v1alpha1 <= the runtime config enabled after upgrading to k8s 1.29
kind: ServiceCIDR
metadata:
  name: lb-cidr1
spec:
  cidrs:            # It looks like an array but only accept 1 member
  - 100.69.172.0/24 # Don't create /32 or it won't work
```

下一篇讲解更改 PodCIDR（Calico）的步骤。
