#!/bin/bash

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must run with sudo, try again..."
  exit 1
fi

# Get the name of the main user account
MAIN_USER=$(logname)

# Get the username of the user who invoked sudo
username="$SUDO_USER"

# Get the home directory of the user
homedir=$(getent passwd "$username" | cut -d: -f6)

# This function runs the 'sudo apt-get install -y nala' command and install nala on the OS
run_nala_install() {
	
    echo "Running 'sudo apt-get install -y nala' command..."
    # Update the package index and upgrade the installed packages
    sudo apt update && sudo apt upgrade -y
    # Install nala with no interaction
    sudo apt-get install -y nala
}

# This function runs the 'sudo nala fetch' command and sends the response '1 2 3 y' when prompted for input
run_nala_fetch() {
    echo "Running 'sudo nala fetch' command..."
    # Use expect to automate the input for nala fetch
    expect -c "
    spawn sudo nala fetch
    expect \"Enter your choice:\"
    send \"1 2 3 4\r\"
    expect \"Are you sure?\"
    send \"y\r\"
    expect eof
    "
}

# This function runs the 'nala' command and installs several needed packages:

run_nala_installPackages() {

	# Add the non-free repository to the sources.list file if not already present
	grep -qxF "deb http://deb.debian.org/debian buster main non-free" /etc/apt/sources.list || echo "deb http://deb.debian.org/debian buster main non-free" | sudo tee -a /etc/apt/sources.list

	# Update the package index
	sudo apt-get update
	
	#Installing Packages with no interaction
    sudo nala install -y xz-utils git curl nano debconf ufw fail2ban net-tools iptables vainfo i965-va-driver-shaders
}

configure_jellyfin_account() {

#Create Jellyfin Service Account if not already exists
id -u jellyfin &>/dev/null || sudo useradd -r -s /bin/false jellyfin

#Define a Home Directory if not already exists
[ -d /home/jellyfin/ ] || sudo mkdir -p /home/jellyfin/
sudo chown -R jellyfin:jellyfin /home/jellyfin/

# Add the Jellyfin user to the video group if not already in it
groups jellyfin | grep -q video || sudo usermod -aG video jellyfin

#Create encoding file if not already exists
[ -d /etc/jellyfin/ ] || sudo mkdir -p /etc/jellyfin/
[ -f /etc/jellyfin/encoding.xml ] || sudo touch /etc/jellyfin/encoding.xml

# Enable VAAPI hardware acceleration for Jellyfin (requires Intel GPU)
grep -qxF "hardwareAcceleration.enableVAAPI = true" /etc/jellyfin/encoding.xml || echo "hardwareAcceleration.enableVAAPI = true" | sudo tee -a /etc/jellyfin/encoding.xml

# Define the device path for VAAPI (requires Intel GPU)
grep -qxF "hardwareAcceleration.vaapiDevicePath = \"/dev/dri/renderD128\"" /etc/jellyfin/encoding.xml || echo "hardwareAcceleration.vaapiDevicePath = \"/dev/dri/renderD128\"" | sudo tee -a /etc/jellyfin/encoding.xml

# Define the driver type for VAAPI (requires Intel GPU)
grep -qxF "hardwareAcceleration.vaapiDriverTypeOverride = \"i965\"" /etc/jellyfin/encoding.xml || echo "hardwareAcceleration.vaapiDriverTypeOverride = \"i965\"" | sudo tee -a /etc/jellyfin/encoding.xml

# Drop advanced subtitles for VAAPI (requires Intel GPU)
grep -qxF "hardwareAcceleration.vaapiDropAdvancedSubtitlesOverride = true" /etc/jellyfin/encoding.xml || echo "hardwareAcceleration.vaapiDropAdvancedSubtitlesOverride = true" | sudo tee -a /etc/jellyfin/encoding.xml

# Define the output format for VAAPI (requires Intel GPU)
grep -qxF "hardwareAcceleration.vaapiHwaccelOutputFormatOverride = \"vaapi_vld\"" /etc/jellyfin/encoding.xml || echo "hardwareAcceleration.vaapiHwaccelOutputFormatOverride = \"vaapi_vld\"" | sudo tee -a /etc/jellyfin/encoding.xml

# Allow hwaccel transcoding for VAAPI (requires Intel GPU)
grep -qxF "hardwareAcceleration.vaapiAllowHwaccelTranscodingOverride = true" /etc/jellyfin/encoding.xml || echo "hardwareAcceleration.vaapiAllowHwaccelTranscodingOverride = true" | sudo tee -a /etc/jellyfin/encoding.xml

# Allow hwaccel decoder for VAAPI (requires Intel GPU)
grep -qxF "hardwareAcceleration.vaapiAllowHwaccelDecoderOverride = true" /etc/jellyfin/encoding.xml || echo "hardwareAcceleration.vaapiAllowHwaccelDecoderOverride = true" | sudo tee -a /etc/jellyfin/encoding.xml

# Allow hwaccel encoder for VAAPI (requires Intel GPU)
grep -qxF "hardwareAcceleration.vaapiAllowHwaccelEncoderOverride = true" /etc/jellyfin/encoding.xml || echo "hardwareAcceleration.vaapiAllowHwaccelEncoderOverride = true" | sudo tee -a /etc/jellyfin/encoding.xml


#Create Jellyfin files if not already exists
[ -d /var/lib/jellyfin ] || sudo mkdir -p /var/lib/jellyfin
[ -d /etc/jellyfin ] || sudo mkdir -p /etc/jellyfin
[ -d /usr/share/jellyfin ] || sudo mkdir -p /usr/share/jellyfin
[ -d /var/log/jellyfin ] || sudo mkdir -p /var/log/jellyfin

# Set ownership of Jellyfin files to jellyfin user
sudo chown -R jellyfin:jellyfin /var/lib/jellyfin
sudo chown -R jellyfin:jellyfin /etc/jellyfin
sudo chown -R jellyfin:jellyfin /usr/share/jellyfin
sudo chown -R jellyfin:jellyfin /var/log/jellyfin

}

# This function installs NixPackages:
run_nix_install() {

    echo "Running Nix Installation using  determinate.systems/nix installation command..."
    # Installing Nix Using the Determinate Systems Script
    sudo -u jellyfin curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

}

run_nixjellyfin() {
  
  # Define the commands to be run
  command1="sudo -u jellyfin /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  command2="sudo -u jellyfin /nix/var/nix/profiles/default/bin/nix profile install nixpkgs#jellyfin"

  # Run the commands with error checking
  eval "$command1" || { echo "Failed to run $command1"; exit 1; }
  eval "$command2" || { echo "Failed to run $command2"; exit 1; }
  
}

create_jellyfin_service() {

# Define the service code
service_code='[Unit]
Description=Jellyfin Media Server
After=network.target

[Service]
User=jellyfin
Group=jellyfin
WorkingDirectory=/home/jellyfin/
ExecStart=/home/jellyfin/.nix-profile/bin/jellyfin
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target'

  # Create the service file with error checking
  echo "$service_code" > /etc/systemd/system/jellyfin.service || { echo "Failed to create service file"; exit 1; }

  # Reload the systemd daemon to recognize the new service
  sudo systemctl daemon-reload

  # Enable the service to start automatically at boot
  sudo systemctl enable jellyfin.service

  # Start the service
  sudo systemctl start jellyfin.service
}

setup_security() {
    # Setup UFW rules
    sudo ufw limit 22/tcp  
    sudo ufw allow 80/tcp  
    sudo ufw allow 443/tcp
    sudo ufw allow 8096/tcp #Jellyfin port
    sudo ufw allow 8920/tcp #Jellyfin port
    sudo ufw allow 1900/udp #Jellyfin port
    sudo ufw allow 7359/udp #Jellyfin port
    sudo ufw default deny incoming  
    sudo ufw default allow outgoing
    sudo ufw enable

    # Harden /etc/sysctl.conf
    sudo sysctl kernel.modules_disabled=1
    sudo sysctl -a
    sudo sysctl -A
    sudo sysctl mib
    sudo sysctl net.ipv4.conf.all.rp_filter=1 #Enable source validation by reversed path (RFC1812)
    sudo sysctl net.ipv4.conf.all.accept_redirects=0 #Disable ICMP redirect acceptance (RFC1122)
    sudo sysctl net.ipv4.conf.all.send_redirects=0 #Disable ICMP redirect sending (RFC1122)
    sudo sysctl net.ipv4.conf.all.accept_source_route=0 #Disable IP source routing (RFC1812)
    sudo sysctl net.ipv4.conf.all.log_martians=1 #Log packets with impossible addresses (RFC1812)
    sudo sysctl net.ipv4.tcp_syncookies=1 #Enable TCP SYN cookies (RFC4987)
    sudo sysctl net.ipv4.icmp_echo_ignore_broadcasts=1 #Ignore ICMP broadcasts (RFC1122)
    sudo sysctl net.ipv4.icmp_ignore_bogus_error_responses=1 #Ignore bogus ICMP errors (RFC1122)

    # PREVENT IP SPOOFS
    sudo bash -c 'echo -e "order bind,hosts\nmulti on" > /etc/host.conf'

    # Enable fail2ban
    sudo cp jail.local /etc/fail2ban/
    sudo touch /var/log/auth.log
    echo "logpath = /var/log/auth.log" | sudo tee -a /etc/fail2ban/jail.d/defaults-debian.conf

    sudo systemctl enable fail2ban
    sudo systemctl daemon-reload
    sudo systemctl start fail2ban

    echo "listening ports"
    sudo netstat -tunlp 
}

setup_lan() {

# Get the ethernet network interface name using ip command
# Assume it is the first non-loopback interface
iface=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')

# Set the static IP address with error checking
# Check if the file already has an entry for the interface
if grep -q "^auto $iface" /etc/network/interfaces; then
  echo "The file already has an entry for auto $iface"
else
  echo "auto $iface" >> /etc/network/interfaces || { echo "Failed to set auto $iface"; exit 1; }
fi

# Check if the file already has an entry for the static configuration
if grep -q "^iface $iface inet static" /etc/network/interfaces; then
  echo "The file already has an entry for iface $iface inet static"
else
  # Remove any existing DHCP configuration for the interface
  sed -i "/^iface $iface inet dhcp/d" /etc/network/interfaces || { echo "Failed to remove DHCP configuration"; exit 1; }
  # Add the static configuration for the interface
  echo "iface $iface inet static" >> /etc/network/interfaces || { echo "Failed to set iface $iface inet static"; exit 1; }
fi

# Check if the file already has an entry for the address
if grep -q "^address 10.10.1.25" /etc/network/interfaces; then
  echo "The file already has an entry for address 10.10.1.25"
else
  # Replace any existing address entry with the new one
  sed -i "/^address/c\address 10.10.1.25" /etc/network/interfaces || { echo "Failed to set address"; exit 1; }
fi

# Check if the file already has an entry for the netmask
if grep -q "^netmask 255.255.255.0" /etc/network/interfaces; then
  echo "The file already has an entry for netmask 255.255.255.0"
else
  # Replace any existing netmask entry with the new one
  sed -i "/^netmask/c\netmask 255.255.255.0" /etc/network/interfaces || { echo "Failed to set netmask"; exit 1; }
fi

# Check if the file already has an entry for the gateway
if grep -q "^gateway 10.10.1.1" /etc/network/interfaces; then
  echo "The file already has an entry for gateway 10.10.1.1"
else
  # Replace any existing gateway entry with the new one
  sed -i "/^gateway/c\gateway 10.10.1.1" /etc/network/interfaces || { echo "Failed to set gateway"; exit 1; }
fi

# Set the primary DNS suffix with error checking
# Check if the file already has an entry for the search domain
if grep -q "^search pfsense.home" /etc/resolv.conf; then
  echo "The file already has an entry for search pfsense.home"
else
  # Replace any existing search domain entry with the new one
  sed -i "/^search/c\search pfsense.home" /etc/resolv.conf || { echo "Failed to set primary DNS suffix"; exit 1; }
fi

# Set the DNS address with error checking
# Check if the file already has an entry for the nameserver
if grep -q "^nameserver 10.10.1.1" /etc/resolv.conf; then
  echo "The file already has an entry for nameserver 10.10.1.1"
else
  # Replace any existing nameserver entry with the new one
  sed -i "/^nameserver/c\nameserver 10.10.1.1" /etc/resolv.conf || { echo "Failed to set DNS address"; exit 1; }
fi

# Set additional settings for a 1Gbps Ethernet LAN using ethtool command
ethtool -s $iface speed 1000 duplex full autoneg off

}


run_linux_tweaks() {

#Faster Grub
sudo sed -i 's/GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=1/' /etc/default/grub && sudo update-grub

# Enable zswap
sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT/ s/"$/ zswap.enabled=1"/' /etc/default/grub
sudo update-grub

#Disable Hyper-Thread Mitigations for more performance on Desktop and use zswap
echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf
echo "kernel.nosmt = 1" | sudo tee -a /etc/sysctl.conf

}

# Main script
echo "Starting script..."

#Install Nala and Fetch best mirrors
run_nala_install
#run_nala_fetch

#Install Additional Packages
run_nala_installPackages

#Create and configure Jellyfin service account
configure_jellyfin_account

#Sets the Nix Enviroment so it can be used and installs jellyfin
run_nix_install
run_nixjellyfin

#Create and start Jellyfin service
create_jellyfin_service

#Hardens Server
setup_security

#ConfigureLan & Static IP
setup_lan

#Set additional configuration optios
run_linux_tweaks

#The End
echo "Script finished."
echo "Check /etc/network/interfaces and /etc/resolv.conf for any network mismatches."
