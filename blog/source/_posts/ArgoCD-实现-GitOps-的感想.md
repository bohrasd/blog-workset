---
title: ArgoCD 实现 GitOps 的感想
date: 2021-01-15 20:13:08
tags: kubernetes CI/CD argocd
---

实现 GitOps 不是一蹴而就的。为公司项目实现 GitOps 前后彻底推翻了两次，大幅修改了很多次。当然没有完美的 Ops, 但现在处于一个相对符合 weaveworks 那位老师定义的样子，而且也符合我们的实际情况。我需要记录一下自己的心路历程，否则很容易对结果 take for granted.

首先说下使用前：项目是把配置放在 .env 文件里，k8s 的 yaml 也放在代码目录里。但这个 yaml 却不是最终部署，而是里面有很多占位字符串等到 ci 流水线的最后一步替换掉，再 apply 到集群上。

困扰有很多：每个项目的 ci 都要独立修改，大动的时候例如加服务网格 sidecar、升级 api version 或者加 hpa 之类的操作，都需要到各个项目去动，各自提交。很麻烦而且长期下来配置各不相同。然后开发者并不知道代码目录里看到的这些是什么。凡此种种。而 GitOps 的好处之多，我就不赘述了。

第一个疗程：首先原本的 ci 文件里有一长串复杂但却久经考验的部署 bash 脚本. 我知道我不能一上来就大动干戈，所以我只是把最后 kubectl apply 那一步改为一个 git 提交。很好。但我一上来就非常执着于中心化配置，我想要在一个我能控制的仓库里把 yaml 在提交前「截」下来,把自己的配置 kustomize patch 上去。于是我另建了一个仓库，在提交前拉下来，把我的配置 kustomize 上去.但最终的提交到哪里呢？我觉得既然我有「截断」措施，各个项目的 yaml 还是在各自仓库里不容易冲突，于是参照网上的做法在 ci 的最后一步提交给自己。为了防止循环提交，在提交时带上 [skip ci].

上面这几个考虑事实证明大错特错。
1. 配置非但还是没有分离，而且原先为了保密把一些敏感配置提取到 gitlab 变量里，结果现在又被作为最终注入的 secret yaml 提交回了代码仓库；
2. 我这个截断行为等于给使用者增加了一个不透明而且碎片化的一层，部署之后业务开发向我抱怨他不知道数据库在哪配的，因为现在等于有了 3 个地方，而且出现了重复配置，他不知道优先级是怎样的；
3. 我的截断等于需要流水线主动拉取，接下来即便我做了中心化的修改，也需要各个仓库执行最后一步流水线才能生效；
4. 最后是提交到自己仓库——虽然你能看到有这么做的，但是千万别，因为 skip ci 标记会在流水线页面莫名其妙多一个被跳过的记录，而且开发人员如果没有在自己提交前拉下最新的代码直接提交，会产生一个 merge, 稍不注意 git 的 merge 提交记录里会带上这个标记，导致开发人员提交无法触发流水线。

第二个疗程：这一步我当然是要导出所有配置，所有的微服务的 yaml，最终提交都到同一个项目级仓库。事实证明，做 gitops 当然要相信 git 的机制。各自项目提交到各自的文件夹，怎么可能冲突。去除了我的所谓中心化配置，所有配置都在最终 gitops 仓库里，也大幅精简了复杂度，而且这个配置可以提交即生效。

解决了大多数问题，但还有一些棘手的地方。
1. 最大的问题是每次生成的 yaml 还是通过各自仓库里的模板字符串替换得到的；
2. 每次进行改动虽然只需要一个仓库提交，但需要进行大量文件的修改，总是要写很多脚本，也容易出错；
3. gitops 的仓库在项目里，提交的 secret 相当于大家还是能看到。

最终的方案删除了各个项目里的所谓模板，把一个真正的模板放在了 gitops 仓库一个单独的文件里，然后 ci 只在每个冷启动的项目复制一份模板新建 yaml，而之后每次 build 完镜像，只需要 Bump 镜像版本。真正做到了「开发人员只交付镜像」.

其次就是 secret 的问题。现阶段大多数的建议是使用 mozilla sops 或者 hashicorp vault 来实现 sealed secret. 我本想试用 sops, 但发现 sops 真的只能使用 Amazon/Azure/GCP 的密钥环服务，并不能使用国内云厂商的类似服务。另一方面我们只是个小团队，一次性加入太多复杂度，很容易造成全公司里只有我知道这东西怎么用的状况。最终我的方案是直接把 gitops 的仓库单独迁到一个项目管理员的 gitlab 组下面。现在就可以邀请项目的管理人员进组看到具体的 secret. 这样做还有一个好处，即 ArgoCD 的 dex 调用 GitLab 的 sso 时，可以读取用户所在的组。这样我就可以通过用户在不在 gitops 组里去管理 ArgoCD 内的操作权限，一箭双雕。

最后是配置的问题，果然还是 kustomize 比较合适。可以实现层级关系来把通用的配置放在一个层级管理。helm 的问题不是今天的话题不多说了，如果你很喜欢 helm 我不反对，但你应该能注意到，类似 promethues-operator/linkerd2/ECK/Jaeger/cert-manager 等等等等这些大项目都没有把 helm 作为首选的安装方式，这是非常能说明问题的。
但是 kustomize 也有它的问题：最麻烦的是版本间的区别过于复杂。我本来以为 kubectl 自带的就可以，没想到这个版本差异太大。我本来下载了最新版本，没想到又与 argocd 带的版本有些操作不相兼容。最后不得不打包了一个 kustomize 和 git 的镜像来作为最后的上线一步。但是你应该可以注意到，把 kustomize 放进 kubectl 是一种明显的承认它亲儿子地位的行为。而版本问题都是时间可以解决的。

又跑题了，但大概就是这些，作为以后的备忘。如果想到什么再来补充吧。
