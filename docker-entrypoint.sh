#!/bin/sh
set -e

mkdir -p /var/run/dbus /run/dbus

if [ -n "${CUPS_ADMIN_PASSWORD_FILE:-}" ] || [ "${CUPS_ADMIN_PASSWORD+x}" = x ]; then
  if [ -n "${CUPS_ADMIN_PASSWORD_FILE:-}" ]; then
    if [ ! -r "$CUPS_ADMIN_PASSWORD_FILE" ]; then
      echo "CUPS_ADMIN_PASSWORD_FILE is not readable: $CUPS_ADMIN_PASSWORD_FILE" >&2
      exit 1
    fi
    admin_password=$(cat "$CUPS_ADMIN_PASSWORD_FILE")
  else
    admin_password=$CUPS_ADMIN_PASSWORD
  fi

  if [ -z "$admin_password" ]; then
    echo "CUPS admin password must not be empty" >&2
    exit 1
  fi

  if id -u print >/dev/null 2>&1; then
    usermod -aG lpadmin print
  else
    useradd -m -s /bin/sh -G lpadmin print
  fi
  printf 'print:%s\n' "$admin_password" | chpasswd
  unset admin_password CUPS_ADMIN_PASSWORD
fi

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
