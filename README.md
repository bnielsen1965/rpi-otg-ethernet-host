# rpi-otg-ethernet-host

Configure the Raspberry Pi Zero OTG USB port as an ethernet host with a DHCP server.

This script will modify the boot parameters to make the USB port come up as an
ethernet device. It will also generate the interface file to set a static IP
address on the USB ethernet device and configure the isc-dhcp-server to provide
a block of DHCP address leases to the system attached to the USB port.


# usage

rpi-otg-ethernet-host - Configure Raspberry Pi Zero USB OTG as an ethernet host with DHCP service.

Used to modify boot up parameters to enable the Pi Zero USB interface as an ethernet
device and configure the ethernet device to come up as a host interface that will
provide DHCP addresses to connected clients.

rpi-otg-ethernet-host subnet
- subnet - the subnet address to use for the dhcp block, the interface will use the .1 address.
