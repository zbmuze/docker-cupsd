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

This image also ships Epson ESC/P-R support, which covers Epson inkjet models such as the L360.

Admin user & passwords default to **print** / **print**

## Build numbering

The repository supports automatic build numbering for Docker images. Running `rake build` will tag the built image as:

- `unixorn/cupsd:latest`
- `unixorn/cupsd:bookworm-slim`
- `unixorn/cupsd:build-<number>`

The `<number>` tag is derived from the Git commit count, and can also be overridden with `BUILD_NUMBER` in CI.

## Run the server

Start `cupsd` with:

```sh
cp printers.conf.example printers.conf
sudo docker run -d --restart unless-stopped \
  -p 631:631 \
  --privileged \
  -e CUPS_SERVER_NAME=cups.example.com \
  -v /var/run/dbus:/var/run/dbus \
  -v /dev/bus/usb:/dev/bus/usb \
  -v $(pwd)/printers.conf:/etc/cups/printers.conf \
  unixorn/cupsd
```

If you access CUPS through a route or proxy, set `CUPS_SERVER_NAME` to the external host name so redirects stay on the public address instead of the container’s internal IP.

or use `docker-compose up` with the following `docker-compose.yaml`:

```yaml
version: '3.9'
services:
  cupsd:
    image: unixorn/cupsd
    volumes:
      - './printers.conf:/etc/cups/printers.conf'
      - '/dev/bus/usb:/dev/bus/usb'
      - '/var/run/dbus:/var/run/dbus'
      - /etc/hostname:/etc/hostname:ro
      - /etc/localtime:/etc/localtime:ro
      - /etc/machine-id:/etc/machine-id:ro
      - /etc/timezone:/etc/timezone:ro
    privileged: true
    ports:
      - '631:631'
    restart: unless-stopped
```

Mounting `printers.conf` into the container keeps you from losing your printer configuration when you upgrade the container later.

> Important: create a local `printers.conf` file before first starting the container:
> `cp printers.conf.example printers.conf`
> Otherwise Docker may create an empty bind mount and CUPS will not preserve your printer definitions.
>
> Note: `printers.conf` alone is not always enough. When you add a printer through the CUPS web UI, CUPS also creates a PPD file under `/etc/cups/ppd`. To keep printers after a container restart, persist both `printers.conf` and `/etc/cups/ppd`.
>
> For USB printers, the queue definitions are stored in `printers.conf`, but the physical device must still be available to CUPS after power-cycling. If the printer disappears after reboot, confirm the host USB device is still attached and that `/dev/bus/usb` is mounted into the container.

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
