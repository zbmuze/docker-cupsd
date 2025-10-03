# 使用最新的 Debian 稳定版 slim 镜像作为基础
FROM debian:bookworm-slim

LABEL maintainer="muze"
LABEL description="CUPS + Gutenprint for Epson L210/L360 (Printing) + SANE-airscan (Scanning)"

# 设置环境变量以避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# --- 核心修改：将 scanimage 替换为 sane-utils ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    # --- 打印相关 ---
    cups \
    cups-bsd \
    cups-client \
    cups-filters \
    printer-driver-gutenprint \
    gsfonts \
    openprinting-ppds \
    sudo \
    whois \
    # --- 扫描相关组件 ---
    sane-airscan \
    libsane-common \
    # --- 修正：将 scanimage 替换为 sane-utils ---
    sane-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# --- 配置 SANE 允许网络访问 ---
RUN mkdir -p /etc/sane.d/dll.d
RUN echo "airscan" > /etc/sane.d/dll.d/airscan.conf
RUN echo "localhost" > /etc/sane.d/saned.conf && \
    echo "192.168.0.0/16" >> /etc/sane.d/saned.conf

# --- 核心修改：为 Epson L360 添加 sane 驱动配置 ---
# 这行命令会创建一个文件，告诉 SANE 去加载 epson2 驱动模块
RUN echo "epson2" > /etc/sane.d/dll.d/epson2.conf

# 创建用户并加入 lpadmin 和 scanner 组
RUN useradd -m -s /bin/bash -G lpadmin,scanner print \
    && echo "print:print" | chpasswd
RUN apt-get update && apt-get install -y sane-airscan avahi-daemon
# 配置 CUPS 允许远程访问和管理
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin\/conf>/a \  Allow All' /etc/cups/cupsd.conf \
    && echo "ServerAlias *" >> /etc/cups/cupsd.conf

# --- 暴露 SANE 扫描服务端口 ---
EXPOSE 631 6566

# --- 创建启动脚本，同时启动 CUPS 和 SANE 服务 ---
RUN echo '#!/bin/bash' > /usr/local/bin/start-services.sh && \
    echo 'service saned start' >> /usr/local/bin/start-services.sh && \
    echo 'exec /usr/sbin/cupsd -f' >> /usr/local/bin/start-services.sh && \
    chmod +x /usr/local/bin/start-services.sh

# 使用新的启动脚本来启动所有服务
CMD ["/usr/local/bin/start-services.sh"]
