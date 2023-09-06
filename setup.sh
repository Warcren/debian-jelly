#!/bin/bash

## check for sudo/root
if ! [ $(id -u) = 0 ]; then
  echo "This script must run with sudo, try again..."
  exit 1
fi

# Get the username of the user who invoked sudo
if [ "$SUDO_USER" ]; then
  username="$SUDO_USER"
else
  username="$(whoami)"
fi

# Get the home directory of the user
homedir=$(getent passwd "$username" | cut -d: -f6)

# This function runs the 'sudo apt-get install -y nala' command and install nala on the OS
run_nala_install() {
	
    echo "Running 'sudo apt-get install -y nala' command..."
    sudo apt update && sudo apt upgrade
    sudo apt-get install -y nala
}

# This function runs the 'sudo nala fetch' command and sends the response '1 2 3 y' when prompted for input
run_nala_fetch() {
    echo "Running 'sudo nala fetch' command..."
    { echo "1 2 3"; echo "y"; } | sudo nala fetch
}


# This function runs the 'nala' command and installs several needed packages:
run_nala_installPackages() {
    echo "Running 'sudo nala install -y xz-utils git curl nano debconf' command..."
    sudo nala install -y xz-utils git curl nano debconf acl
}

# This function installs NixPackages:
run_nix_install() {
    echo "Running Nix Installation using  determinate.systems/nix installation command..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

}

run_nixjellyfin() {
  # Define the commands to be run
  command1=". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  command2="nix profile install nixpkgs#jellyfin"

  # Run the commands
  eval "$command1"
  eval "$command2"


}

run_securitypack() {
  # Define the commands to be run
  command1="sudo nala install -y ufw fail2ban net-tools iptables"

  # Run the commands
  eval "$command1"
}


configure_jellyfin_account() {

#!/bin/bash

# Install necessary packages
sudo nala install -y vainfo i965-va-driver-shaders

# Add the Jellyfin user to the video group
sudo usermod -aG video leo

sudo mkdir -p /etc/jellyfin/
sudo touch /etc/jellyfin/encoding.xml

# Enable VAAPI hardware acceleration for Jellyfin (requires Intel GPU)
echo "hardwareAcceleration.enableVAAPI = true" >> /etc/jellyfin/encoding.xml

# Define the device path for VAAPI (requires Intel GPU)
echo "hardwareAcceleration.vaapiDevicePath = \"/dev/dri/renderD128\"" >> /etc/jellyfin/encoding.xml

# Define the driver type for VAAPI (requires Intel GPU)
echo "hardwareAcceleration.vaapiDriverTypeOverride = \"i965\"" >> /etc/jellyfin/encoding.xml

# Drop advanced subtitles for VAAPI (requires Intel GPU)
echo "hardwareAcceleration.vaapiDropAdvancedSubtitlesOverride = true" >> /etc/jellyfin/encoding.xml

# Define the output format for VAAPI (requires Intel GPU)
echo "hardwareAcceleration.vaapiHwaccelOutputFormatOverride = \"vaapi_vld\"" >> /etc/jellyfin/encoding.xml

# Allow hwaccel transcoding for VAAPI (requires Intel GPU)
echo "hardwareAcceleration.vaapiAllowHwaccelTranscodingOverride = true" >> /etc/jellyfin/encoding.xml

# Allow hwaccel decoder for VAAPI (requires Intel GPU)
echo "hardwareAcceleration.vaapiAllowHwaccelDecoderOverride = true" >> /etc/jellyfin/encoding.xml

# Allow hwaccel encoder for VAAPI (requires Intel GPU)
echo "hardwareAcceleration.vaapiAllowHwaccelEncoderOverride = true" >> /etc/jellyfin/encoding.xml

# Set ownership of Jellyfin files to jellyfin user
sudo chown -R jellyfin:leo /var/lib/jellyfin
sudo chown -R jellyfin:leo /etc/jellyfin
sudo chown -R jellyfin:leo /usr/share/jellyfin
sudo chown -R jellyfin:leo /var/log/jellyfin
}

create_jellyfin_service() {
  # Define the service code
  service_code='[Unit]
Description=Jellyfin Media Server
After=network.target

[Service]
User=leo
Group=leo
UMask=002

Type=simple
ExecStart=/nix/var/nix/profiles/default/bin/jellyfin
Restart=on-failure
RestartSec=5
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target'

  # Create the service file
  echo "$service_code" > /etc/systemd/system/jellyfin.service

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
    sudo sysctl net.ipv4.conf.all.rp_filter
    sudo sysctl -a --pattern 'net.ipv4.conf.(eth|wlan)0.arp'

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

# Set the static IP address
echo "auto eth0" >> /etc/network/interfaces
echo "iface eth0 inet static" >> /etc/network/interfaces
echo "address 10.10.1.25" >> /etc/network/interfaces
echo "netmask 255.255.255.0" >> /etc/network/interfaces
echo "gateway 10.10.1.1" >> /etc/network/interfaces

# Set the primary DNS suffix
echo "search pfsense.home" >> /etc/resolv.conf

# Set the DNS address
echo "nameserver 10.10.1.1" >> /etc/resolv.conf

# Set additional settings for a 1Gbps Ethernet LAN
ethtool -s eth0 speed 1000 duplex full autoneg off
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
run_nala_fetch

#Install Additional Packages
run_nala_installPackages

#Sets the Nix Enviroment so it can be used and installs jellyfin
run_nix_install
run_nixjellyfin

#Create and configure Jellyfin service account
configure_jellyfin_account

#Create and start Jellyfin service
create_jellyfin_service

#Install Security packages
run_securitypack

#Hardens Server
setup_security

#ConfigureLan & Static IP
setup_lan

#Set additional configuration optios
run_linux_tweaks

echo "Script finished."
echo "Check /etc/network/interfaces and /etc/resolv.conf for any network mismatches."
