 # docker-cupsd
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## 目录

- [运行服务](#运行服务)
- [向服务器添加打印机](#向服务器添加打印机)
- [在 Mac 上添加打印机](#在-mac-上添加打印机)
- [与 Home Assistant 一起使用](#与-home-assistant-一起使用)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


`cupsd` 的 Docker 容器。

基于 debian:bullseye-slim。包含 [cupsd](https://cups.org) 以及我能想到的所有打印机驱动。

该镜像还自带 Epson ESC/P-R 支持，可覆盖像 L360 这样的 Epson 喷墨机型。

管理员用户名和密码默认是 **print** / **print**

## 构建编号

该仓库支持 Docker 镜像的自动构建编号。运行 `rake build` 会为构建好的镜像打上以下标签：

- `muze862/mzcupsd:latest`
- `muze862/mzcupsd:bookworm-slim`
- `muze862/mzcupsd:build-<number>`

`<number>` 标签来源于 Git 提交计数，并且可以在 CI 中通过 `BUILD_NUMBER` 覆盖。

## 运行服务

使用以下命令启动 `cupsd`：

```sh
cp printers.conf.example printers.conf
sudo docker run -d --restart unless-stopped \
  -p 631:631 \
  --privileged \
  -e CUPS_SERVER_NAME=cups.example.com \
  -v /var/run/dbus:/var/run/dbus \
  -v /dev/bus/usb:/dev/bus/usb \
  -v $(pwd)/printers.conf:/etc/cups/printers.conf \
  -v $(pwd)/ppd:/etc/cups/ppd \
  muze862/mzcupsd
```

如果你通过路由或代理访问 CUPS，请将 `CUPS_SERVER_NAME` 设置为外部主机名，这样重定向地址会保持为公共地址，而不是容器内部 IP。

或者使用以下 `docker-compose.yaml` 和 `docker-compose up`：

```yaml
version: '3.9'
services:
  cupsd:
    image: muze862/mzcupsd
    volumes:
      - './printers.conf:/etc/cups/printers.conf'
      - './ppd:/etc/cups/ppd'
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

将 `printers.conf` 挂载到容器中可以避免在以后升级容器时丢失打印机配置。

> 重要：在首次启动容器之前，先创建本地 `printers.conf` 文件和本地 `ppd` 目录：
> `cp printers.conf.example printers.conf`
> `mkdir -p ppd`
> 否则 Docker 可能会创建空的绑定挂载，而 CUPS 无法保留你的打印机定义。
>
> 注意：单独持久化 `printers.conf` 并不总是足够。当你通过 CUPS Web UI 添加打印机时，CUPS 还会在 `/etc/cups/ppd` 下创建一个 PPD 文件。要在容器重启后保留打印机，请同时持久化 `printers.conf` 和 `/etc/cups/ppd`。
>
> 对于 USB 打印机，队列定义存储在 `printers.conf` 中，但物理设备在断电后仍必须对 CUPS 可用。如果打印机在重启后消失，请确认宿主机上的 USB 设备仍已连接，并且 `/dev/bus/usb` 已挂载到容器中。

## 向服务器添加打印机

1. 访问 `http://cupsd-hostname:631`
2. **Administration** -> **Printers** -> **Add Printer**

## 在 Mac 上添加打印机

1. **System Preferences** -> **Printers**
2. 点击 **+**
3. 点击中间的球形图标
4. 在 Address 字段输入服务器的 IP（或更好是 DNS 名称）
5. 在 Protocol 下拉菜单中选择 `Internet Printing Protocol`
6. 在队列字段中输入 `printers/YOURPRINTERNAME`。

## 与 [Home Assistant](https://www.home-assistant.io/) 一起使用

我写了一篇博客，介绍如何将此镜像与 Home Assistant 一起使用，以便在有打印任务时自动开启我的 HP 4050N 打印机，并在任务完成后关闭它，[详见此处](https://unixorn.github.io/post/home-assistant-printer-power-management/)。不过它适用于任何打印机。
