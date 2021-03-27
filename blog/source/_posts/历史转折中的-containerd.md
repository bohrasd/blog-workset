---
title: 历史转折中的 containerd
date: 2020-11-09 21:15:50
tags:
---

你知道 containerd, 但你又不了解 containerd, 你不关心它的过去和现状，也不清楚它的未来，你不是真的爱它。现在是2020年秋天。最近 containerd 的维护者 Phil Estes 去了一档播客，讲了很多关于 containerd 和 OCI 的事情。机缘巧合听了这个节目，稍微总结性的记录一下。

历史
最早期，虚拟机，LXC 这些东西，是容器技术的曙光期不必赘述。中间种种略过，Docker 横空出世，大约 2014-15年期间，Docker 是唯一知道怎么样正确把 Namespace 和 cgroup 打包起来的公司。但接下来他们的命运急转直下。大家对 Docker monopoly 的代码、层出不穷的 bug 以及对社区的漠不关心等等，产生很多抱怨。rkt 作为竞争者出现，然后好事的公司发起了「开放容器倡议」，即OCI.

我们谈及 Docker 总是只关心容器，其实它也包括了很多连带的东西例如镜像的标准，镜像的构建，镜像仓库的定义等等。OCI 统一了这些，那接下来就是有组织有计划的干掉 Docker. runC 直接去封装了容器技术本身，containerd 作为运行时去管理容器的生命周期。

把 containerd 和 Docker 比较是不合适的。containerd 并不、也不打算去 build 镜像和管其他杂事，ctr 这个终端工具，也只是给运维人员测试用的。containerd 只是想专心做运行时的行业标准。「行业标准」，与之相对的 CRI 只是 Kubernetes 自己的标准。

回到这段历史，所有 containerd 不关心的事情，都直接交给 Docker/BuildKit. 而红帽阵营在这个混乱期，为了让事情变得更复杂？或者让 Docker 死的更彻底？他们直接基于 runC 构建了 CRI-O，专供 k8s. 而接下来又为了满足开发人员的使用需要，构建了 Podman/Buildah/Scopio.

containerd 的现状
既然 containerd 是行业标准，那除了用于 Docker 和 k8s，还有什么呢？有的。例如要搞边缘计算的 k3s 就是直接基于 contianerd 的，它跳过了 CRI，所以 512MB 内存就可运行。

再有就是 OpenFaaS，用在体积庞大的 Docker Swarm 和 Kubernetes 上很好用。但是如果只有一台 5刀一个月的小破 VPS，还是考虑一下 faasd 吧。直接基于 containerd, 它能跑在 1GB 内存的小机子上。

除了这些，还有 containerd 的一些子项目。假如你要在自己笔记本拉个10GB 的镜像，你说好我时间多可以等。那假如几千台服务器，每台都拉同一个 10GB 镜像？大家都是一个网里的，都去重复请求 registry 不太好吧。containerd/stargz-snapshotter 就是来自 contianerd 的解决方案。

OCI 的现状
上面说道 OCI 提供了容器和镜像的标准之后，这个倡议就忽然失去了热度——反正标准定了，去做工具就行了。几年后的现在，容器的世界日趋成熟，我们又开始需要统一更多的标准，所以 OCI 的关注度又回升了。比如 opencontainers/distribution-spec 就是为了让 Docker 死的更透一点，来统一镜像 registry 的标准吧？ Habour/Quay/各路云厂商，可以按标准走了。

而且，要考虑的并不是只有容器,要管理的还有那么多 yaml/chart/乱七八糟，Docker 有 Docker App, 其他各种云厂商也有各自的解决方案。但最终无论被管理的是镜像还是别的任何文件任何媒介，都可以遵循一个 registry 标准。于是 opencontainers/artifacts 的热度也在上升。

简单回顾
runC 是最底层封装，建立和运行容器；
你需要一个运行时去调度，就有了 containerd;
k8s 通过 CRI 来管各种运行时，Docker/rkt/containerd/CRI-O;
本地开发/镜像构建，如果你是 Docker 派用 Docker/containerd/buildkit, 红帽派用 Podman/Buildah/Skopeo;
OCI 就是一切开放容器的标准。

Docker 走后怎样
最近因为 Docker 被人们冷落多年以后，终于无力承受几十 PB 的镜像托管的服务器费用，修改了用户政策，要自动删除 6个月以上不活跃的镜像。破公司快倒了。

红帽作为上游接下来要推 cgroup v2. CRI-O/Podman 等早已支持，而 Fedora 作为红帽最新科技的 testbed, 也默认使用 cgroup v2 了一年多。看起来也很有意思，比如内存满了，比起直接 OOMkill，它可以利用内存的高中低优先级. containerd 也会支持。

以后，你可以 alias podman=docker, 然后一切照旧。
