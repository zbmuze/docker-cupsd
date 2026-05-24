#!/bin/sh
set -e

# If the external host name is provided, tell CUPS to use it as the canonical server name.
if [ -n "$CUPS_SERVER_NAME" ]; then
  if grep -q '^ServerName ' /etc/cups/cupsd.conf; then
    sed -i "s|^ServerName .*|ServerName $CUPS_SERVER_NAME|" /etc/cups/cupsd.conf
  else
    sed -i "s|^Port 631|Port 631\nServerName $CUPS_SERVER_NAME|" /etc/cups/cupsd.conf
  fi
fi

exec /usr/sbin/cupsd -f
