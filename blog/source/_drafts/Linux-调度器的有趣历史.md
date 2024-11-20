---
title: Linux 调度器的有趣历史
date: 2021-12-23 16:03:59
tags:
---

### 调度器
2007 年 Linux 从 O(1) 换为 CFS 调度前后，也实现了分组调度的功能。CFS 和 O(1) 的区别在 (OSTEP)[https://pages.cs.wisc.edu/~remzi/OSTEP/#book-chapters] 一书中有描述，大概可以理解为 O(1) 是前面的优先级调度，CFS 类似于后面的步长调度，只不过使用的是红黑树，总是去树最左侧时长最短的进程执行。除了 CFS，linux 保留的实时进程的两种类型：FIFO 和 RR 也是书中介绍过的。关于调度器更换也有一段[争论](https://en.wikipedia.org/wiki/Con_Kolivas)，但那是另一个故事了。

还有一些背景。htop 中 `NI` 这一列是进程的 niceness 值。翻一翻发现大都是0，除了一些桌面环境的后置应用会有正值。调出 `PGRP` 和 `SESSION` 这两列，发现他们的数值大都是一样的。Linux 进程属于 session，session 中有很多进程组，其中只有一个活动的进程。在终端执行一个命令，`htop` 中就能看到执行的命令和终端属于同一 session, 但是不同的进程分组，因为你执行命令导致你的终端被后置了。下面开始讲故事。

### back and forth
Linus 经常需要编译内核，在这个漫长等待的过程中，他想用电脑看看视频放松一下。在讨论这个问题时他们描述这个场景：编译时指定 `make -j 10`，打开视频，每个进程就都得到了 9% 的 CPU. 如果能够使用[分组调度](https://lwn.net/Articles/240474/)，编译和视频属于不同分组，就能各占 50% CPU 时间，确保流畅的观影体验。但是分组调度设计的本意是，当不同用户登录时各自的进程进入不同分组，能获得公平的 CPU 时间。但这个功能并没有给用户方便的使用途径。

Linus 非常中意[基于 TTY 的调度](https://lwn.net/Articles/415742/)，基本想法是按照 TTY 进行分组，没有绑定的放进 root 分组。他在自己电脑上测试之后感觉编译的同时[上网快多了](https://lwn.net/Articles/415748/)，他说「这个补丁肯定是”真正有改进“那种补丁，分组调度从“对某些特定服务器有用” 变成 “这是个杀手级特性”。」

此时 Systemd/Cgroup 明显已经在着手解决这个问题了，所以很多来自 RedHat 的开发者们表达了不同的看法。Vivek Goyal 认为此事应该在用户空间中解决，并且介绍了他们可能已经在进行的工作。

内核开发者的工作方式和普通用户应该大不相同。他们喜欢打开很多 TTY 在不同的 TTY 中做不同的工作；而普通用户用的大多数桌面环境都只从一个 TTY 启动。打开 htop 你会发现除了 DM 和 DE 的启动进程以外，大多数进程都没有绑定 TTY.

接下来就是一段大家喜闻乐见的口舌之争，Linus 用他一贯的不屑攻击用户空间: "fragmented mess", "user-space daemons are a total mess", "The 'flexibility' tends to be more a flexibility to get things wrong", "would be a total nightmare".

Systemd 的作者 Lennart Poettering 众所周知不是一个善茬。他声称使用 systemd 的发行版已经给每个 session 创建了 systemd cgroup， 所以他只要接下来为每个 session 创建 CPU cgroup 就能更好的做到这件事。他回击 "Binding something like this to TTYs is just backwards".
Linus 对他还没做完就说三说四很不买账："Numbers talk, bullshit walks."，没有数据，nobody cares.
Lennart Pottering 当场演示了一个 cgroup 的例子。
争论的焦点就变成了是应该内核做好一切还是由用户空间配置的问题。还有人引用美国总统的名言：「放弃自由换取暂时的安全者，不配拥有自由和安全。——本・富兰克林」「历史的教训告诉我们当政府扩张，自由就会收缩。——托马斯・杰斐逊」

今天此事如何尘埃落定呢？ AutoGroup 和 CGroup。使用 Systemd 的系统，也就是大多数系统中进程都会自动被分配 cgroup，覆盖 AutoGroup 的设置
