FROM debian:bookworm-slim
LABEL maintainer="muze <zhmuze@gmail.com>"
LABEL description="Cupsd on debian-slim, only for Epson L210/L360 (Gutenprint)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    cups \
    cups-filters \
    printer-driver-escpr \
    printer-driver-gutenprint \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# 复制你配置好的 cupsd.conf 进镜像
COPY cupsd.conf /etc/cups/cupsd.conf

EXPOSE 631

CMD ["/usr/sbin/cupsd", "-f"]
