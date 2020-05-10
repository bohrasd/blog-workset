---
title: prometheus operator
date: 2020-04-20 20:13:08
tags: kubernetes metrics prometheus
---

普罗米修斯很早就该上了。阿里云提供的metrics 颇为实用，但是外包给他们做的dashboard着实难用丑陋，缺乏大厂风范。浩哥吐槽了很久。

本来没有想很多，但我不知道为何头脑一热就说，要用 operator. 恰逢最近各个大厂(IBM,微软，红帽)的油管频道都突然出视频讲 operator 模式。他们描绘的人肉 operator 转为自动化，应用能够易于配置(其实helm也挺方便)、无缝升级(helm也能)、self-healing(达到第五级的项目着实少数)让无知的我非常心动。

## 基本信息
普罗米修斯 operator 的 CRD 包括：

```
Prometheus, which defines a desired Prometheus deployment. The Operator ensures at all times that a deployment matching the resource definition is running.

ServiceMonitor, which declaratively specifies how groups of services should be monitored. The Operator automatically generates Prometheus scrape configuration based on the definition.

PodMonitor, which declaratively specifies how groups of pods should be monitored. The Operator automatically generates Prometheus scrape configuration based on the definition.

PrometheusRule, which defines a desired Prometheus rule file, which can be loaded by a Prometheus instance containing Prometheus alerting and recording rules.

Alertmanager, which defines a desired Alertmanager deployment. The Operator ensures at all times that a deployment matching the resource definition is running.
```

PrometheusRule 顾名思义. 我这里暂时关闭了 Alertmanager. 但是 helm chart 并没有提供只保留 scrape rules 去掉 alert rules 的方法。只好生成 yaml 自己删掉 alert rules。

ServiceMonitor 和 PodMonitor 其实质还是生成对应的配置去读取对应 service 和 pod 的信息。

普罗米修斯 2.x 版本之后发生了诸多改动。首先据说大幅优化了内存占用，连手册页面里新版都移除了关于内存的说明，看来对自己的优化很有自信。

## 基本配置
我配置内存时参考了[这里](https://www.robustperception.io/how-much-ram-does-prometheus-2-x-need-for-cardinality-and-ingestion)的配置。只能做个大概的参考，但总算有个参考。

普罗米修斯 operator 带有 grafana 安装、默认对 kubernetes 的监控和对应的 dashboard.

另一个小插曲是一开始将安装命名为 prometheus, 果然造成了不知名的冲突。删除以后发现 kubelet 的 scrape 数据都不正确，查看 target 后发现 prometheus 在同时读取两个 Service 提供的数据。然后才知道 Prometheus 第一次安装时生成的 headless service 没有删掉。手动删除后数据恢复了正常。

另外该 operator 也默认你开启了服务间的ssl, 会自动建立 ClusterRoleBinding 获取 secret. 如果你没有开启，需要自己为 grafana 加上 skipTls, 这个选项被官方 chart 遗漏了。另外要关闭 kubelet.serviceMonitor.https 否则会403。(搜索这个问题时竟然有博客说是因为127.0.0.1无法被局域网访问，你们的网络知识还不如我啊)

## Istio Integrety
Istio 坚称自带的 Prometheus 和其他插件都是演示用，不能作生产环境。在 1.5 之前他们在 issue 里说最好自建 Prometheus, 带上他们提供的 Rules, 如果是 Operator 部署也只需要加上他们的 [ServiceMonitor](https://github.com/istio/installer/tree/master/istio-telemetry/prometheus-operator).
在 1.5 版本他们突然想通了，给自己的 Prometheus 插件加上了 federation 接口，然后提供了[文档](https://istio.io/docs/ops/best-practices/observability/).

## monitoring mixins
监控的一个困扰是某些提供了一些 scrape rules 的项目，你不一定能找到合适的 grafana dashboard, 即使有，版本也可能有出入。例如上文 Prometheus Operator 自带的 dashboard 只能对应自带的 scrape rule. 其实这里更好的方式是关掉所有 rule 和内建的 dashboard, 然后直接用 mixin 编译成套的 rules + dashboard.
https://github.com/monitoring-mixins/docs
