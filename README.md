# CQUPT Network Tips

## 前言

为了在重邮校园网环境下获得更好的冲浪体验，折腾了一些东西出来，可能有同学能用得上，遂分享给大家。

需要说明的一点是分享的内容都是在运行ImmortalWrt系统的NanoPi R2S设备上长时间使用没有问题的，Linux/Mac设备改改可能就能使用，Windows设备要使用应该需要修改挺多东西，但可以看看思路。

## 网络保活

现在的校园网环境下有时候会莫名奇妙的掉线，甚至还可能重连不上。

因此开发了[网络保活](keep_net_alive.sh)这个脚本。

在掉线且无法重连的经历中发现有掉线后无法获得正常IP地址的情况，这种情况下会拿到169.x.x.x的地址，但我们可以通过修改MAC地址的方式来重新向网关申请IP。

这个脚本的功能是通过登录API检测登录状态，如果已经登录了则什么都不做，如果没有登录则通过ifconfig命令设置一个随机的MAC地址，然后重新获取IP再连接。

将这个脚本配置在cron中使用为最佳。

``` shell
crontab -e

*/5 * * * * /bin/bash /path/keep_net_alive.sh
```

## IP检测

如果要在校园网内网中进行文件传输、远程控制等操作，需要知道对端设备的IP地址，而设备分配到的IP地址又可能发生变化，这就很让人难受。（比如疫情期间在寝室控制实验室的设备，IP变了就连不上，为此还扫了整个10.16.x.x:3389，试图找到我的设备）

[IP检测](ip_detect.sh)这个脚本的功能是检测设备的IP地址是否发生变化，如果发生了变化就推送到Server酱提醒用户。

与网络保活一样也是配置在cron中使用为最佳。

``` shell
crontab -e

*/5 * * * * /bin/bash /path/ip_detect.sh
```

但我现在实际上使用的是DDNS，在ImmortalWrt上跑[ddns-go](https://github.com/jeessy2/ddns-go)，[luci-app-ddns-go](https://github.com/sirpdboy/luci-app-ddns-go)项目。

## 卡千兆网速

曾经有一段时间只要多重新登录几次就有可能解锁千兆网速，但现在已经失效了。[get_giga_net](get_giga_net.sh)这个脚本的功能是不断换MAC地址登录校园网，然后通过下载一个镜像文件测试网速，如果网速达到要求则停止，如果没达到要求重新开始整个流程。需要注意的一点是这个在代码最外层循环有一个“在线控制”，这是由于如果人不在学校且在进行重新登录的操作，但是这个时候突然需要远程到实验室的设备，可以及时的停止。这个“在线控制”可以是任何能通过curl获取到的字符即可，比如自己通过caddy、nginx等做个，或者用github的gist也行。

## 其他

### 关于网速

1. 现在已经无法直接卡出千兆了，但之前有同学提到IPv6没有限速（现在不知道是什么情况）。因此可以准备一个上下行都比较快的VPS或者家用带宽作为中转。最简单的方式是使用tailscale构建虚拟局域网，然后指定外部IPv6设备为endpoint即可。

2. 第二种方法是多找几个同学做多拨，把大家伙的账号登录到一台设备上聚合起来，然后在这台设备上开一个socks代理，其他设备在tun代理模式下走socks到这台设备上网。（尝试过未能实现，卡在了多播，如果多播问题解决了其实还有局域网内部有可能会被限速的问题）

### 多设备

可以在一台固定的设备上运行socks，其他设备在tun模式下代理到这台设备，只需要连接到校园网，不用登录。可以直接裸核跑个[sing-box](https://github.com/SagerNet/sing-box)。如果是服务器需要网络的话，添加以下配置即可：
```
ALL_PROXY="socks5://user_name:password@address:port"
HTTP_PROXY="http://user_name:password@address:port"
HTTPS_PROXY="http://user_name:password@address:port"
```

### 提醒

1. 有同学在常用端口上开socks代理（1080, 1080x, 7890, 789x），且无需身份验证，小心被偷跑喔。