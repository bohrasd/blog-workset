---
title: 如何在本地虚拟机模拟 Kubernetes the hard way
date: 2021-10-01 11:39:11
tags: kubernetes
---
[Kuberenetes the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way) 是一个非常出名的学习 Kubernetes 的项目。作者是谷歌的 Kelsey Hightower (他关于 NFT 的推特非常有意思)。这个教程的目的是不通过 kubeadm 也不通过其他 k3d/kind/minikube 之类的方法，手动搭建 k8s。包括手动生成所有证书，手动下载所有 binary 手写 systemd 文件来启动这些 binary，在这个过程中，让学习者对每个部件的用途有所感觉。

国内用户实践这个教程会有一个问题，那就是它需要使用谷歌云，但 gcloud 命令因为网络封锁不便使用。而我虽有办法，但免费的一年 $300 coupon 早就为了躲避网络封锁用掉了。但没关系，这些操作都可以在本地虚拟机实践，这里挑出其中会有问题的章节作一个笔记。

## 第三节

创建服务器实例，在本地都可以通过 virt-manager 建立，在选择网络那一步选择 bridge，填入虚拟网卡名。虚拟机安装完正常启动后，`sudo virsh net-dhcp-leases default` 可以看到所有的虚拟机地址。

## 第四、五节

冗长的生成所有证书和配置的环节。但这里其实内容很关键，因为这里说明了各部件是如何互相认证进行通信的，证书的 CN(Common Name) 即是用户，O(Organization) 即是 Group. 证书也可以用其他工具生成。但是 PKCS11 里的密码加密 key 是亲测不支持的。另外如果不使用 RSA，例如我使用 ECDSA 可以启动所有部件，但后来 metrics-server 不认识非 RSA 证书。

## 第八节
loadbalancer 可以用任意的反向代理代替，例如本地用 envoy 运行这个配置：
```
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        protocol: TCP
        address: 0.0.0.0
        port_value: 6443
    filter_chains:
    - filters:
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: inter_tcp
          cluster: k8s
  clusters:
  - name: k8s
    type: STATIC
    dns_lookup_family: V4_ONLY
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: k8s
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 192.168.122.1
                port_value: 6443
        - endpoint:
            address:
              socket_address:
                address: 192.168.122.2
                port_value: 6443
        - endpoint:
            address:
              socket_address:
                address: 192.168.122.3
                port_value: 6443
```
然后把 apiserver 的地址指向 192.168.122.1:6443 即可。当然不讲究的甚至可以直接用其中一个 master 的虚拟机地址。

## 第九节
启动 worker 中关闭 swap 这一步，Redhat 系如果使用 zram：
```
systemctl disable firewalld
systemctl stop firewalld
systemctl unmask dev-zram0.swap
```

Debian 系安装系统时不要预留 swap 分区即可。

安装和配置 CNI，这里可以照做，POD_CIDR 中就需要手动分配 PodCIDR 的三个子网，比如 10.244.0.0/16 可以分配 10.244.0.0/24, 10.244.1.0/24, 10.244.2.0/24.

也可以后面直接装个 flannel/Calico 之类的 overlay network 跳过这一步，但注意 1.0 之后的 cni 中已经没有自带 flannel 了，而 flannel 部署时也不会自动下载自己的 cni. 可以自己去 https://github.com/flannel-io/cni-plugin/releases 下载。教程里下载的 0.9 版本还是有自带的。

还有一个有趣的点，gcloud 会自动 dns 实例名到 ip，我们可以在 master 的 `/etc/hosts` 中指定，类似
```
192.168.x.x worker-1
192.168.x.x worker-2
192.168.x.x worker-3
```
否则有可能会注册不了 worker.

## 第十一节
上一步如果照教程在 `/etc/cni/net.d 中自己建立 bridge，这里就需要通过 iproute 告诉路由表怎么寻找各台机子 pod 子网了。每台虚拟机中指定另外两台机器的网络。例如 192.168.122.1 是 10.244.0.0/24, 就指定

```
ip ro add 10.244.1.0/24 via 192.168.122.2
ip ro add 10.244.2.0/24 via 192.168.122.3
```
另外两台也照做。

如果使用 flannel，还有一个坑：默认的 vxlan 恰好在我的 debian 版本上有问题无法工作。如果我使用 `host-gw` 模式，其实和作者这里的实现是一模一样的，没有使用 overlay network，直接通过路由表。其实 flannel 还有很多其他模式，比如 ipip, UDP 等都可以正常用。

## 其他
到这里为止教程完成了。但还有很多有意思的空间。比如作者没有开启 Aggregation Layer, 也需要自己生成证书，这个证书就是 kubeadm 生成的 front-proxy 证书。更有意思的是，这个教程实现的 master 是真正的 master，没有 pod 网络，所以你想让 metrics-server 与 master 通信还需要让 metrics-server 运行在 hostNetwork...

所以接下来可以乱捣鼓的东西还有很多。但今天就写到这里。
