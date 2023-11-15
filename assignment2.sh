#!/bin/bash
# Vadim Lobarev 200530998
# Assignment 2



# Check /etc/hosts
echo "Checking /etc/hosts..."
if ! grep -q "^192.168.16.21\s*$(hostname)\s*home.arpa\s*localdomain$" /etc/hosts; then
    echo "Change required to /etc/hosts"
    echo "Updating /etc/hosts..."
    sudo sed -i "/^192.168.16.21/s/.*/192.168.16.21   $(hostname) home.arpa localdomain/" /etc/hosts
else
    echo "/etc/hosts is already configured."
fi



# Check installed software
echo "Checking installed software..."
required_software=("openssh-server" "apache2" "squid" "ufw")
missing_software=()
for software in "${required_software[@]}"; do
    if ! dpkg -l | grep -q "ii  $software "; then
        missing_software+=("$software")
    fi
done

if [ ${#missing_software[@]} -gt 0 ]; then
    echo "Change required: Install the following software packages:"
    for package in "${missing_software[@]}"; do
        echo "Installing: $package"
        sudo apt-get install -y "$package"
    done
else
    echo "All required software is already installed."
fi

# Check SSH configuration
echo "Checking SSH configuration..."
if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    echo "Change required: Set 'PasswordAuthentication no' in /etc/ssh/sshd_config"
    sudo sed -i '/^PasswordAuthentication/s/.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo service ssh restart
else
    echo "SSH configuration is already set to 'PasswordAuthentication no.'"
fi

# Check Apache configuration
echo "Checking Apache configuration..."
if ! apachectl -t -D DUMP_MODULES | grep -q "ssl_module"; then
    echo "Change required: Enable the SSL module in Apache"
    sudo a2enmod ssl
    sudo systemctl restart apache2
else
    echo "SSL module is already enabled in Apache."
fi

# Check Squid configuration
echo "Checking Squid configuration..."
if ! grep -q "^http_access allow localnet" /etc/squid/squid.conf; then
    echo "Change required: Add 'http_access allow localnet' to /etc/squid/squid.conf"
    echo "http_access allow localnet" | sudo tee -a /etc/squid/squid.conf
    sudo service squid restart
else
    echo "Squid configuration already allows 'localnet' access."
fi



# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
    echo "UFW is not installed on this system."
    exit 1
fi

# Check if UFW is active
if ! sudo ufw status | grep -q "Status: active"; then
    echo "Enabling UFW..."
    sudo ufw enable
fi

# Check if SSH rule exists (IPv4)
if sudo ufw status | grep -q "22.*ALLOW.*Anywhere"; then
    echo "SSH (port 22) rule already exists."
else
    echo "Change required:SSH (port 22)"
    sudo ufw allow 22
    echo "SSH (port 22) rule added."
fi

# Check if HTTP rule exists (IPv4)
if sudo ufw status | grep -q "80.*ALLOW.*Anywhere"; then
    echo "HTTP (port 80) rule already exists."
else
    echo "Change required:HTTP (port 80)"
    sudo ufw allow 80
    echo "HTTP (port 80) rule added."
fi

# Check if HTTPS rule exists (IPv4)
if sudo ufw status | grep -q "443.*ALLOW.*Anywhere"; then
    echo "HTTPS (port 443) rule already exists."
else
    echo "Change required:HTTPS (port 443)"
    sudo ufw allow 443
    echo "HTTPS (port 443) rule added."
fi

# Check if web proxy rule exists (IPv4)
if sudo ufw status | grep -q "3128.*ALLOW.*Anywhere"; then
    echo "Web Proxy (port 3128) rule already exists."
else
    echo "Change required:Web Proxy (port 3128)"
    sudo ufw allow 3128
    echo "Web Proxy (port 3128) rule added."
fi

# Display UFW status
# echo "Updated UFW Rules:"
# sudo ufw status



# Check user accounts and SSH keys
echo "Checking user accounts and SSH keys..."
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for user in "${users[@]}"; do
    if ! id "$user" &>/dev/null; then
        echo "Change required: Create user '$user'"
        sudo adduser "$user"
    else
        ssh_dir="/home/$user/.ssh"
        authorized_keys_file="$ssh_dir/authorized_keys"

        if [ ! -d "$ssh_dir" ] || [ ! -f "$authorized_keys_file" ]; then
            echo "Change required: Set up SSH keys for user '$user'"
            if [ ! -d "$ssh_dir" ]; then
                sudo -u "$user" mkdir -p "$ssh_dir"
            fi
            if [ ! -f "$authorized_keys_file" ]; then
                sudo -u "$user" touch "$authorized_keys_file"
            fi
        else
            echo "SSH keys are already set up for user '$user'."
        fi
    fi
done


sudoers_file="/etc/sudoers.d/dennis_nopasswd"

if [ ! -f "$sudoers_file" ]; then
    echo "Change required: Allow 'dennis' to use sudo without a password"
    echo "dennis ALL=(ALL) NOPASSWD:ALL" | sudo tee -a "$sudoers_file"
else
    echo "Sudo access for 'dennis' is already configured."
fi




echo "Script execution complete."

