# 使用最新的 Debian 稳定版 slim 镜像作为基础
FROM debian:bookworm-slim

LABEL maintainer="Your Name"
LABEL description="CUPS + Gutenprint for Epson L210 (Printing) + SANE-airscan (Scanning)"

# 设置环境变量以避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# --- 核心修改：在打印基础上增加扫描功能 ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    # --- 打印相关 (保持不变) ---
    cups \
    cups-bsd \
    cups-client \
    cups-filters \
    printer-driver-gutenprint \
    gsfonts \
    openprinting-ppds \
    sudo \
    whois \
    # --- 新增：扫描相关组件 ---
    sane-airscan \
    libsane-common \
    scanimage \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# --- 新增：配置 SANE 允许网络访问 ---
# 创建 SANE 配置目录
RUN mkdir -p /etc/sane.d/dll.d
# 创建配置文件，启用 airscan 后端
RUN echo "airscan" > /etc/sane.d/dll.d/airscan.conf
# 修改 SANE 网络配置，允许来自任何网络的连接
RUN echo "localhost" > /etc/sane.d/saned.conf && \
    echo "192.168.0.0/16" >> /etc/sane.d/saned.conf

# 创建一个名为 'print' 的用户，并加入 lpadmin 和 scanner 组
RUN useradd -m -s /bin/bash -G lpadmin,scanner print \
    && echo "print:print" | chpasswd

# 配置 CUPS 允许远程访问和管理 (保持不变)
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin\/conf>/a \  Allow All' /etc/cups/cupsd.conf \
    && echo "ServerAlias *" >> /etc/cups/cupsd.conf

# --- 新增：暴露 SANE 扫描服务端口 ---
EXPOSE 631 6566

# --- 新增：创建一个启动脚本，同时启动 CUPS 和 SANE 服务 ---
RUN echo '#!/bin/bash' > /usr/local/bin/start-services.sh && \
    echo 'service saned start' >> /usr/local/bin/start-services.sh && \
    echo 'exec /usr/sbin/cupsd -f' >> /usr/local/bin/start-services.sh && \
    chmod +x /usr/local/bin/start-services.sh

# 使用新的启动脚本来启动所有服务
CMD ["/usr/local/bin/start-services.sh"]
