仅为自己使用爱普生L360打印机方便

```bash
docker run -d \
--network host \
--privileged=true \
-v /dev/bus/usb:/dev/bus/usb \
-v /var/run/dbus:/var/run/dbus \
--name mzcupsd \
muze862/mzcupsd:latest
```
登录 CUPS 后台的账号密码：
账号：print
密码：print

如果想让打印机在局域网中被 Bonjour / Avahi 发现，建议使用 `--network host` 或者带有本地广播能力的网络模式；仅用桥接网络时，mDNS 广播可能不能被局域网设备正确发现。

鸿蒙设备通常会通过 mDNS / DNS-SD 发现 `_ipp._tcp` 服务；本镜像已按该标准公布 CUPS 服务，因此在同一局域网中，HarmonyOS 可尝试搜索“IPP”或直接访问 `ipp://<容器宿主机IP>:631/ipp/print`。

镜像不创建默认登录账号。需要通过网页管理 CUPS 时，请自行创建一个加入 `lpadmin` 组的系统用户并设置密码。

## Epson 驱动与通用 IPP/RAW

镜像安装 Epson ESC/P-R（`printer-driver-escpr`）和 Gutenprint 驱动，适用于相应驱动支持的 Epson 型号。将 Epson 打印机连接到容器后，在 CUPS 管理页面添加打印机并选择匹配型号的 Epson 驱动，然后启用共享。

目标打印机支持 IPP Everywhere 时，可创建通用免驱队列：

```bash
lpadmin -p ipp-printer -E \
	-v ipp://PRINTER_IP/ipp/print \
	-m everywhere \
	-o printer-is-shared=true
```

将 `PRINTER_IP` 替换为打印机地址。客户端可通过 CUPS 的 IPP 共享队列打印；HarmonyOS 是否能发现并使用队列取决于设备和局域网配置。

需要将已由客户端格式化的作业原样转发时，可创建 RAW 队列：

```bash
lpadmin -p ipp-raw -E \
	-v ipp://PRINTER_IP/ipp/print \
	-m raw \
	-o printer-is-shared=true
```

RAW 不会转换打印数据，只有作业格式与目标打印机兼容时才适用。当前 CUPS 已提示 RAW 队列弃用，建议新建队列优先使用 `-m everywhere`。
