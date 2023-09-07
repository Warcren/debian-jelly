#!/bin/bash

# Set the static IP address with error checking
# Check if the file already has an entry for the interface
if awk "/^auto $iface/" /etc/network/interfaces; then
  echo "The file already has an entry for auto $iface"
else
  echo "auto $iface" >> /etc/network/interfaces || { echo "Failed to set auto $iface"; exit 1; }
fi

# Check if the file already has an entry for the static configuration
if awk "/^iface $iface inet static/" /etc/network/interfaces; then
  echo "The file already has an entry for iface $iface inet static"
else
  # Remove any existing DHCP configuration for the interface
  awk "!/^iface $iface inet dhcp/" /etc/network/interfaces > temp && mv temp /etc/network/interfaces || { echo "Failed to remove DHCP configuration"; exit 1; }
  # Add the static configuration for the interface
  echo "iface $iface inet static" >> /etc/network/interfaces || { echo "Failed to set iface $iface inet static"; exit 1; }
fi

# Check if the file already has an entry for the address
if awk "/^address 10.10.1.25/" /etc/network/interfaces; then
  echo "The file already has an entry for address 10.10.1.25"
else
  # Replace any existing address entry with the new one
  awk "{if (/^address/) print \"address 10.10.1.25\"; else print}" /etc/network/interfaces > temp && mv temp /etc/network/interfaces || { echo "Failed to set address"; exit 1; }
fi

# Check if the file already has an entry for the netmask
if awk "/^netmask 255.255.255.0/" /etc/network/interfaces; then
  echo "The file already has an entry for netmask 255.255.255.0"
else
  # Replace any existing netmask entry with the new one
  awk "{if (/^netmask/) print \"netmask 255.255.255.0\"; else print}" /etc/network/interfaces > temp && mv temp /etc/network/interfaces || { echo "Failed to set netmask"; exit 1; }
fi

# Check if the file already has an entry for the gateway
if awk "/^gateway 10.10.1.1/" /etc/network/interfaces; then
  echo "The file already has an entry for gateway 10.10.1.1"
else
  # Replace any existing gateway entry with the new one
  awk "{if (/^gateway/) print \"gateway 10.10.1.1\"; else print}" /etc/network/interfaces > temp && mv temp /etc/network/interfaces || { echo "Failed to set gateway"; exit 1; }
fi

# Set the primary DNS suffix with error checking
# Check if the file already has an entry for the search domain
if awk "/^search pfsense.home/" /etc/resolv.conf; then
  echo "The file already has an entry for search pfsense.home"
else
  # Replace any existing search domain entry with the new one
  awk "{if (/^search/) print \"search pfsense.home\"; else print}" /etc/resolv.conf > temp && mv temp /etc/resolv.conf || { echo "Failed to set primary DNS suffix"; exit 1; }
fi

# Set the DNS address with error checking
# Check if the file already has an entry for the nameserver
if awk "/^nameserver 10.10.1.1/" /etc/resolv.conf; then
  echo "The file already has an entry for nameserver 10.10.1.1"
else
  # Replace any existing nameserver entry with the new one
  awk "{if (/^nameserver/) print \"nameserver 10.10.1.1\"; else print}" /etc/resolv.conf > temp && mv temp /etc/resolv.conf || { echo "Failed to set DNS address"; exit 1; }
fi```
