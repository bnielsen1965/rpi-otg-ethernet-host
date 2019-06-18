#!/bin/bash

OTG_MODE="g_ether"
OTG_INTERFACE="usb0"
OTG_NETMASK="255.255.255.0"
OTG_ADDRESS_OCTET="1"


PACKAGE=`basename $0`


# display usage help
function Usage()
{
cat <<-ENDOFMESSAGE
$PACKAGE - Configure Raspberry Pi Zero USB OTG as an ethernet host with DHCP service.

Used to modify boot up parameters to enable the Pi Zero USB interface as an ethernet
device and configure the ethernet device to come up as a host interface that will
provide DHCP addresses to connected clients.

$PACKAGE subnet
  arguments:
  subnet - the subnet address to use for the dhcp block, the interface will use the .1 address.
ENDOFMESSAGE
  exit
}

# die with message
function Die()
{
  echo "$*"
  exit 1
}


# ensure isc-dhcp-server is installed
function InstallDHCPServer()
{
  local pkgok=$(dpkg-query -W --showformat='${Status}\n' isc-dhcp-server|grep "install ok installed")
  if [ "" == "$pkgok" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get --yes install isc-dhcp-server
  fi
}

# set otg mode
function SetOTGMode()
{
  local otgmode="$1"
  ./scripts/otg-set-mode.sh "$otgmode"
}

# create DHCP server settings for otg interface
function SetDHCPServer()
{
  local subnet="$1"
  local interface="$2"
  ./scripts/isc-dhcp-subnet.sh create "${subnet%.*}.0" "$interface"
}

# create otg interface settings
function CreateOTGInterface()
{
  local interface="$1"
  local subnet="$2"
  local address="${subnet%.*}.$OTG_ADDRESS_OCTET"
  local netmask="$3"
  cat >"/etc/network/interfaces.d/$interface" <<EOF

  allow-hotplug $interface
  iface $interface inet static
    address $address
    netmask $netmask

EOF
}

OTG_SUBNET="$1"

if [ -z "$OTG_SUBNET" ]; then
  echo "Subnet required."
  Usage
fi

# make sure script runs from script's path
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_PATH"

InstallDHCPServer || Die "DHCP server install failed."
SetOTGMode "$OTG_MODE" || Die "Set OTG mode failed."
SetDHCPServer "$OTG_SUBNET" "$OTG_INTERFACE" || Die "Configure DHCP server failed."
CreateOTGInterface "$OTG_INTERFACE" "$OTG_SUBNET" "$OTG_NETMASK" || "Create OTG interface failed."

