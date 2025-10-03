# 仅安装 L210 必需组件：CUPS 核心 + Gutenprint 驱动 + 基础工具
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    # CUPS 核心服务（打印基础依赖，不可移除）
    cups \
    cups-bsd \
    cups-client \
    cups-filters \
    # L210 专用驱动（Gutenprint v5.3.3 依赖包）
    printer-driver-gutenprint \
    # 打印配置基础文件（PPD 描述库，Gutenprint 依赖）
    openprinting-ppds \
    # 字体支持（避免打印中文/特殊字符乱码）
    gsfonts \
    # 用户管理工具（创建 print 用户必需）
    sudo \
    whois \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# 创建打印用户并配置 sudo 免密（原逻辑保留，确保权限正常）
RUN useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/print \
  --shell=/bin/bash \
  --password=$(mkpasswd print) \
  print \
&& sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

# 修复 CUPS 远程访问 Bad Request 错误（确保局域网可访问管理界面）
RUN cp /etc/cups/cupsd.conf /etc/cups/fixit && \
  sed 's/Port 631/Port 631\nServerAlias \*/' < /etc/cups/fixit > /etc/cups/cupsd.conf && \
  rm -f /etc/cups/fixit

# 配置 CUPS 允许远程管理和打印机共享（L210 局域网使用必需）
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid)

# 优化 CUPS 加密配置（避免低版本客户端连接失败）
RUN sed -e '0,/^</s//DefaultEncryption IfRequested\n&/' -i /etc/cups/cupsd.conf

# 前台启动 CUPS 服务（确保容器不退出）
CMD ["/usr/sbin/cupsd", "-f"]
