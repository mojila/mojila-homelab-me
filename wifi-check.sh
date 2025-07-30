#!/bin/bash

WIFI_INTERFACE="wlan0"
HOTSPOT_SSID="Homelab"
HOTSPOT_PASSWORD="homelab123"

# Wait for system to settle
sleep 20

# Check if WiFi is enabled
WIFI_ENABLED=$(nmcli -t -f WIFI g)

# Check if wlan0 is connected to a WiFi network (not hotspot mode)
WIFI_CONNECTED=$(nmcli -t -f DEVICE,TYPE,STATE dev | grep "$WIFI_INTERFACE:wifi:connected")

# Check if device is in hotspot mode
HOTSPOT_ACTIVE=$(nmcli device status | grep "$WIFI_INTERFACE" | grep -E "connected.*hotspot|connected.*ap")

if [[ "$WIFI_ENABLED" == "enabled" && -n "$WIFI_CONNECTED" && -z "$HOTSPOT_ACTIVE" ]]; then
    echo "Wi-Fi is connected to a network. Hotspot not needed."
elif [[ -n "$HOTSPOT_ACTIVE" ]]; then
    echo "Hotspot is already active."
else
    echo "No Wi-Fi connected. Enabling hotspot..."
    # Disconnect any existing connection first
    nmcli device disconnect "$WIFI_INTERFACE" 2>/dev/null || true
    # Start hotspot
    nmcli device wifi hotspot ssid "$HOTSPOT_SSID" password "$HOTSPOT_PASSWORD" ifname "$WIFI_INTERFACE"
fi
