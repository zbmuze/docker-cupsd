FROM debian:bookworm-slim
LABEL maintainer="muze <zhmuze@gmail.com>"
LABEL description="Cupsd for Epson L210/L360 (Gutenprint) | HTTP admin support"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    cups \
    cups-filters \
    printer-driver-gutenprint \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

RUN useradd -m -s /bin/bash -G lpadmin print \
    && echo "print:print" | chpasswd

# 直接覆盖完整配置文件
COPY cupsd.conf /etc/cups/cupsd.conf

EXPOSE 631
CMD ["/usr/sbin/cupsd", "-f"]
