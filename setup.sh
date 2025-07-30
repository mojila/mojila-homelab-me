#!/bin/bash

# Ubuntu Noble Hotspot Setup Script
# This script creates a WiFi hotspot using NetworkManager

echo "Setting up WiFi hotspot..."

# Create hotspot connection
nmcli connection add type wifi ifname wlan0 con-name hotspot autoconnect no ssid Homelab \
    mode ap \
    ip4 192.168.4.1/24 \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "homelab123" \
    ipv4.method shared

echo "Hotspot configuration created successfully!"
echo "To start the hotspot, run: nmcli connection up hotspot"
echo "To stop the hotspot, run: nmcli connection down hotspot"
echo "SSID: Homelab"
echo "Password: homelab123"
echo "Gateway IP: 192.168.4.1"