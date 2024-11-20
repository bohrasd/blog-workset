---
title: Steam Deck 用 nix
date: 2024-01-03 10:00:00
tags:
  - linux
---


Steam OS 是一个 immutable system，steam deck 的软件仓库默认只有 flatpak，这个仓库没什么命令行软件.

强行打开 arch 仓库需要修改系统，而且升级 OS 后会丢失。

需要的命令行软件直接下载 binary 到 /home 也可以，也有人通过 homebrew 安装据说也不会丢失。但个人喜欢 nix。

### 配置 nix

Steam OS 官方[听到了](https://linuxgamingcentral.com/posts/steamos-getting-nix-support/)社区希望支持 nix 的呼声，新版本 Steam OS 3.5 提供了 `/nix` 目录，确保升级后不会丢失。

Determinate System 提供了一个支持 Steam OS 的安装脚本，这里介绍了原理： https://determinate.systems/posts/nix-on-the-steam-deck#an-invitation-to-experiment , 对原理没有兴趣可以直接

```
curl -L https://install.determinate.systems/nix | sh -s -- install steam-deck

#清华 nix 源：https://mirrors.tuna.tsinghua.edu.cn/help/nix-channels/
nix-channel --add https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixpkgs-unstable nixpkgs
nix-channel --update
```

接下来就可以装 home-manager 把其他地方的配置一口气搬过来。
