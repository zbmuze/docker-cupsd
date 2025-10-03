# 1. 升级基础镜像到 Debian 12（Bookworm）稳定版
FROM debian:bookworm-slim

# 2. 设置环境变量：避免交互式安装（Debian 12 需显式指定）
ENV DEBIAN_FRONTEND=noninteractive

# 3. 安装核心组件：仅保留 CUPS + HP 驱动 + 必要工具（删除冗余驱动）
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 系统基础工具（仅保留必需）
    sudo \
    whois \
    usbutils \
    # CUPS 核心服务（缺一不可）
    cups \
    cups-client \
    cups-bsd \
    cups-filters \
    # HP 打印机专用驱动（核心，替换原冗余的 printer-driver-all）
    hplip \
    hpijs-ppds \
    hp-ppd \
    # 附加功能（按需保留：SMB 共享、PDF 虚拟打印机）
    smbclient \
    printer-driver-cups-pdf \
    # PPD 数据库（HP 驱动依赖，保留）
    foomatic-db-compressed-ppds \
    openprinting-ppds \
  # 清理缓存：减少镜像体积
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# 4. 创建 print 用户：优化权限（删除全局免密 sudo）
RUN useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/print \
  --shell=/bin/bash \
  --password=$(mkpasswd print) \
  print \
  # （可选）仅允许 print 用户免密管理 CUPS，而非所有 sudo 命令（更安全）
  && echo "print ALL=(ALL) NOPASSWD: /usr/sbin/cupsctl, /usr/sbin/lpadmin, /etc/init.d/cups" >> /etc/sudoers

# 5. 复制自定义 CUPS 配置（需确保本地有 cupsd.conf 文件）
# 若本地无自定义文件，可删除这行，使用默认配置（但需后续手动调整访问规则）
COPY --chown=root:lp cupsd.conf /etc/cups/cupsd.conf

# 6. 暴露 CUPS 默认端口（必须，否则外部无法访问）
EXPOSE 631

# 7. 启动 CUPS 服务（前台运行，保持容器活跃）
CMD ["/usr/sbin/cupsd", "-f"]
