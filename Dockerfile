# 基础镜像
FROM debian:bookworm-slim

# 避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# 添加构建参数而非直接使用环境变量存储敏感信息
ARG CUPS_ADMIN_PASSWORD=print
ENV CUPS_ADMIN_PASSWORD=$CUPS_ADMIN_PASSWORD

# 安装所需软件包
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

# 配置 CUPS 允许远程访问
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i '/<Location \/>/a \  Allow All' /etc/cups/cupsd.conf && \
    sed -i '/<Location \/admin>/a \  Allow All' /etc/cups/cupsd.conf && \
    sed -i '/<Location \/admin\/conf>/a \  Allow All' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    useradd -m print && \
    echo "print:$CUPS_ADMIN_PASSWORD" | chpasswd && \
    usermod -aG lpadmin print

# 添加启动脚本
COPY start-cups.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-cups.sh

# 暴露 CUPS 端口
EXPOSE 631

# 启动服务
CMD ["/usr/local/bin/start-cups.sh"]
