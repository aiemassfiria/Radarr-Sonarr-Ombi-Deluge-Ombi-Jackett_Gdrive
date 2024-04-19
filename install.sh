#!/bin/bash

# Update package lists
sudo apt update

# Install required packages
sudo apt install -y curl sqlite3

# Determine the architecture
arch=$(dpkg --print-architecture)
case $arch in
  amd64)
    arch=x64
    ;;
  arm*|arm64)
    arch=arm
    ;;
  *)
    echo "Unsupported architecture: $arch"
    exit 1
    ;;
esac

# Download Radarr
wget --content-disposition "http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=$arch"

# Extract Radarr
tar -xvzf Radarr*.linux*.tar.gz

# Move Radarr to /opt
sudo mv Radarr /opt/
sudo chown root:root -R /opt/Radarr

# Create systemd service for Radarr
cat << EOF | sudo tee /etc/systemd/system/radarr.service > /dev/null
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/opt/Radarr/Radarr -nobrowser -data=/var/lib/radarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon and enable Radarr service
sudo systemctl -q daemon-reload
sudo systemctl enable --now -q radarr

# Clean up Radarr downloaded files
rm Radarr*.linux*.tar.gz

# Add Sonarr repository key
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8

# Add Sonarr repository to sources.list.d
echo "deb https://apt.sonarr.tv/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/sonarr.list

# Update package lists for Sonarr
sudo apt update

# Install Sonarr
sudo apt install -y sonarr

# Add Ombi repository to sources.list.d
echo "deb https://apt.ombi.app/develop jessie main" | sudo tee /etc/apt/sources.list.d/ombi.list

# Add Ombi repository key
curl -sSL https://apt.ombi.app/pub.key | sudo apt-key add -

# Update package lists for Ombi
sudo apt update

# Install Ombi
sudo apt install -y ombi

# Update Ombi systemd service to use root user and group
sudo sed -i 's/User=.*/User=root/g' /lib/systemd/system/ombi.service
sudo sed -i 's/Group=.*/Group=root/g' /lib/systemd/system/ombi.service

# Reload systemd daemon
sudo systemctl daemon-reload

echo "Ombi installation completed."

# Update package lists
sudo apt update

# Install required packages
sudo apt install -y gnupg ca-certificates

# Add Mono repository key
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

# Add Mono repository to sources.list.d
echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list

# Update package lists for Mono
sudo apt update

# Install Mono
sudo apt install -y mono-devel

# Detect the system architecture
architecture=$(uname -m)

# Set the appropriate download URL based on the architecture
if [ "$architecture" == "x86_64" ]; then
    download_url="https://github.com/Jackett/Jackett/releases/download/v0.20.4148/Jackett.Binaries.LinuxAMDx64.tar.gz"
elif [ "$architecture" == "aarch64" ]; then
    download_url="https://github.com/Jackett/Jackett/releases/download/v0.20.4148/Jackett.Binaries.LinuxARM64.tar.gz"
else
    echo "Unsupported architecture: $architecture"
    exit 1
fi

# Download the file
echo "Downloading Jackett..."
wget "$download_url"

# Extract Jackett
tar -xvzf Jackett.Binaries.*.tar.gz

# Install Jackett systemd service
sudo useradd -m -p $(openssl passwd -1 jackett) jackett
sudo chown jackett:jackett -R "/root/Jackett"
sudo bash Jackett/install_service_systemd.sh

# Update Jackett systemd service to use root user and group
sudo sed -i 's/User=.*/User=root/g' /etc/systemd/system/jackett.service
sudo sed -i 's/Group=.*/Group=root/g' /etc/systemd/system/jackett.service
sudo chown root:root -R "/root/Jackett"

# Reload systemd daemon
sudo systemctl daemon-reload

# Check Jackett service status
sudo systemctl status jackett.service

# Restart Jackett service
sudo systemctl restart jackett.service

echo "Jackett installation completed."

# Add iptables rules
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8112 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8113 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9117 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 7878 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8989 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 5000 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 32400 -j ACCEPT

# Save iptables rules
sudo apt-get install netfilter-persistent

sudo netfilter-persistent save

#!/bin/bash

# Update package lists
sudo apt update

# Install Deluge daemon
sudo apt-get install -y deluged

# Install Deluge Web
sudo apt-get install -y deluge-web

# Create Deluged systemd service
sudo tee /etc/systemd/system/deluged.service > /dev/null <<EOT
[Unit]
Description=Deluge Bittorrent Client Daemon
After=network-online.target

[Service]
Type=simple
User=root
Group=root
UMask=000
ExecStart=/usr/bin/deluged -d
Restart=on-failure
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
EOT

# Start and enable Deluged service
sudo systemctl start deluged
sudo systemctl enable deluged

# Create Deluge Web systemd service
sudo tee /etc/systemd/system/deluge-web.service > /dev/null <<EOT
[Unit]
Description=Deluge Bittorrent Client Web Interface
After=network-online.target

[Service]
Type=simple
User=root
Group=root
UMask=027
ExecStart=/usr/bin/deluge-web -d
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# Start and enable Deluge Web service
sudo systemctl start deluge-web
sudo systemctl enable deluge-web

echo "Deluge and Deluge Web installation completed."
echo "This is URGENT!!, Dont SKIP"
echo "Please open Deluge Web for the first time on your VPS at http://YourVPSIP:8112"
echo "Once you have opened Deluge Web, press Enter to continue."
read -p ""

# Search for the core.conf file and set the move_completed and move_completed_path options
config_file=~/.config/deluge/core.conf

if [[ -f "$config_file" ]]; then
    jq '.move_completed = true | .move_completed_path = "/root/Movies/RND/Movies"' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
    echo "Successfully updated core.conf"
else
    echo "core.conf file not found"
fi

echo "Successfully updated move completed Movie Path to /root/Movies/RND/Movies"
echo "You can access the Deluge Movies Web interface at http://YourVPSIP:8112"

# Create a copy of the Deluge configuration for the new instance
cp -a ~/.config/deluge ~/.config/deluge1

# Modify the configuration files for the new instance
sed -i 's/58846/58847/g' ~/.config/deluge1/hostlist.conf
sed -i 's/58846/58847/g; s/58646/58647/g' ~/.config/deluge1/core.conf
sed -i 's/8112/8113/g' ~/.config/deluge1/web.conf

# Search for the core.conf file and set the move_completed and move_completed_path options
config_file=~/.config/deluge1/core.conf

if [[ -f "$config_file" ]]; then
    jq '.move_completed = true | .move_completed_path = "/root/Movies/RND/Series"' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
    echo "Successfully updated core.conf"
else
    echo "core.conf file not found"
fi

echo "Successfully updated move completed Series Path to /root/Movies/RND/Series"

# Create the systemd service file for the new Deluge daemon
sudo tee /etc/systemd/system/deluged1.service > /dev/null <<EOT
[Unit]
Description=Deluge Bittorrent Client Daemon (New Instance)

[Service]
User=root
Group=root
ExecStart=/usr/bin/deluged -d -c /root/.config/deluge1

[Install]
WantedBy=multi-user.target
EOT

# Create the systemd service file for the new Deluge Web interface
sudo tee /etc/systemd/system/deluge-web1.service > /dev/null <<EOT
[Unit]
Description=Deluge Bittorrent Client Web Interface (New Instance)

[Service]
User=root
Group=root
ExecStart=/usr/bin/deluge-web -d -c /root/.config/deluge1

[Install]
WantedBy=multi-user.target
EOT

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable and start the new Deluge services
sudo systemctl enable deluged1
sudo systemctl start deluged1
sudo systemctl enable deluge-web1
sudo systemctl start deluge-web1

echo "New Deluge instance has been set up as a systemd service."
echo "You can access the new Deluge Series Web interface at http://YourVPSIP:8113"
