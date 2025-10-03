# docker-cupsd
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Table of Contents

- [Run the server](#run-the-server)
- [Add printers to server](#add-printers-to-server)
- [Add the printer to your Mac](#add-the-printer-to-your-mac)
- [Use with Home Assistant](#use-with-home-assistant)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


`cupsd` in a docker container.

Based on debian:bullseye-slim. Includes [cupsd](https://cups.org) along with every printer driver I could think of.

Admin user & passwords default to **print** / **print**

## Run the server
仅为自己使用爱普生L360打印机方便
Start `cupsd` with:
```sh
docker run -d --name mzcupsd-printer --restart unless-stopped -p 631:631 --privileged -v /var/run/dbus:/var/run/dbus -v /dev/bus/usb:/dev/bus/usb -v "$(pwd)/printers.conf:/etc/cups/printers.conf" muze862/mzcupsd
```
打印机和扫描仪  
```sh
docker run -d --name mzcupsd-printer-scan --restart unless-stopped -p 631:631 -p 6566:6566 --privileged -v /var/run/dbus:/var/run/dbus -v /dev/bus/usb:/dev/bus/usb -v "$(pwd)/printers.conf:/etc/cups/printers.conf" -v "$(pwd)/sane:/etc/sane.d" muze862/mzcupsd
```
Mounting `printers.conf` into the container keeps you from losing your printer configuration when you upgrade the container later.

## Add printers to server

1. Connect to `http://cupsd-hostname:631`
2. **Adminstration** -> **Printers** -> **Add Printer**

## Add the printer to your Mac

1. **System Preferences** -> **Printers**
2. Click on the **+**
3. Click the center sphere icon
4. Put the IP (or better, DNS name) of your server in the Address field
5. Select `Internet Printing Protocol` in the Protocol dropdown
6. Put `printers/YOURPRINTERNAME` in the queue field.

## Use with [Home Assistant](https://www.home-assistant.io/)
I blogged how I use this with Home Assistant to automagically turn on my HP 4050N printer when there are print jobs and turn it back off when the jobs are complete [here](https://unixorn.github.io/post/home-assistant-printer-power-management/), but it'll work with any printer.
