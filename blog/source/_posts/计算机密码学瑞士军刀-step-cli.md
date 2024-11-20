---
title: 计算机密码学瑞士军刀 step-cli
date: 2021-10-09 13:45:59
tags:
 - 加密
 - cli
---

`step-cli` 是一个几乎全功能的密码学终端。通常说起这类工具我们第一反应是 `openssl` 或 cloudflare 出品的 `cfssl`. 但 smallstep 出品的 `step-cli` 有很多额外的好处。最近体验了一下，还是非常推荐的。

### 优点

#### 人性化

我最常用的一个功能是 `step ceritificate inspect https://xxx.com` 直接查看我管理的网站的证书过期时间。直接通过 url 就能看到人性化展示的证书内容，`--short` 可以简便看到过期时间。openssl 虽然有 `openssl s_client -connect 1.2.3.4:443 -showcerts < /dev/null`，但显示的结果远没有 step 那么友好，命令也不是很便捷。

生成证书，生成和签名 CSR 等也十分方便。语法也比较平易近人。openssl 也能摸清它的规律，但往往用起来容易让人不知所措，例如第一次用的人容易不确定应该 `rsa`, `genrsa` 还是 `rsautl`; 证书的功能分布在 `ca` `asn1parse` `x509`, 以及我自己也分不清 `pkcs7`, `pkcs8`, `pkcs12`. 但在 step 中所有涉及证书的工具都被 `step certificate` 解决了。

最人性化的地方是它的 help 信息十分全面详尽，大多数情况下都有安全使用的范例，你只通过终端就能知道各种命令的用法。所以本文就算想要介绍用法也只不过是拷贝文档中的例子而已。

#### 功能全
它除了 openssl 中那些基础的工具，还囊括了 JOSE (JWT/JWE/JWS/JWK), 还有 NACL/OTP/OAUTH/OIDC, 甚至能够运行自己的 PKI, 还能方便通过证书统一管理主机的 SSH 认证。应有尽有。

`step crypto jwt inspect` 可以直接检查 jwt 的内容, 与其他命令组合例如：

```
kubectl get secret default-token-abcde -o jsonpath='{.data.token}' | base64 -d | step crypto jwt inspect --insecure
```
即可获得 jwt 的 json 内容。本地有 key 还可以 `step crypto jwt verify` 可以检查 jwt 签名。其他 JWK/JWE/JWS 功能不一一列举。

还有 `step crypto hash` 生成和比较摘要，`step crypto otp` 生成一次性密码，等等。

#### 安全
step 的一大好处是为用户考量了安全性，所以所有不安全的操作都需要手动指定，甚至不允许。例如生成密钥对默认使用椭圆曲线而不是 RSA; 生成证书或密钥对时会默认要求提供密码；hash 的默认算法是 SHA-256；JWT 不允许任意指定 key 进行签名，而必须要使用 jws.

step 最重要的理念在于，普通人即便懂得密码学的原理，也不应该自己过分涉及任何细节。它只暴露最终用户实际工作中需要的东西，算法只是在生成过程中指定的一个参数而已。所以小白也可以非常安全的使用, 一旦涉及不安全的内容都需要显式指定 `--insecure`.

密码学是一个完全不同的学科。任何专家都乐于告诉你原理，但他们永远会建议你，遵循最佳实践，不要自己实现现有的工具。普通人遑论实现加密，即便是安全的使用现有的密码学工具都非常困难。很多能力很强的工程师都会在这个问题上犯错误[1](https://twitter.com/Blankwonder/status/1471339829489070084)[2](https://github.com/shadowsocks/shadowsocks-org/issues/64#issuecomment-292788339)。

### 缺点
在使用中优点有时也会变成缺点。比如 step 默认生成密钥对的 key 是密码加密的，很多地方不支持；比如不允许任意指定 JWS 签名用的 key。因为安全限制了很多使用场景。
