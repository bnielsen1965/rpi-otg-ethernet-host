#!/bin/bash

DEFAULT_INTERFACE="usb0"
OTG_INTERFACE="$1"
OTG_INTERFACE="${OTG_INTERFACE:="$DEFAULT_INTERFACE"}"

if [ ! -f "/etc/network/interfaces.d/$OTG_INTERFACE" ]; then
  exit 1
fi

SUBNET=$(sed -n -e 's/^.*address[^0-9]\+\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.\).*/\1/p' /etc/network/interfaces.d/usb0)
SUBNET="${SUBNET}0"

echo "$SUBNET"
exit 0
