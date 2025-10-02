# 使用 Debian 稳定版作为基础镜像
FROM debian:bookworm-slim

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    CUPS_ADMIN_USER=print \
    CUPS_ADMIN_PASSWORD=print

# 安装 CUPS 及打印机驱动
RUN apt-get update && apt-get install -y --no-install-recommends \
    cups \
    cups-bsd \
    cups-filters \
    printer-driver-all \
    printer-driver-gutenprint \
    printer-driver-hpcups \
    hpijs-ppds \
    hplip \
    && rm -rf /var/lib/apt/lists/*

# 配置 CUPS
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i '/<Location \/>/a \  Allow All' /etc/cups/cupsd.conf && \
    sed -i '/<Location \/admin>/a \  Allow All' /etc/cups/cupsd.conf && \
    sed -i '/<Location \/admin\/conf>/a \  Allow All' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    useradd -m $CUPS_ADMIN_USER && \
    echo "$CUPS_ADMIN_USER:$CUPS_ADMIN_PASSWORD" | chpasswd && \
    usermod -aG lpadmin $CUPS_ADMIN_USER

# 暴露端口
EXPOSE 631

# 启动脚本
COPY start-cups.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-cups.sh

CMD ["/usr/local/bin/start-cups.sh"]
