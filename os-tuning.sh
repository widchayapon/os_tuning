#!/bin/bash

# Update package lists
echo "Updating package lists..."
sudo apt update -y
sleep 2

# Upgrade installed packages
echo "Upgrading installed packages..."
sudo apt upgrade -y
sleep 2

# Disable and stop systemd-resolved
echo "Disabling and stopping systemd-resolved..."
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved
sleep 2

# Remove existing resolv.conf and create a new one
echo "Updating /etc/resolv.conf with new nameservers..."
sudo rm -rf /etc/resolv.conf
cat <<EOF | sudo tee /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
sleep 2

# Disable UFW
echo "Disabling UFW..."
sudo ufw disable
sleep 2

# Check UFW status
echo "Checking UFW status..."
sudo ufw status
echo "------------------------------------------------------------"
sleep 2

# Stop and disable ds_agent service
echo "Stopping and disabling ds_agent service..."
sudo systemctl stop ds_agent
sleep 2
sudo systemctl disable ds_agent
sleep 2


# Disable IPv6 in sysctl
echo ">> Disable IPv6 in sysctl ... "
cat <<EOF | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
### Disable IPv6 ###
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
sudo sysctl -p

# ตรวจสอบไฟล์ /etc/netplan/00-installer-config.yaml
if [ -f "/etc/netplan/00-installer-config.yaml" ]; then
    echo "เจอไฟล์ /etc/netplan/00-installer-config.yaml"
    config_file="/etc/netplan/00-installer-config.yaml"
    temp_file="/tmp/netplan_temp.yaml"

    cp "$config_file" "$temp_file"
    sleep 2

    # แก้ไขค่า nameservers
    sed -i 's/203.150.213.1/1.1.1.1/' "$temp_file"
    sed -i 's/203.150.218.161/8.8.8.8/' "$temp_file"
    sleep 2

    # เขียนกลับไปยังไฟล์ YAML
    sudo cp "$temp_file" "$config_file"
    sleep 2

    # ลบไฟล์ชั่วคราว
    rm "$temp_file"
    sleep 2

    # สร้างคำสั่งสำหรับทำให้การตั้งค่าเครือข่ายเป็นปัจจุบัน
    sudo netplan apply
    sleep 2

    # Display completion message
    echo "Nameservers updated and netplan configuration applied successfully!"
    echo "-------------------------------------------------------------------------------------------"
    echo "OS-tunning complete !!"
else
    # ตรวจสอบไฟล์ /etc/netplan/01-netcfg.yaml หากไม่เจอ /etc/netplan/00-installer-config.yaml
    if [ -f "/etc/netplan/01-netcfg.yaml" ]; then
        echo "เจอไฟล์ /etc/netplan/01-netcfg.yaml"
        NETPLAN_CONFIG_FILE="/etc/netplan/01-netcfg.yaml"

        # Backup the original configuration file
        echo "Backing up the original netplan configuration file..."
        sudo cp $NETPLAN_CONFIG_FILE ${NETPLAN_CONFIG_FILE}.bak
        sleep 2

        # Update the nameservers
        echo "Updating the nameservers in the netplan configuration file..."
        sudo sed -i 's/addresses: \[203.150.213.1,203.150.218.161\]/addresses: [1.1.1.1,8.8.8.8]/' $NETPLAN_CONFIG_FILE
        sleep 2

        # Apply the netplan configuration
        echo "Applying the netplan configuration..."
        sudo netplan apply
        sleep 2

        # Display completion message
        echo "Nameservers updated and netplan configuration applied successfully!"
        echo "-------------------------------------------------------------------------------------------"
        echo "OS-tunning complete !!"
    else
        echo "ไม่เจอไฟล์ /etc/netplan/00-installer-config.yaml และไม่เจอไฟล์ /etc/netplan/01-netcfg.yaml"
    fi
fi


hostname=$(hostname)
cp /etc/hosts /etc/hosts.bak
sed -i "/127.0.1.1 ubuntu22/a 127.0.1.1 $hostname" /etc/hosts
echo "แก้ไขไฟล์ /etc/hosts ได้แล้วนิ "

# Reboot the system
sudo reboot


