#!/bin/bash
# Vadim Lobarev 200530998
# Assignment 2


#!/bin/bash

# Check /etc/hosts
echo "Checking /etc/hosts..."
if ! grep -q "192.168.16.21\s$(hostname)\shome.arpa\slocaldomain" /etc/hosts; then
    echo "Change required: Add the following line to /etc/hosts"
    echo "192.168.16.21   $(hostname) home.arpa localdomain"
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
        echo "$package"
    done
fi

# Check SSH configuration
echo "Checking SSH configuration..."
if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    echo "Change required: Set 'PasswordAuthentication no' in /etc/ssh/sshd_config"
fi

# Check Apache configuration
echo "Checking Apache configuration..."
if ! apachectl -t -D DUMP_MODULES | grep -q "ssl_module"; then
    echo "Change required: Enable the SSL module in Apache"
fi

# Check Squid configuration
echo "Checking Squid configuration..."
if ! grep -q "^http_access allow localnet" /etc/squid/squid.conf; then
    echo "Change required: Add 'http_access allow localnet' to /etc/squid/squid.conf"
fi

# Check UFW configuration
echo "Checking UFW configuration..."
if ! ufw status | grep -q "22.*ALLOW"; then
    echo "Change required: Allow SSH (port 22) in UFW"
fi

if ! ufw status | grep -q "80.*ALLOW"; then
    echo "Change required: Allow HTTP (port 80) in UFW"
fi

if ! ufw status | grep -q "443.*ALLOW"; then
    echo "Change required: Allow HTTPS (port 443) in UFW"
fi

if ! ufw status | grep -q "3128.*ALLOW"; then
    echo "Change required: Allow Squid (port 3128) in UFW"
fi

# Check user accounts and SSH keys
echo "Checking user accounts and SSH keys..."
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for user in "${users[@]}"; do
    if ! id "$user" &>/dev/null; then
        echo "Change required: Create user '$user'"
    else
        ssh_dir="/home/$user/.ssh"
        authorized_keys_file="$ssh_dir/authorized_keys"

        if [ ! -d "$ssh_dir" ] || [ ! -f "$authorized_keys_file" ]; then
            echo "Change required: Set up SSH keys for user '$user'"
        fi
    fi
done

# Check sudo access for dennis
echo "Checking sudo access for user 'dennis'..."
if ! sudo -lU dennis | grep -q "(ALL) NOPASSWD:ALL"; then
    echo "Change required: Allow 'dennis' to use sudo without a password"
fi

echo "Script execution complete."

