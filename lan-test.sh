#!/bin/bash
# Get the name of the network interface
iface=$(ip -o -4 route show to default | awk '{print $5}')

# Define the static IP configuration
ip_config="auto $iface
iface $iface inet static
address 10.10.1.25
netmask 255.255.255.0
gateway 10.10.1.1"

# Define the DNS configuration
dns_config="search pfsense.home
nameserver 10.10.1.1"

# Overwrite the network interfaces file with the new configuration
echo "$ip_config" > /etc/network/interfaces || { echo "Failed to set IP configuration"; exit 1; }

# Overwrite the resolv.conf file with the new DNS configuration
echo "$dns_config" > /etc/resolv.conf || { echo "Failed to set DNS configuration"; exit 1; }
