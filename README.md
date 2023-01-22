# Natter-Cloudflare-Redirect

一个简单的Bash脚本，用来配合natter自动修改cloudflare的重定向规则。
natmap应该也可以用，调调参数就行了。

因为我在用qBittorrent，所以我把[qBittorrent-NAT-TCP-Hole-Punching](https://github.com/Mythologyli/qBittorrent-NAT-TCP-Hole-Punching)也塞进去了。

当前的实现方法非常绿皮（这不重要，能跑就行。）

`https://api.cloudflare.com/client/v4/zones/${ZONE}/rulesets/${RULE}` 就好像linux的 `>` ,会清空重定向规则列表并重新添加一条。
`https://api.cloudflare.com/client/v4/zones/${ZONE}/rulesets/${RULE}/rules` 则像linux的 `>>`，会在规则列表里添加一条，但并不会覆盖名称完全相同的另一条。(试的时候loop没停住，刷了十条名字一样内容一样的，然后才开始报错...看的挺〇疼的)

所以当前的做法是先清空再重新添加。

如果有更好的实现方式，欢迎fork&PR。

## 感谢 
[Natter](https://github.com/MikeWang000000/Natter)

[NatMap](https://github.com/heiher/natmap)

[qBittorrent-NAT-TCP-Hole-Punching](https://github.com/Mythologyli/qBittorrent-NAT-TCP-Hole-Punching)


### 题外话
CF的Origin Rules也可以实现类似效果，但是必须从CF cdn回源（也就是要把CloudFlare的代理打开），在外面访问的时候效果不是很好。因此写了这个重定向的~~垃圾~~脚本。

302而不是301是因为浏览器缓存，万一端口变了解析变了浏览器还照着301的缓存去跳转就尴尬了
