FROM debian:bookworm-slim
LABEL maintainer="Joe Block <jpb@unixorn.net>"
LABEL description="Cupsd on top of debian-slim, optimized for Epson L360"

# 精简安装包，并确保安装 sudo 和 whois
# sudo: 提供 sudo 命令和 /etc/sudoers 文件
# whois: 提供 mkpasswd 命令
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    cups \
    cups-bsd \
    cups-client \
    cups-filters \
    foomatic-db \
    gsfonts \
    printer-driver-escpr \
    openprinting-ppds \
    sudo \
    whois \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# 添加用户并配置 sudo (现在依赖的包都已安装，此步将成功)
RUN useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/print \
  --shell=/bin/bash \
  --password=$(mkpasswd print) \
  print \
&& sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

# 修复 Bad Request 错误
RUN cp /etc/cups/cupsd.conf /etc/cups/fixit && \
  sed 's/Port 631/Port 631\nServerAlias \*/' < /etc/cups/fixit > /etc/cups/cupsd.conf && \
  rm -f /etc/cups/fixit

# 配置服务可远程访问
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid)

# 仅在请求时启用加密
RUN sed -e '0,/^</s//DefaultEncryption IfRequested\n&/' -i /etc/cups/cupsd.conf

# 启动命令
CMD ["/usr/sbin/cupsd", "-f"]
