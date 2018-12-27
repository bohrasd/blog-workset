---
title: ubuntu 配置 uwsgi 踩坑
date: 2018-08-15 17:41:29
tags:
---

[](#uwsgi-配置 "uwsgi 配置")uwsgi 配置
--------------------------------

[配置文件编写](https://uwsgi-docs-zh.readthedocs.io/zh_CN/latest/Configuration.html)

总的来讲，uwsgi 配置可以有任意类型任意格式，相互之间可嵌套，非常灵活。

参考了[这里](https://www.oschina.net/translate/serving-flask-with-nginx-on-ubuntu)采用将配置文件放在子站点目录，再将各处的文件ln 链接到 /etc/uwsgi/vassals 中，再由 /etc/uwsgi/emperor.ini 囊括起来

    [uwsgi]
    emperor = /etc/uwsgi/vassals
    uid = www-data
    gid = www-data
    

站点的配置文件主要是要指定 base 下的 app 文件的 module 模块的可执行 callable.  
sock 文件会在 uwsgi 启动后自动生成。  
配置 sock 文件的权限。nginx 和 uwsgi 的用户同为 www-data ，可以放心配置为 644.

另外，日志和配置的权限都要配置给 www-data.

坑：由于现在一般采用 pip3 安装最新版的 uwsgi，所以已经无须配置 plugin = python. 否则会报错：

    UNABLE to load uWSGI plugin: ./python_plugin.so: cannot open shared object file: No such file or directory !!!
    

[](#uwsgi-服务 "uwsgi 服务")uwsgi 服务
--------------------------------

Vladikk 虽然前面讲的很好，但是文章很老了，ubuntu 服务方面，他还在采用 13.04 版本默认的 Upstart. 新版的默认服务已经采用 systemd. 关于三种服务的详细介绍可参看[这里](https://www.ibm.com/developerworks/cn/linux/1407_liuming_init1/index.html)

Upstart 的配置在 /etc/init 中，这里不做介绍。过去我常用的 vps 默认都是 sysvinit. 网上有[现成的脚本](https://gist.github.com/dlebech/3fd9a86abf0a980446cf)。

而 Systemd 的配置位于/lib/systemd/system/uwsgi.service

    [Unit]
    Description=uWSGI Emperor
    After=syslog.target
    
    [Service]
    ExecStart=/home/.pyenv/versions/3.7.0/bin/uwsgi --ini /etc/uwsgi/emperor.ini
    RuntimeDirectory=uwsgi
    Restart=always
    KillSignal=SIGQUIT
    Type=notify
    NotifyAccess=all
    
    [Install]
    WantedBy=multi-user.target
    

这里只要正确配置 uwsgi 的目录，用参数方式启动就行。log 可以删掉，只要 uwsgi 配置文件里有 log 就可以。
