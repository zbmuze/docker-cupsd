仅为自己使用爱普生L360打印机方便

```bash
docker run -d \
-p 631:631 \
--privileged=true \
-v /dev/bus/usb:/dev/bus/usb \
-v /var/run/dbus:/var/run/dbus \
--name mzcupsd \
muze862/mzcupsd:latest
```
登录 CUPS 后台的账号密码：
账号：print
密码：print
