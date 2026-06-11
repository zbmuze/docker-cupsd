仅为自己使用爱普生L360打印机方便

docker run -d \
--name mzcupsd-printer \
--restart unless-stopped \
-p 631:631 \
--privileged \
-v /var/run/dbus:/var/run/dbus \
-v /dev/bus/usb:/dev/bus/usb \
muze862/mzcupsd:latest

账号：print 密码：print
