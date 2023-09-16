---
title: GNOME 又激怒了所有人
date: 2021-09-23 10:13:08
tags:
 - GNOME
 - Linux
 - drama
---

## 背景
如果你以前关注 Linux Desktop, 你可能知道 GNOME 早在几年前就联名公开信呼吁社区[不要搞主题](https://stopthemingmy.app/). [Gnome-Looks](gnome-look.org/) 上的那些好看的东西其实是从来不被承认的. 这个事情一直处于争论不休的状态, 但在最近变的更加紧张.

7 月份 GNOME 的[一篇博客](https://blogs.gnome.org/tbernard/2021/07/13/community-power-4/)再次论述了 GNOME 的哲学. 这篇文章里有一些有争议的部分, 例如作者直言全局主题就是一个 “broken idea”, 而且他后面说的更有意思: __如果你不喜欢你应用的外观, 你应该直接去给它们贡献代码.__ 作为一个简中使用者, 我只能说这句话 sounds familiar. 作者又说 Win95 时代的 UI 设计已经死了, 应该用更好的设计去取代任务栏和状态栏(Which is?). 他说每一个可配置项都是有代价的, 应该尽可能避免配置项并解决它底层的问题. 这话听上去很合理, 但作为用户我们知道, 很多时候 GNOME 显然在并没有解决问题的情况下就收回了用户的选择权. 今天几乎每个 GNOME 使用者装完系统第一件事, 就是去安装一个第三方状态栏.

这些听上去很合理实则经不起推敲的东西我个人以及我相信很多人都并不买账(这也是 MATE/Cinnamon 等一干 GNOME2 余孽存在的原因), 但说到底都是个人选择. 真正造成问题的是他们对待用户的这种高傲的态度, 以及在没有解决底层问题之前就收回了选择权.

## 事件
9 月 1 日, System76 的 Pop!\_OS 开发者在推特上抱怨 [GTK4 的暗黑模式无法跟随系统全局样式表](https://twitter.com/jeremy_soller/status/1433085221994258435), 并[提醒](https://twitter.com/jeremy_soller/status/1433088460655452162) GNOME 团队应该了解, Pop!\_OS/Ubuntu 以及其他发行版 __不会因为你不提供 API 就停止修改主题__. 两天后 Jeremy 和 GNOME 开发者 Alexander Mikhaylenko 进行了一连串关于主题样式的[争论](https://twitter.com/jeremy_soller/status/1433487714926698498). 谁知 GNOME 彻底跟 Jeremy 掰了, 驳回了他关于 Recoloring API 的[提交](https://gitlab.gnome.org/GNOME/libadwaita/-/merge_requests/232), 并且 Alexander 在回复中将他在推特上的言辞视为威胁和 “flamebait”, 要求 Jeremy 道歉, 称在道歉之前不会与 System76 的雇员有更多交互. 现在 Jeremy 在 GNOME gitlab 的用户已经处于删除状态.

Jeremy 这番炮轰并非毫无来由, Yaru 和 Feren OS 的开发者都曾私下同他抱怨过 GNOME/GTK 团队非常难以合作. 笔者在 Fedora 上也早就发现 GTK4 应用如 GNOME Extension 不会跟随系统转为暗黑模式. 而且 Jeremy 早在多年前的一个提交中就讨论过这个问题. GNOME 在 18 日的博客中[从他们的视角概括这次事件](https://blogs.gnome.org/alatiera/2021/09/18/the-truth-they-are-not-telling-you-about-themes/), 更多关于 GTK4/libadwaita 这里不再深入, 这篇文章评论里反对的观点也被他们删除干净. 但即便从他们的文章中也很明确的说明了, 在 libwaita 1.0 (尚未发布) 发布之前, 不会有全局主题支持, 而他们的解决方式, 即所谓的 Coloring API 最快也会在 libwaita 2.0 中出现.

所以我可以简单的用一个结论来概括: 他们在解决底层问题之前就拿走了你的选择权. 以前是对用户, 现在是对开发者. GNOME 说开发者有选择, 不喜欢 libadwaita 和 GNOME HIG 大可以不用; 但问题在于 __GTK 是一个 ToolKit__, 在 Toolkit 中硬编码是给开发者制造障碍.

其后就是整个社区的反弹. Solus/Budgie 的开发者 Joshua 一篇长文表达了对 GNOME/GTK 无论是技术还是人的角度充满失望, 宣布要在 Budgie 11 中[舍弃 GTK](https://joshuastrobl.com/2021/09/14/building-an-alternative-ecosystem/). Feren OS 也一篇长文表示[道不同不相为谋](https://medium.com/feren-os/the-future-of-feren-os-theming-for-gtk-94051a64e6de). Inkscape 开发者在 Youtube 上评论 [GNOME 已经不是一个自由软件社区](https://www.youtube.com/watch?v=IFGXVN9dZ8U). 他们的观点都值得一看.

以上大体是这次事件值得关注的部分. 很多 Twitter 上一些 GNOME fanboy 的一些人身攻击和无端指责这里都没有也没必要聊, 以及虽然 Elementary/Pantheon 开发者力挺 GNOME, 但他本人就是 GNOME 基金会成员, 所以抛开这些, 我认为此次事件大体上可以看作 GNOME vs 整个社区. 如果你认为我有偏见, 可以告诉我还有谁站在 GNOME 这边.

## 启示
高傲, 难以沟通, 一意孤行. GNOME 显然对自己在人机交互、设计方面非常自信, 但也使得他们丝毫听不进社区的意见. 显然在 GNOME 眼中, 普通用户乃至一般的贡献者, 是没有发言权的. 如果你不同意他们的设计就不要用. 健康的开源项目离不开用户的反馈和新鲜血液的贡献, 但这都不是 GNOME 想要的. 今天的 GNOME 更像一个 Linux 世界中的 Windows 或 iOS, 设计的初衷就是用户不知道什么是好的设计, 也不应该有过多选择. 这种运作方式或许适合商业公司, 但拿来运作开源项目, 甚至去主导 GTK 这样被大量使用的上游项目, 是非常有问题的.

但弃用 GTK 也会有诸多问题. 推特上有很多人在声援时都推荐 KDE Plasma ~~还有人问 Xfce... 还是省省吧~~, Jeremy 也确实在推上问除 KDE 外有无使用 Kwin 的成功项目. 但从 Joshua 的博文可以看出, 大多 GTK 开发者都是 C 语言出身, 他们比起 Qt/C++ 还是更倾向 C/Rust. 另外 Qt 背后总归是商业公司, 很多人会有顾虑. 而且现在 GTK/Qt 割据的状况已经造成 Linux 桌面生态的很多麻烦, 即便假设其他发行版合力引入新的 Toolkit, 碎片化会成为将来的一个问题.

总而言之, 与主流操作系统不同, 选择 Linux 本身就隐含着一个指向: __我们知道自己在做什么__. 我们不是任由商业公司玩弄的羊群, 而是能够学习和训练自我掌握高阶技能的 power user. 有多少 Linux 玩家不会使用终端? 事实上, 看看类似 i3/Sway 这类 Tiling Window System 重新受到的关注, 看看 wlroots 衍生出的[各种神奇项目](https://wiki.archlinux.org/title/Wayland)(复活了 Plan9 桌面的 wio, 不知道什么鬼的 wayfire...), 社区中激发的种种创意和激情, 都印证了这一点. 用精英主义的态度去对待这样的用户群体是无济于事的.

虽然笔者有自己的观点, 但我个人认为本文总体仍以事实为主(~~但是说真的 Xfce 还是省省吧~~), 并且都附有相关链接, 各位可以自行评判.
