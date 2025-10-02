# 基于 x86 架构的 OpenWRT 基础镜像（以 64 位为例）
FROM openwrtorg/rootfs:x86_64

# 安装依赖（x86 架构支持更完整的 CUPS 组件）
RUN opkg update && \
    opkg install \
      cups \
      cups-bsd \
      cups-filters \
      cups-libs \
      printer-driver-gutenprint \
      printer-driver-cups-pdf \
      sudo \
      dbus \
      usbutils \
      curl \
      # x86 额外支持的网络打印组件
      samba36-client \
      avahi-daemon \
    && rm -rf /var/cache/opkg/*

# 创建用户（适配 OpenWRT 的 ash shell）
RUN useradd \
    --groups=sudo,lp,lpadmin \
    --create-home \
    --home-dir=/home/print \
    --shell=/bin/ash \
    print \
  && echo "print:print" | chpasswd \
  && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 配置 CUPS（启用网络发现，适配 x86 网络性能）
RUN sed -i '/^Port 631/a ServerAlias *' /etc/cups/cupsd.conf && \
    # 允许 Avahi 服务发现（x86 支持更好）
    sed -i 's/^#BrowseLocalProtocols/BrowseLocalProtocols/' /etc/cups/cupsd.conf && \
    sed -i '0,/^</s//DefaultEncryption IfRequested\n&/' /etc/cups/cupsd.conf && \
    # 启动 CUPS 并应用配置
    /usr/sbin/cupsd && \
    while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done && \
    cupsctl --remote-admin --remote-any --share-printers --enable-browsing && \
    kill $(cat /var/run/cups/cupsd.pid)

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:631/ || exit 1

# 启动服务（同时启动 Avahi 用于网络发现）
CMD ["/bin/sh", "-c", "avahi-daemon --daemonize && /usr/sbin/cupsd -f"]
