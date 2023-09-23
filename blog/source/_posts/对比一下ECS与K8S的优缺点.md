---
title: 对比一下ECS与K8S的优缺点
date: 2023-09-16 15:09:10
tags: kubernetes
---

基于 Fargate 的 ECS 就是一个非常易用的 PaaS, 所有的管理工作都在 AWS. 在我看来也是用 ECS 最大的价值。Fargate 的优势不用多说，这个灵感来自谷歌 Crostini 的技术炙手可热。用起来直观感受也是非常的轻量化，灵敏程度和其他地方跑容器没有太大差别。

ECS Fargate 用下来为数不多的缺点有三：

- 不能把配置或Secret直接挂载为文件，只能作为环境变量传入；
- 不能使用高级的 Linux 权限如 devices/capabilities (只有基于 EC2 才能支持)；
- 最小单位的 CPU/内存也是有限制的

如果采用基于 EC2 的方式运行，虽然多了一些灵活性，但也失去了大多数 Fargate 的优势。机器需要管理工作。awsvpc 网卡在每台机器上只能运行十几个 task, 而 bridge 的 dynamic port mapping 的灵活性也不如 service. 没有 Readiness 机制，对机器的管理（如 drain/cordon/affinity等）也欠缺。

而 K8S 可以说是非常灵活和强有力了。因为一开始就接触 K8S, 没有这种对比， 所以现在才意识到，使用 K8S 几乎没有牺牲任何 Linux 本身的好处，而且它已经为使用者考虑好了大多数大规模使用机器会遇到的痛点。当然这些好处也伴随着相对较高的学习成本。所以 ECS 的简单也是优势。
