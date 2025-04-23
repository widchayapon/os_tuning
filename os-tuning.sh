#!/bin/bash

echo "============================================================================="
echo ">>> Task 1 (1/2): Updating package lists..."
sudo apt update -y
sleep 2
echo "============================================================================="

echo "============================================================================="
echo ">>> Task 1 (2/2): Upgrading installed packages..."
sudo apt upgrade -y
sleep 2
echo "============================================================================="

echo ""
echo ""

echo "============================================================================="
echo ">>> Task 2 (1/2): Disabling and stopping systemd-resolved..."
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved
sleep 2
echo "============================================================================="

echo "============================================================================="
echo ">>> Task 2 (2/2): Updating /etc/resolv.conf with new nameservers..."
sudo rm -rf /etc/resolv.conf
cat <<EOF | sudo tee /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
sleep 2
echo "============================================================================="

echo ""
echo ""

echo "============================================================================="
echo ">>> Task 3: Updating /etc/hosts with the current hostname..."
hostname=$(hostname)
cp /etc/hosts /etc/hosts.bak
sed -i "/127.0.1.1 ubuntu22/a 127.0.1.1 $hostname" /etc/hosts
echo "Task 3: /etc/hosts has been updated."
echo "============================================================================="

echo ""
echo ""

echo "============================================================================="
echo ">>> Task 4 (1/2): Disabling UFW firewall..."
sudo ufw disable
sleep 2
echo "============================================================================="

echo "============================================================================="
echo ">>> Task 4 (2/2): Checking UFW status..."
sudo ufw status
sleep 2
echo "============================================================================="

echo ""
echo ""

echo "============================================================================="
echo ">>> Task 5: Stopping and disabling ds_agent service..."
sudo systemctl stop ds_agent
sleep 2
sudo systemctl disable ds_agent
sleep 2
echo "============================================================================="


echo ""
echo ""

echo "============================================================================="
echo ">>> Task 6: Disabling IPv6 in sysctl..."
cat <<EOF | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
### Disable IPv6 ###
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
sudo sysctl -p
sleep 2
echo "============================================================================="

echo ""
echo ""

echo "============================================================================="
echo ">>> Task 7: Checking netplan configuration files..."
if [ -f "/etc/netplan/00-installer-config.yaml" ]; then
    echo "Found: /etc/netplan/00-installer-config.yaml"
    config_file="/etc/netplan/00-installer-config.yaml"
    temp_file="/tmp/netplan_temp.yaml"

    cp "$config_file" "$temp_file"
    sleep 2

    echo "Updating nameservers in the configuration..."
    sed -i 's/203.150.213.1/1.1.1.1/' "$temp_file"
    sed -i 's/203.150.218.161/8.8.8.8/' "$temp_file"
    sleep 2

    sudo cp "$temp_file" "$config_file"
    rm "$temp_file"
    sleep 2

    echo "Applying the updated netplan configuration..."
    sudo netplan apply
    echo "Netplan configuration applied successfully."
else
    if [ -f "/etc/netplan/01-netcfg.yaml" ]; then
        echo "Found: /etc/netplan/01-netcfg.yaml"
        NETPLAN_CONFIG_FILE="/etc/netplan/01-netcfg.yaml"

        echo "Backing up the original configuration..."
        sudo cp $NETPLAN_CONFIG_FILE ${NETPLAN_CONFIG_FILE}.bak
        sleep 2

        echo "Updating nameservers..."
        sudo sed -i 's/addresses: \[203.150.213.1,203.150.218.161\]/addresses: [1.1.1.1,8.8.8.8]/' $NETPLAN_CONFIG_FILE
        sleep 2

        echo "Applying the updated configuration..."
        sudo netplan apply
        echo "Netplan configuration applied successfully."
    else
        echo "No suitable netplan configuration file found."
    fi
fi
echo "============================================================================="

echo ""
echo ""

echo "============================================================================="
echo ">>> Task 8: Checking connectivity to specified endpoints..."

# Define endpoints
endpoints="git.inet.co.th kb.sdi.one.th"

# Function to display progress bar
show_progress() {
    progress=0
    while [ $progress -le 100 ]; do
        sleep 0.02  # Simulate progress
        printf "\rProgress: ["
        i=0
        while [ $i -lt 50 ]; do
            if [ $((i * 2)) -lt $progress ]; then
                printf "="
            else
                printf " "
            fi
            i=$((i + 1))
        done
        printf "] %d%%" "$progress"
        progress=$((progress + 2))
    done
    printf "\n"
}

# Loop through each endpoint
for endpoint in $endpoints; do
    show_progress

    # Check endpoint connectivity
    printf "Checking %s... " "$endpoint"
    if curl -s --head --fail "https://$endpoint" > /dev/null; then
        printf "\033[1;32m→ Success:\033[0m %s is reachable.\n" "$endpoint" # Green arrow for Success
    else
        printf "\033[1;31m→ Failure:\033[0m %s is not reachable. Please contact the relevant team.\n" "$endpoint" # Red arrow for Failure
    fi

    echo ""
done

echo "============================================================================="

echo ""
echo ""

echo "============================================================================="
echo ">>> Task 9: Rebooting the system..."
sudo reboot
echo "============================================================================="