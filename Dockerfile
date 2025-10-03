FROM debian:bookworm-slim
LABEL maintainer="muze <zhmuze@gmail.com>"
LABEL description="Cupsd on debian-slim, only for Epson L210/L360 (Official Driver)"
# 设置环境变量以避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# --- 核心修改：安装 CUPS 和官方 Epson 驱动 ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    # CUPS 核心服务和基础组件
    cups \
    cups-bsd \
    cups-client \
    cups-filters \
    # 基础字体支持
    gsfonts \
    # PPD 文件数据库
    openprinting-ppds \
    # 创建用户和配置 sudo 所需的工具
    sudo \
    whois \
    # --- 新增部分：下载和安装驱动所需的工具 ---
    wget \
    dpkg \
  # --- 下载并安装官方 Epson 驱动 ---
  && wget -O /tmp/epson-driver.deb https://eposs.epson.com.cn/EPSON/assets/resource/Download/Service/driver/Inkjet/L130/sign_epson-inkjet-printer-201401w_1_0_0_amd64.deb \
  && dpkg -i /tmp/epson-driver.deb || true \
  && apt-get -f install -y \
  # --- 清理 ---
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# 创建一个名为 'print' 的用户，并加入 lpadmin 组以管理打印机
RUN useradd -m -s /bin/bash -G lpadmin print \
    && echo "print:print" | chpasswd

# 配置 CUPS 允许远程访问和管理
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin\/conf>/a \  Allow All' /etc/cups/cupsd.conf \
    && echo "ServerAlias *" >> /etc/cups/cupsd.conf

# 暴露 CUPS 的标准端口
EXPOSE 631

# 启动脚本，确保 CUPS 在前台运行
CMD ["/usr/sbin/cupsd", "-f"]
