---
title: 用 HashiCorp Vault 代替在线密码管理器
date: 2021-08-05 20:59:22
tags:
    - vault
    - terminal
---

LastPass 宣布移动端或网页端只支持一种设备以后, 我换到了 BitWarden. 有一些不如意的地方, 但不重要. 我最近心血来潮, 想看看以前尝试过的 KeePass 做的怎样. 我在寻找 Firefox 插件的时候发现了 [Tusk](https://github.com/subdavis/Tusk), 一款 Vue 写的插件. 这款插件已经停止维护了, 我看到作者在 README 中写道:

>  **Why is it unsuppored?** Because I no longer prefer the keepass ecosystem.  I believe version control and data sync should be a core feature of any password manager.

然后他说自己已经切换到 [pass](https://www.passwordstore.org/). 一个自称符合 Unix 哲学的密码管理器.
我不清楚这款产品怎样, 但我一想, 虽然是一个团队级协作的产品, 但 Vault 其实非常符合他说的, 有版本控制, 有 cli, 锦上添花的是它还支持保存你的云 Credential, 你的 ssh-key, 你的证书, 你的数据库密码……堪称运维福音. 我搜了搜 github, 万万没想到还真有人做了 [vaultPass](https://github.com/mulbc/vaultPass/) 这个浏览器插件. 与其去研究什么 pass, 我还不如直接给自己起个 vault 当密码管理器.

### 使用 vaultPass 大致流程:

方法很简单, 看看自己有什么方便的 https://www.vaultproject.io/docs/configuration/storage 在手头. 我直接去注册了一个免费的 S3 对象存储.

配置也很简单, 然后随便找个免费的 Serverless 服务丢上去, 我极其喜欢 https://fly.io/, 可惜他们没邀请活动之类的, 不然我天天帮他们打广告.

vault 起来以后, 需要建一个名为 secret 的 kv 存储.
```
vault secrets enable -path=secret kv-v2
```

然后启用 LDAP 或用户名密码登录
```
vault auth enable userpass
```

然后把 bitwarden 导出的 json 转成我们想要的格式

```
cat bitwarden_export_20210805144230.json | jq -rc ".items | .[] | select(.login.password != null) | .name, {title: .name, username: .login.username, password: .login.password, comment: .login.uris[0].uri}" > vault-compatible.jsonl
```

然后导入 vault

```
cat vault-compatible.jsonl | sed 's/"/\\"/g' | xargs -n2 zsh -c 'vault kv patch secret/vaultPass/bohr/$0 @<(echo $1)'
```

然后插件里填上部署的 vault 的域名, 用户名密码, 就完事了! 它似乎是根据 kv 文件名去检测域名. 都是在线获取所以需要网速好, 自动填充,
复制粘贴用户名密码都能正常使用. 不能自动识别和保存密码, 需要手动在终端 put 密码.

但不重要, 重要的是可以有条理的存各种 secret 各种 key, 甚至支持阿里云 RAM 那些玩意, 更重要的是很酷, 不走寻常路.

手机端只能希望哪位移动端大佬做了. 暂时别想了.
