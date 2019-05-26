#!/bin/bash

DHCPD_RANGE_START=100
DHCPD_RANGE_END=240

DHCPD_CONF_PATH="/etc/dhcp"
DHCPD_CONF_FILE="dhcpd.conf"

DHCPD_DEFAULT_PATH="/etc/default"
DHCPD_DEFAULT_FILE="isc-dhcp-server"

SUBNET_HEADER="#### START [subnet] DO NOT EDIT ####"
SUBNET_FOOTER="#### END [subnet] DO NOT EDIT ####"

PACKAGE=`basename $0`


# display usage help
function Usage()
{
cat <<-ENDOFMESSAGE
$PACKAGE - Create or remove a subnet configuration for isc-dhcp-server.

Used to modify ${DHCPD_CONF_PATH}/${DHCPD_CONF_FILE} with a subnet address block
and the interface settings in ${DHCPD_DEFAULT_PATH}/${DHCPD_DEFAULT_FILE}.

$PACKAGE command subnet [interface]
  arguments:
  command - the command to execute, create | remove
  subnet - the subnet address to use for the dhcp block
  interface - the interface that will be used for dhcp service
ENDOFMESSAGE
  exit
}

# die with message
function Die()
{
  echo "$*"
  Usage
  exit 1
}

# TrimString "...string..."
function TrimString()
{
  local trimmed="$1"
  # remove leading whitespace characters
  trimmed="${trimmed#"${trimmed%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
  echo "$trimmed"
}

# get string value of DHCP interfaces setting
function GetDHCPInterfacesString()
{
  echo "$(sed -n -e 's/\s*INTERFACESv4="\(.*\)"/\1/p' ${DHCPD_DEFAULT_PATH}/${DHCPD_DEFAULT_FILE})"
}

# AdjustDHCPInterfaces remove|insert "eth0"
function AdjustDHCPInterfaces()
{
  local action="$1"
  local interface="$2"
  local newinterfaces=""
  local interfacestring="$(GetDHCPInterfacesString)"
  local interfaces=$(echo $interfacestring | tr "," "\n") # string to array
  # filtered out the adjusted interface
  for iface in $interfaces; do
    iface="$(TrimString "$iface")"
    if [ "$iface" != "$interface" ]; then
      newinterfaces="$newinterfaces,$iface"
    fi
  done
  newinterfaces="${newinterfaces#,}" # remove leading ,
  if [ "$action" = "insert" ]; then
    newinterfaces="$newinterfaces,$interface"
  fi
  newinterfaces="${newinterfaces#,}" # remove leading ,
  sed -i.backup "s/\(\s*INTERFACESv4=\"\).*\(\".*$\)/\1$newinterfaces\2/" "${DHCPD_DEFAULT_PATH}/${DHCPD_DEFAULT_FILE}"
}

# GetDHCPHeader "subnet"
function GetDHCPHeader()
{
  echo "${SUBNET_HEADER/\[subnet\]/$1}"
}

# GetDHCPFooter "subnet"
function GetDHCPFooter()
{
  echo "${SUBNET_FOOTER/\[subnet\]/$1}"
}

# RemoveDHCPSubnet "subnet"
function RemoveDHCPSubnet()
{
  local subnet="$1"
  local header="$(GetDHCPHeader "$subnet")"
  local footer="$(GetDHCPFooter "$subnet")"
  sed -i.backup "/^$header$/,/^$footer$/{d}" "$DHCPD_CONF_PATH/$DHCPD_CONF_FILE"
}

#InsertDHCPSubnet "subnet"
function InsertDHCPSubnet()
{
  local subnet="$1"
  RemoveDHCPSubnet "$subnet"
  local header="$(GetDHCPHeader "$subnet")"
  local footer="$(GetDHCPFooter "$subnet")"
  local block=$(cat <<EOF
$header
subnet $subnet netmask 255.255.255.0 {
  range ${subnet/\.0/\.$DHCPD_RANGE_START} ${subnet/\.0/\.$DHCPD_RANGE_END};
  option subnet-mask 255.255.255.0;
}
$footer
EOF
  )
  echo "$block" >> "$DHCPD_CONF_PATH/$DHCPD_CONF_FILE"
}


COMMAND="$1"
COMMAND_SUBNET="$2"
COMMAND_INTERFACE="$3"

if [ -z "$COMMAND" ]; then
  Die "Missing command."
fi

if [ -z "$COMMAND_SUBNET" ]; then
  Die "Missing subnet."
fi

# make sure subnet supports netmask 255.255.255.0
COMMAND_SUBNET="${COMMAND_SUBNET%.*}.0"

case ${COMMAND} in
  "remove")
  if [ ! -z "$COMMAND_INTERFACE" ]; then
    AdjustDHCPInterfaces "remove" "$COMMAND_INTERFACE"
  fi
  RemoveDHCPSubnet "$COMMAND_SUBNET"
  ;;
  "create")
  if [ ! -z "$COMMAND_INTERFACE" ]; then
    AdjustDHCPInterfaces "insert" "$COMMAND_INTERFACE"
  fi
  InsertDHCPSubnet "$COMMAND_SUBNET"
  ;;
  *)
  Die "Unknown command $COMMAND"
  ;;
esac
