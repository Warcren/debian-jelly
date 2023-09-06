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

#Create Jellyfin Service Account
sudo useradd -r -s /bin/false jellyfin
sudo adduser jellyfin sudo

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
    sudo nala install -y xz-utils git curl nano debconf
}

run_nixjellyfin() {
  # Define the commands to be run
  sudo mkdir -p /home/jellyfin/
  sudo chown jellyfin:leo /home/jellyfin
  cd /home/jellyfin
  
  sudo -u jellyfin curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  command1="sudo -u jellyfin /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  command2="sudo -u jellyfin /nix/var/nix/profiles/default/bin/nix profile install nixpkgs#jellyfin profile install nixpkgs#jellyfin"

  # Run the commands
  eval "$command1"
  eval "$command2"

}

configure_jellyfin_account() {

#!/bin/bash

# Install necessary packages
sudo nala install -y vainfo i965-va-driver-shaders

# Add the Jellyfin user to the video group
sudo usermod -aG video jellyfin

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
sudo chown -R jellyfin:jellyfin /var/lib/jellyfin
sudo chown -R jellyfin:jellyfin /etc/jellyfin
sudo chown -R jellyfin:jellyfin /usr/share/jellyfin
sudo chown -R jellyfin:jellyfin /var/log/jellyfin
}

create_jellyfin_service() {
  # Define the service code
  service_code='[Unit]
Description=Jellyfin Media Server
After=network.target

[Service]
User=jellyfin
Group=jellyfin
UMask=002

Type=simple
ExecStart=/home/jellyfin/.nix-profile/bin/jellyfin
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

#Main Scrip
run_nala_install
run_nala_fetch
run_nala_installPackages
run_nixjellyfin
#configure_jellyfin_account
#create_jellyfin_service
