仅为自己使用爱普生L360打印机方便

```bash
docker run -d \
  --network host \
  --privileged=true \
  -v /dev/bus/usb:/dev/bus/usb \
  -v /var/run/dbus:/var/run/dbus \
  -e CUPS_ADMIN_PASSWORD='替换为你自己的强密码' \
  --name mzcupsd \
  muze862/mzcupsd:latest
```

容器启动时会创建加入 `lpadmin` 组的 `print` 管理账号，密码由 `CUPS_ADMIN_PASSWORD` 设置。也可以通过 `CUPS_ADMIN_PASSWORD_FILE` 指定容器内可读的密码文件（例如 Docker secret）。未设置密码变量时不会创建管理账号。环境变量可能出现在容器配置中，敏感部署建议使用密码文件。

局域网设备通过 Bonjour / Avahi 发现打印机时，请使用 `--network host`。桥接网络通常无法将 mDNS 广播正确传到局域网。添加打印机后，还要在 CUPS 中启用该队列并勾选“共享此打印机”；只有实际共享的队列会被公布。

鸿蒙设备通常通过 mDNS / DNS-SD 搜索 `_ipp._tcp` 服务。确认容器和设备位于同一局域网且未启用无线客户端隔离；也可先在浏览器打开 `http://<容器宿主机IP>:631/printers/` 检查队列是否可访问。IPP 地址使用 CUPS 实际队列路径 `ipp://<容器宿主机IP>:631/printers/<队列名>`。

## Epson 驱动与通用 IPP/RAW

镜像安装 Epson ESC/P-R（`printer-driver-escpr`）和 Gutenprint 驱动，适用于相应驱动支持的 Epson 型号。将 Epson 打印机连接到容器后，在 CUPS 管理页面添加打印机、选择匹配型号的 Epson 驱动，并启用该队列及“共享此打印机”。也可以用 `lpadmin -p <队列名> -o printer-is-shared=true` 设置队列共享。

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
