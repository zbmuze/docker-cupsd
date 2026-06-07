FROM debian:bookworm-slim
LABEL maintainer="muze <zhmuze@gmail.com>"
LABEL description="Cupsd for Epson L210/L360 (Gutenprint) | HTTP admin support"

# 禁止交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# 安装 CUPS + 爱普生专用驱动
RUN apt-get update && apt-get install -y --no-install-recommends \
    cups \
    cups-filters \
    printer-driver-gutenprint \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# 创建管理用户 print:print 并加入打印管理员组
RUN useradd -m -s /bin/bash -G lpadmin print \
    && echo "print:print" | chpasswd

# 核心配置：开放外网 + 关闭强制HTTPS + 全路径允许访问
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf \
    # 关闭加密，彻底解决 https 强制跳转
    && sed -i 's/DefaultEncryption.*/DefaultEncryption Never/' /etc/cups/cupsd.conf \
    # 全局允许所有IP访问
    && sed -i '/<Location \/>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin\/conf>/a \  Allow All' /etc/cups/cupsd.conf \
    && echo "ServerAlias *" >> /etc/cups/cupsd.conf

EXPOSE 631

# 前台运行 cupsd
CMD ["/usr/sbin/cupsd", "-f"]
