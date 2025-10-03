# 使用最新的 Debian 稳定版 slim 镜像作为基础
FROM debian:bookworm-slim

LABEL maintainer="muze"
LABEL description="CUPS + Epson Drivers + SANE-airscan for Printing and Scanning"

# 设置环境变量以避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# --- 合并安装命令并修正包列表 ---
# 将所有 apt-get install 合并为一步，这是 Docker 的最佳实践，可以减少镜像层数。
# 移除了重复的 `sane-airscan` 和 `avahi-daemon` 安装。
# `libsane-common` 通常作为 `sane-utils` 的依赖会被自动安装，可以省略。
# `sudo` 和 `whois` 对于容器服务来说非必需，可以移除以保持镜像精简。
RUN apt-get update && apt-get install -y --no-install-recommends \
    # --- 打印相关 ---
    cups \
    cups-bsd \
    cups-client \
    cups-filters \
    printer-driver-escpr \
    gsfonts \
    # --- 扫描相关 ---
    sane-airscan \
    sane-utils \
    avahi-daemon \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# --- 配置 SANE 允许网络访问 ---
# 你的配置方式是正确的，这是推荐的做法。
RUN mkdir -p /etc/sane.d/dll.d
RUN echo "airscan" > /etc/sane.d/dll.d/airscan.conf

# --- 核心修改：为 Epson L360 添加 sane驱动配置 ---
# 这行是多余的，因为 `epson2` 驱动通常默认就在会被加载。
# 即使需要手动加载，正确的做法是在 `/etc/sane.d/dll.conf` 文件中取消 `epson2` 这一行的注释，
# 而不是创建一个新的文件。对于 `sane-airscan` 这种外部后端，使用 dll.d 目录是正确的。
# 我们将这行删除，因为它可能会引起冲突或不必要的混淆。
# RUN echo "epson2" > /etc/sane.d/dll.d/epson2.conf

# --- 修正：配置 saned 服务 ---
# saned.conf 是 saned 服务的配置文件，用于指定允许连接的客户端 IP。
# 你之前的配置是正确的，这里保留。
RUN echo "localhost" > /etc/sane.d/saned.conf && \
    echo "192.168.0.0/16" >> /etc/sane.d/saned.conf

# --- 创建用户并加入 lpadmin 组 ---
# `scanner` 组在很多现代系统中已经不常用，SANE 的访问控制更多通过 saned.conf 和 PAM 实现。
# 加入 `lpadmin` 组是必需的，用于管理打印机。
RUN useradd -m -s /bin/bash -G lpadmin print \
    && echo "print:print" | chpasswd

# --- 配置 CUPS 允许远程访问和管理 ---
# 你的 CUPS 配置非常完善，这里保留。
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin>/a \  Allow All' /etc/cups/cupsd.conf \
    && sed -i '/<Location \/admin\/conf>/a \  Allow All' /etc/cups/cupsd.conf \
    && echo "ServerAlias *" >> /etc/cups/cupsd.conf

# --- 暴露端口 ---
# 631: CUPS 管理端口
# 6566: SANE 网络扫描服务端口
EXPOSE 631 6566

# --- 创建启动脚本，启动所有必需服务 ---
# 这是最关键的修改！一个容器应该有一个主进程。我们用一个脚本来启动所有后台服务，
# 最后用 `exec` 来启动 cupsd 并让它在前台运行。
# `exec` 非常重要，它会替换脚本进程，使得 `docker stop` 能正确地向 cupsd 发送信号。
RUN echo '#!/bin/bash' > /usr/local/bin/start-all.sh && \
    echo 'set -e' >> /usr/local/bin/start-all.sh && \
    echo 'echo "Starting Avahi daemon..."' >> /usr/local/bin/start-all.sh && \
    # 使用后台模式启动 avahi-daemon
    echo 'avahi-daemon -D' >> /usr/local/bin/start-all.sh && \
    echo 'echo "Starting saned service..."' >> /usr/local/bin/start-all.sh && \
    # saned 可以作为守护进程启动
    echo 'saned -d1' >> /usr/local/bin/start-all.sh && \
    echo 'echo "Starting CUPS service..."' >> /usr/local/bin/start-all.sh && \
    # 使用 exec 和 -f (foreground) 参数，让 cupsd 成为容器的主进程
    echo 'exec /usr/sbin/cupsd -f' >> /usr/local/bin/start-all.sh && \
    chmod +x /usr/local/bin/start-all.sh

# --- 使用新的启动脚本来启动所有服务 ---
CMD ["/usr/local/bin/start-all.sh"]
