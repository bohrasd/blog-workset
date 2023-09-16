---
title: 利用免费 S3 自建类 Firefox Send 快传服务
date: 2021-09-28 13:37:19
tags:
    - Self-Hosted
---

Firefox Send 是一个 Mozilla 开发的临时通过网页上传并分享文件的工具. 它曾经短暂的运营了一年半左右, 可以方便的将 2GB 以内的文件通过链接发送给别人, 后来因为有很多人通过这种方法[钓鱼和发送病毒](https://support.mozilla.org/en-US/kb/what-happened-firefox-send)而被迫停止运营.
感谢 Forceu 这位开发者的项目 [Gokapi](https://github.com/Forceu/Gokapi/), 我们得以非常方便的自己建立一个同样的服务. 存储可以本地或 S3, 可以通过链接分享并在一段时间内自动清理掉. 可以为文件单独设置允许的下载次数, 失效日期, 分享密码.

![home](https://user-images.githubusercontent.com/1593467/117467861-62861480-af54-11eb-8823-a7b8e60d9017.png)

### Disclamer 1:

通过对其功能的描述, 相信每个人都有自己的判断, 所以这里不去与其他任何工具比较优劣, 只是向读者介绍如何自建这样一个服务.

我自己不喜欢现有商业产品的外观, 广告和各种限制, 而 croc 和 syncthing 又需要文件接收方有客户端, 最终感觉这个是最符合我个人使用场景的.

### Disclamer 2:

对于任何一种自建服务, 我个人认为在 2021 年都应该优先考虑容器/Serverless 的方式建立和部署, 他们更便宜或免费的更彻底, 而且极其有利于后续维护. 我个人没有 VPS, 但并不影响读者使用 VPS 去实现本文介绍的功能.

## 步骤
### 注册 S3

首先你可以去注册任意的 AWS S3 兼容对象存储. 使用本地存储可以跳过. 本文使用七牛演示, 10GB 免费空间. 搜了一下网易数帆有 50GB. 注册过程略过.

然后建立一个对象存储的 Bucket, 这里记得设置为私有空间, 因为 Gokapi 没有对文件进行加密.

然后根据下表决定对应的 S3 参数, 区域和 Endpoint:

![endpoint](https://insidebkt.lanqb.com/qiniu-endpoint.png)

在七牛页面右上角的密钥管理页面获取 AK/SK:

![ak-sk](https://insidebkt.lanqb.com/qiniu-ak-sk.png)

### 配置

然后决定你运行 gokapi 的以下参数:

- GOKAPI_PORT 端口 如8080
- GOKAPI_EXTERNAL_URL 文件链接, 如 http://example.com:8080, 若部署在反代后面就无须带上端口
- GOKAPI_REDIRECT_URL 链接无法访问时重定向到的位置, 可以是你的博客主页
- GOKAPI_USE_SSL 是否使用 SSL, 我没有尝试
- GOKAPI_USERNAME 用户名
- GOKAPI_PASSWORD 密码

以及上一步提到的 S3 参数:
- GOKAPI_AWS_BUCKET
- GOKAPI_AWS_REGION
- GOKAPI_AWS_KEY
- GOKAPI_AWS_KEY_SECRET
- GOKAPI_AWS_ENDPOINT

### 部署和运行

接下来创建应用, 以 [fly](https://fly.io) 为例:

```
fly launch --image f0rc3/gokapi --name your-firefox-send
```

Serverless 用户可以将准备好的参数导入 secret:
```
fly secrets import <<EOF
GOKAPI_PORT=8080
GOKAPI_USERNAME=abc
...
EOF
```

使用 VPS 的用户可以通过 `-e` 选项设置参数:
```
docker run -e GOKAPI_PORT=12345 -e ... -dt -p 127.0.0.1:8080:8080 f0rc3/gokapi:latest
```
没有设置也没关系, 程序会交互性的提醒你设置.

接下来将域名解析到应用或 VPS 的 IP 地址.
fly 用户可直接运行 `fly certs create send.example.com` 解决证书.

接下来, 访问 send.example.com/admin 就可以使用了!

步骤是不是很简单? 是不是感觉 “这也能写一篇?”

从侧面证明了这个软件非常易于使用 ;)

