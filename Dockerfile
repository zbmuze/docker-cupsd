FROM debian:bookworm-slim
LABEL maintainer="muze <zhmuze@gmail.com>"
LABEL description="Minimal CUPS server for Epson L210/L360 (Gutenprint)"

# 设置环境变量以避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# --- 核心修改：仅安装最核心的软件包 ---
# 移除了客户端工具、sudo、whois 和通用字体
RUN apt-get update && apt-get install -y --no-install-recommends \
    # CUPS 核心服务
    cups \
    cups-filters \
    # L210 专用驱动
    printer-driver-gutenprint \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/*

# 创建 'print' 用户并加入 lpadmin 组，无需 sudo
RUN useradd -m -s /bin/bash -G lpadmin print \
    && echo "print:print" | chpasswd

# 配置 CUPS 允许远程访问和管理
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin\/conf>/a \  Allow All' /etc/cups/cupsd.conf

# 暴露 CUPS 的标准端口
EXPOSE 631

# 使用 exec 启动 CUPS 在前台运行，以便正确处理信号
CMD ["sh", "-c", "exec /usr/sbin/cupsd -f"]
