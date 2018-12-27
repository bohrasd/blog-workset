---
title: 怎样允许 uwsgi 用户通过 webhook 操作 git
date: 2018-08-07 07:48:32
tags:
---

*   为该用户生成 ssh-key


	sudo -u www-data ssh-keygen -t rsa  

*   将公钥加在代码托管平台
    
*   生成 known_hosts
    

	ssh-keyscan -H github.com >> /var/www/.ssh/known_hosts   

*   将.ssh 下的文件权限属于该用户。

其实你自己用git 也是一样，只不过提示加 known_hosts 的时候你无脑按过 yes 了
