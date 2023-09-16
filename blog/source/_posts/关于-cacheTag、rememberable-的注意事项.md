---
title: 关于 cacheTag、rememberable 的注意事项
date: 2018-11-29 13:37:19
tags:
    - Laravel
    - Redis
---

很多 Laravel 项目出于额——优雅——会使用 Rememberable 这个库来对查询进行缓存。这里总结几点其使用的注意事项：

### 最基本的，CacheTag 不能当作 Key 来用

Tag 的概念和博客里是一样的，它用来归类大量的 key，同个 Key 也可以归类给多个 Tag，这样去控制缓存非常方便灵活。

但是如果每个查询都单独的使用 Tag，一方面失去意义；另一方面，CacheTag 的 Flush 只会清理它标记的内容和 key，在 Redis 中 Tag 本身作为一个 Set 存储所有 Key，而 RedisTaggedCache 又会为这个 Set 生成一个 standard_ref，两个都不会过期。这样使用 Tag 会遗留大量的 KeySet 和 standard_ref。再怎么 Flush 也不会清理它们的。

### 其次，Rememberable 无法为 paginate 的查询使用 Key

当然这里最好的实践肯定是手动控制分页缓存。但有时没注意就使用 Rememberable 分配 Key，查询结果一定是返回 Count 的结果的缓存。

这是这个插件的原理决定的，它非常简单，代码就一个文件，里面只是继承了 Builder 并重写了其 get 方法。而我们知道，所有其他 builder 的查询诸如 first, count, paginate 等都内部使用 get 来查询。问题是 paginate 的内部有两个查询，Count 和当前查询页的结果。

插件的作者在 issue 中拒绝为了这个把插件变的臃肿。