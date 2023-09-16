---
title: Handle access log with fluent bit
date: 2020-04-15 20:13:08
tags: kubernetes logging fluent-bit
---

*发现好多人渣到处爬别人博客。改成英文标题试试看会不会缓解。实在不行以后就只写英文技术文章。*

将 istio sidecar 的 access_log 配置为 JSON 之后，我以为万事大吉了。fluent bit 的 kubernetes filter 会自动 Merge Log. 没想到 istio 的 proxyv2 并没有直接使用 Envoy 那套格式，而是固定了 TEXT 和 JSON, 所以也不存在什么 typed_json. 而 JSON 格式里的响应时间、返回码全都是固定带双引号，会被 ECK 解析为字符串。本来手动写了个 ACCESS_LOG_FORMAT, 这时一位德高望重的前辈提醒我不如趁此机会直接通过 fluent bit 搞定这个问题，把 access log 单独输出到一个 index 里面。

Fluent bit 里面有几个重要的概念。数据通过 input 读进来时，可以打上 TAG; parser 可以格式化数据，filter 可以各种操作数据，但是它们都不对 TAG 做操作，直到 1.4 才加入了 rewrite_tag 这个更为灵活的东西。filter 和 output 都可以 MATCH 这些 TAG.

而 kubernetes 这个 filter 就非常重要。Fluent bit 为 k8s 的使用者推荐了「tail + kubernetes filter」这样一种工作流。它通过 tail input 读入以后，tail 给它打上了 path 转换成的 tag, 将「/var/log/文件名.log」转为「kube.var.log.文件名.log」。接下来 kubernetes filter 需要你提供路径部分到 Kube_Tag_Prefix, 这样它就能读取到文件名。然后它内置一个正则表达式
`(?<pod_name>[a-z0-9](?:[-a-z0-9]*[a-z0-9])?(?:\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*)_(?<namespace_name>[^_]+)_(?<container_name>.+)-(?<docker_id>[a-z0-9]{64})\.log$`
自动解析出 pod namespace container 等信息。

*由于我一开始对各种概念不够了解，当时认为一个 input 只会有一个 TAG, 所以考虑用 rewrite_tag 来更改 TAG 实现输出到多个 output. 最后发现 rewrite_tag 里的 rule 的正则无比的耗费 cpu. 办公室里我的笔记本风扇发出了惨叫。*

后来在 github issue 里发现很多人都遇到这个需求。他们采取的方式是直接在 tail 的 input 里带上 TAG_REGEX 解析出 pod/container/namespace 信息，然后直接打成 TAG. 聪明。接下来的问题是 kubernetes filter 无法解析这个已经解析过的 TAG 了，其实只要附上 REGEX_PARSER 替代内置的正则即可。最后增加一个 OUTPUT 即可输出到多个 index.

*中间出过一些小插曲，比如没设置旧日志读取时间，搞得 fluent bit 压力极大不停的 backpressure, 我还在疑惑为何刚才的操作没有被记录等愚蠢状况。*

接下来的操作就很简单了，设置一个符合 istio-proxyv2 格式的正则，写个 parser filter 即可方便的搜索 access log. 其实 fluent bit 内置的正则 parser 里有 envoy 格式，但是 istio 的 proxyv2 修改过这个格式，多一些信息。辛辛苦苦抠的，改天我把这个正则也贴过来。

```
    [PARSER]
        Name        k8s-nginx-ingress-typed
        Format      regex
        Regex       ^(?<host>[^ ]*) - (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*) "(?<referer>[^\"]*)" "(?<agent>[^\"]*)" (?<request_length>[^ ]*) (?<request_time>[^ ]*) \[(?<proxy_upstream_name>[^ ]*)\] (\[(?<proxy_alternative_upstream_name>[^ ]*)\] )?(?<upstream_addr>[^ ]*) (?<upstream_response_length>[^ ]*) (?<upstream_response_time>[^ ]*) (?<upstream_status>[^ ]*) (?<reg_id>[^ ]*).*$
        Time_Key    start_time
        Time_Format %d/%b/%Y:%H:%M:%S %z
        Types code:integer size:integer request_time:float upstream_status:integer upstream_response_time:float
```

