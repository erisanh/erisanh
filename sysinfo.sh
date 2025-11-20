#!/usr/bin/env bash

echo "=============================="
echo "    SYSTEM INFORMATION"
echo "=============================="

echo -e "\n--- OS & KERNEL ---"
lsb_release -a 2>/dev/null
uname -a

echo -e "\n--- CPU INFO ---"
lscpu

echo -e "\n--- GPU INFO ---"
lspci | grep -E "VGA|3D|Display"

echo -e "\n--- RAM INFO ---"
free -h
echo
sudo dmidecode -t memory 2>/dev/null | grep -E "Size:|Type:|Speed:" | grep -v "No Module"

echo -e "\n--- DISK INFO ---"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
echo
df -hT

echo -e "\n--- BATTERY INFO ---"
upower -i $(upower -e | grep BAT) 2>/dev/null

echo -e "\n--- TEMPERATURE & SENSORS ---"
sensors 2>/dev/null

echo -e "\n--- MOTHERBOARD INFO ---"
sudo dmidecode -t baseboard 2>/dev/null

echo -e "\n--- BIOS INFO ---"
sudo dmidecode -t bios 2>/dev/null

echo -e "\n--- NETWORK INFO ---"
ip -br a
echo
sudo lshw -class network 2>/dev/null

echo -e "\n--- USB DEVICES ---"
lsusb

echo -e "\n--- PCI DEVICES ---"
lspci

echo -e "\n--- RUNNING SERVICES ---"
systemctl --type=service --state=running

echo -e "\n=============================="
echo "      END OF REPORT"
echo "=============================="
