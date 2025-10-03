FROM debian:bookworm-slim

LABEL maintainer="muze <zhmuze@gmail.com>"
LABEL description="Cupsd on debian-slim, only for Epson L210/L360 (Gutenprint v5.3.4)"

# 设置环境变量以避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# 安装 Epson L210 所需的软件包
RUN apt-get update && apt-get install -y --no-install-recommends \
    # CUPS 核心服务和基础组件
    cups \
    cups-bsd \
    cups-client \
    cups-filters \
    # Epson L210 专用的 Gutenprint 驱动（会包含对应版本，如 v5.3.4 相关组件）
    printer-driver-gutenprint \
    # 基础字体支持
    gsfonts \
    # PPD 文件数据库，Gutenprint 依赖它来识别 Epson L210 型号
    openprinting-ppds \
    # 创建用户和配置 sudo 所需的工具
    sudo \
    whois \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# 清理其他不必要的打印机驱动（改进版，先检查再卸载）
RUN if dpkg -l | grep -q "printer-driver-hp"; then \
        apt-get remove -y --purge printer-driver-hp*; \
    fi \
    && apt-get autoremove -y \
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
