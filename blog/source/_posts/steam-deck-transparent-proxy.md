---
title: linux 透明代理原理
date: 2024-01-03 20:13:08
tags:
  - linux
---

两年前在自己的 linux 设备上边理解边摆弄过透明代理，本来觉得没什么值得记录的。最近买了 steam deck, 给它搞透明代理的过程中忽然发现有很多细节都忘记了，在这里小记一笔。

## 装 Clash

```
#安装 clash-meta：
nix-env -iA nixpkgs.clash-meta
```

## 透明代理

除了 Tun 以外，Linux 通过 iptables 有两种透明代理的机制， REDIRECT 和 TPROXY.

### REDIRECT

原理是将包的 DESTINATION IP/PORT 修改为本机上代理监听的 IP/PORT。文档里有介绍：

https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html?utm_source=pocket_saves#REDIRECTTARGET

但包的目标地址被改了，代理如何得知原始目标地址呢？对于 TCP 连接来说，可以读取 socket option `SO_ORIGINAL_DST`获得。

著名的服务网格 Linkerd 就使用这一机制从 sidecar 代理进出 Pod 的流量。

但对于 UDP 流量来说就没有这一选项了。

### TPROXY

TPROXY 本身的文档有个很好的例子。
https://www.kernel.org/doc/html/latest/networking/tproxy.html

原理是在本机 iptables mangle 为需要代理的包打一个 mark.

```
iptables -t mangle -A DIVERT -j MARK --set-mark 1
```

这个 mark 是 netfilter policy routing 的一个机制，它不在实际包当中，只是本机进行流量控制打的一个标记。

关于 MARK target: https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html?utm_source=pocket_saves#MARKTARGET

接下来利用 policy routing 把带有 mark 的流量 route 到 loopback 设备，

```
# ip rule add fwmark 1 lookup 100
# ip route add local 0.0.0.0/0 dev lo table 100
```

关于 policy routing: https://theplant.slack.com/archives/C02KZTUKBH8/p1645587411325009

然后在 TPROXY 中把这些接受到的流量发送给代理监听的端口即可。

```
iptables -t mangle -A PREROUTING -p tcp --dport 80 -j TPROXY \
--tproxy-mark 0x1/0x1 --on-port 50080
```

### 解决回环

在实际使用中会遇到一个问题，即一个本来要发出去的包发给代理，代理又要发出去的时候，如果不能区分，可能又会发回给代理。

一个解决方法是，让代理以一个专门的 linux user 运行，这样代理发出的流量都能通过 iptables 的 --uid-owner 来识别。只要先把 uid 为代理的包先 RETURN 即可。

## 一个简单例子

```

#!/bin/bash

[ -z "$(ip ro show tab 100)" ] && ip route add local default dev lo table 100
[ -z "$(ip ru show from all fwmark 0x1)" ] && ip rule add fwmark 1 lookup 100

iptables -t mangle -S clash 2&>1 >/dev/null
[ "$?" != 0 ] && iptables -t mangle -N clash
iptables -t mangle -S clash_out 2&>1 >/dev/null
[ "$?" != 0 ] && iptables -t mangle -N clash_out
iptables -t nat -S clash_dns 2&>1 >/dev/null
[ "$?" != 0 ] && iptables -t nat -N clash_dns

# wifi/蓝牙网络连接
[ -z "$(iptables -t mangle -S OUTPUT | grep clash)" ] && iptables -t mangle -I OUTPUT -o wlp2s0 -j clash_out && iptables -t mangle -I OUTPUT -o bnep0 -j clash_out
[ -z "$(iptables -t mangle -S PREROUTING | grep clash)" ] && iptables -t mangle -I PREROUTING -j clash

iptables -t mangle -F clash
iptables -t mangle -F clash_out
iptables -t mangle -A clash_out -m owner --uid-owner clash -j RETURN

iptables -t mangle -A clash_out -j MARK --set-mark 1 -p tcp
iptables -t mangle -A clash -j TPROXY --tproxy-mark 0x1/0x1 -p tcp --on-port 8891
iptables -t mangle -A clash_out -j MARK --set-mark 1 -p udp
iptables -t mangle -A clash -j TPROXY --tproxy-mark 0x1/0x1 -p udp --on-port 8891

# DNS 请求 redirect 到 clash
[ -z "$(iptables -t nat -S OUTPUT | grep clash_dns)" ] && iptables -t nat -A OUTPUT -p udp --dport 53 -j clash_dns

iptables -t nat -F clash_dns
iptables -t nat -A clash_dns -m owner --uid-owner clash -j RETURN
iptables -t nat -A clash_dns -p udp --dport 53 -j REDIRECT --to-ports 1053

```

Clash systemd, 以单独用户启动及相关权限：

```
[Unit]
Description=clash
After=network.target

[Service]
User=clash
Group=clash
AmbientCapabilities=CAP_NET_BIND_SERVICE CAP_NET_ADMIN
ExecStart=/home/clash/.nix-profile/bin/clash -d /home/clash/.config/clash
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
