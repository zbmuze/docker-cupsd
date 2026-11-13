FROM debian:bookworm-slim
LABEL maintainer="muze <zhmuze@gmail.com>"
LABEL description="Cupsd on debian-slim, only for Epson L210/L360 (Gutenprint)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    avahi-daemon \
    avahi-utils \
    dbus \
    cups \
    cups-filters \
    passwd \
    printer-driver-escpr \
    printer-driver-gutenprint \
  && mkdir -p /var/run/dbus /run/dbus \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# 复制你配置好的 cupsd.conf 进镜像
COPY cupsd.conf /etc/cups/cupsd.conf
COPY avahi-daemon.conf /etc/avahi/avahi-daemon.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 631 5353/udp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/sbin/cupsd", "-f"]
