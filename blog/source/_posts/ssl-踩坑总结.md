---
title: ssl 踩坑总结
date: 2018-08-08 18:20:08
tags:
published: false
---

# 申请证书
--------------------

acme.sh 早已支持通配符域名证书。

1.  godadday 获取 Key 和 Secret，dns 验证
2.  [各种域名商的DNS API 方式](https://github.com/Neilpang/acme.sh/tree/master/dnsapi)

        acme.sh --issue --dns dns_gd -d example.com -d *.example.com



# nginx-配置
--------------------------------

*   加密配置 ssl_ciphers

该配置推荐采用 [谋智推荐的 ssl 配置生成器](https://mozilla.github.io/server-side-tls/ssl-config-generator/)
，其中 server version 是 nginx 版本， 而 openssl 版本是

    cd /etc/ssl/certs && openssl version


*   手动生成 DHE 强交换参数 ssl_dhparam

        cd /etc/ssl/certs
        openssl dhparam -out dhparam.pem 4096


*   配置中加入

        ssl_dhparam /etc/ssl/certs/dhparam.pem;


*   [全部安全建议](https://linux.cn/article-5374-1.html)


最后可以通过 MySSL.com 或 [www.ssllabs.com](http://www.ssllabs.com) 检测效果。

{% asset_img test_score.png ssllabs得分 %}
