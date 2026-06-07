docker run -d --name mzcupsd-printer --restart unless-stopped -p 631:631 --privileged -v /var/run/dbus:/var/run/dbus -v /dev/bus/usb:/dev/bus/usb -v "$(pwd)/printers.conf:/etc/cups/printers.conf" muze862/mzcupsd:latest 

账号：print 密码：print 存在很多小问题
