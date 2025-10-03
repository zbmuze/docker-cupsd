FROM debian:bookworm-slim
LABEL maintainer="Joe Block <jpb@unixorn.net>"
LABEL description="Cupsd on debian-slim, support Epson L210 (Gutenprint) + L360 (Official v1.0.0-1)"

# 安装核心依赖、Gutenprint 驱动 (L210) 和工具
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    # CUPS 核心服务组件
    cups \
    cups-bsd \
    cups-client \
    cups-filters \
    # 打印基础依赖
    foomatic-db \
    gsfonts \
    openprinting-ppds \
    # L210 Gutenprint 驱动
    printer-driver-gutenprint \
    # 系统工具依赖
    sudo \
    whois \
    # 新增：用于下载 .deb 包
    wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# --- 手动安装 L360 指定驱动开始 ---
# 1. 从 Debian 官方归档下载明确支持 L360 的 1.0.0-1 版本驱动包
#    注意：这里使用的是旧版本的链接，请确认其有效性
RUN wget -O /tmp/epson-inkjet-printer_1.0.0-1.deb \
    "http://ftp.de.debian.org/debian/pool/non-free/e/epson-inkjet-printer-escpr/epson-inkjet-printer-escpr_1.0.0-1_amd64.deb"

# 2. 使用 dpkg -i 手动安装下载的 .deb 包
#    注意：这个包的名称可能与我们之前用的不同
RUN dpkg -i /tmp/epson-inkjet-printer_1.0.0-1.deb \
    # 3. 修复可能因手动安装导致的依赖问题
    && apt-get -f install -y \
    # 4. 清理下载的 .deb 文件，减小镜像体积
    && rm -f /tmp/epson-inkjet-printer_1.0.0-1.deb

# --- 手动安装 L360 指定驱动结束 ---

# 创建打印用户并配置 sudo 免密
RUN useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/print \
  --shell=/bin/bash \
  --password=$(mkpasswd print) \
  print \
&& sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

# 修复 CUPS 远程访问 Bad Request 错误
RUN cp /etc/cups/cupsd.conf /etc/cups/fixit && \
  sed 's/Port 631/Port 631\nServerAlias \*/' < /etc/cups/fixit > /etc/cups/cupsd.conf && \
  rm -f /etc/cups/fixit

# 配置 CUPS 允许远程管理和共享
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid)

# 优化 CUPS 加密配置
RUN sed -e '0,/^</s//DefaultEncryption IfRequested\n&/' -i /etc/cups/cupsd.conf

# 启动 CUPS 服务
CMD ["/usr/sbin/cupsd", "-f"]
