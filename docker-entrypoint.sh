#!/bin/sh
set -e

mkdir -p /var/run/dbus /run/dbus

if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
  dbus-daemon --system --fork >/dev/null 2>&1 || true
fi

if [ -x /usr/sbin/avahi-daemon ]; then
  if ! pgrep -x avahi-daemon >/dev/null 2>&1; then
    avahi-daemon --daemonize --no-chroot >/dev/null 2>&1 || true
  fi
fi

# If the external host name is provided, tell CUPS to use it as the canonical server name.
if [ -n "$CUPS_SERVER_NAME" ]; then
  if grep -q '^ServerName ' /etc/cups/cupsd.conf; then
    sed -i "s|^ServerName .*|ServerName $CUPS_SERVER_NAME|" /etc/cups/cupsd.conf
  else
    sed -i "s|^Port 631|Port 631\nServerName $CUPS_SERVER_NAME|" /etc/cups/cupsd.conf
  fi
fi

exec "$@"
