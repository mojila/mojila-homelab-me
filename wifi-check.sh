#!/bin/bash

WIFI_INTERFACE="wlan0"
HOTSPOT_NAME="hotspot"

# Wait for system to settle
sleep 20

CONNECTED=$(nmcli -t -f WIFI g)
ACTIVE_CON=$(nmcli -t -f DEVICE,STATE dev | grep "$WIFI_INTERFACE" | grep "connected")

if [[ "$CONNECTED" != "enabled" || -z "$ACTIVE_CON" ]]; then
    echo "No Wi-Fi connected. Enabling hotspot..."
    nmcli connection up "$HOTSPOT_NAME"
else
    echo "Wi-Fi is connected. No need to enable hotspot."
fi
