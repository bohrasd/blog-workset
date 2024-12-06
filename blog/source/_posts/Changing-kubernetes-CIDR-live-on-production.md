---
title: Changing kubernetes CIDR live on production
date: 2024-11-21 17:12:45
tags:
- kubernetes
- CNI
- tailscale
---

## Context: The conflict with Tailscale’s CIDR

kOps-managed clusters use `100.64.0.0/13` as the default Service CIDR and `100.96.0.0/11` as the default Cluster CIDR (PodCIDR), while Tailscale assigns addresses in the `100.64.0.0/10` range, spanning from 100.64.0.0 to 100.127.255.255. This creates an overlap between Tailscale’s subnet and kOps’ default CIDRs.

Tragically we have to, or I should say it was too late to find that we can't connect an essential service from our kops cluster through tailscale. So we have to migrate both podCIDR and serviceCIDR to other CIDRs. Well to look at it optimisticly, the benefits also includes easier connectivity to our other Tailscale services, the ability to expose more internal Kubernetes services like the observability stack, and improved Kubernetes access control by eliminating the need for bastion hosts.

## Concepts

#### Service IP
It’s a Virtual IP allocated by kube-apiserver. `kube-proxy` on each nodes (if using kube-proxy) then defined iptable rules for this virtual IP.
Some well-known service IPs:
kube-apiserver: `kubernetes.default.svc.cluster.local` ( x.x.0.1)
kube-dns: `kube-dns.kube-system.svc.cluster.local` (x.x.0.10)

Example: a set of rules from service foo-bar (172.24.121.68) redirected to pods (`172.18.244.100/172`.18.249.115)
```
-A KUBE-SERVICES -d 172.24.121.68/32 -p tcp -m comment --comment "example-ns/foo-bar:app cluster IP" -m tcp --dport 4000 -j KUBE-SVC-WWWWWWWWWW

-A KUBE-SVC-WWWWWWWWWW ! -s 172.16.0.0/13 -d 172.24.121.68/32 -p tcp -m comment --comment "example-ns/foo-bar:app cluster IP" -m tcp --dport 4000 -j KUBE-MARK-MASQ

-A KUBE-SVC-WWWWWWWWWW -m comment --comment "example-ns/foo-bar:app -> 172.18.244.100:4000" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-XXXXXXXXX

-A KUBE-SVC-WWWWWWWWWW -m comment --comment "example-ns/foo-bar:app -> 172.18.249.115:4000" -j KUBE-SEP-YYYYYYYYY
```

#### Pod IP
An actual IP of a network interface attached to a pod, assigned by IPAM (IP address management) component. It's implemented by CNI to overcome inter-node communication by routing/tunneling/……anything without NAT.

## Change serviceCIDR

What we want to achieve is changing the Service CIDR without affecting the ingress-nginx service. So some services will keep the old IP. The feature [Extend Service IP Ranges](https://kubernetes.io/docs/tasks/network/extend-service-ip-ranges/) will be used to achieve this.
- Upgrade cluster to k8s 1.29 to enable `MultiCIDRServiceAllocator` feature gate and `networking.k8s.io/v1alpha1` API
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
- Then we'll use kops to change `serviceCIDR` from `100.64.0.0/13` to `172.24.0.0/15`
- Recreate all `ClusterIP` services after master rolling finished (recreate kube-api & dns services first)

### Hints & Tips:
- Don’t touch headless services when recreating all services! (service have clusterIP: None) (In case an IP is assigned to them)
- Leave LoadBalancer services for now if you don't want to change all DNS records in one night. AWS doesn't support recreate LB service and keep it's LB instance.
- `kubernetes.default` will be recreate by itself, magically
- Restart all pods after recreated kube-dns service to load the new DNS server in /etc/resolv.conf
- We create the /24 serviceCIDR to fix error events reported from LoadBalancer service: `ClusterIPOutOfRange`. /32 CIDR won't work.

```
apiVersion: networking.k8s.io/v1alpha1 <= the runtime config enabled after upgrading to k8s 1.29
kind: ServiceCIDR
metadata:
  name: lb-cidr1
spec:
  cidrs:            # It looks like an array but only accept 1 member
  - 100.69.172.0/24 # Don't create /32 or it won't work
```

## Change podCIDR (Calico)

First we have to look at:

### IPAM mechanism in kops

IPAM can be managed by kubernetes(kube-controller-manager) or CNI plugin (Calico, Cilium, …). In kOps, it’s managed by kube-controller-manager by default. But from k8s teams perspective, the CIDR is Not intended to be changed [ref](https://github.com/kubernetes/kubernetes/issues/75461#issuecomment-475387323). If you do kube-controller-manager will refuse to start.

On kops, to use CNI to manage IPAM:

#### Calico
It will take over IPAM by default, this is the CNI config generated by kOps:

```
root@i-xxxxx:/home/ubuntu# cat /etc/cni/net.d/10-calico.conflist
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
```

#### Cilium

Cilium IPAM manages podCIDR by kube-controller-manager by default. `cluster-pool` mode (the cilium feature to manage IPAM) is not supported in kOps, meaning Cilium would need to be managed independently instead of through kOps. Additionally, changing podCIDR is not recommended in Cilium, even when using cluster-pool mode.

### The migration

Calico has the ability IPPool to support multiple CIDRs, so we can add a new CIDR and remove the old one.

Before rolling updates, scaling up CoreDNS and pod-identity-webhook is essential to handle potential inter-node connectivity issues.

#### Steps:
- Create an IPPool of `172.16.0.0/13`
- Disable default IPPool `100.96.0.0/11`
- Rolling restart all workloads to have PodIP in `172.16.0.0/13`
- Change kops config and rolling restart:
  - `nonMasqueradeCIDR` from `100.64.0.0/10` to `172.16.0.0/12`
  - `podCIDR` from `100.96.0.0/11` to `172.16.0.0/13`
  - Disable kube-controller-manage IPAM `allocateNodeCIDRs: false` (kOps cluster), otherwise kube-controller-manager will refuse to start

```
failed to mark cidr[100.96.18.0/24] at idx [0] as occupied for node: i-xxxxxxx: cidr 100.96.18.0/24 is out the range of cluster cidr 172.16.0.0/13" controller="node-ipam-controller"
```
By disabling it, the kube-controller-manager will stop assigning podCIDR for each nodes, that’s no problem as long CNI do the IPAM

- Delete old IPPool

