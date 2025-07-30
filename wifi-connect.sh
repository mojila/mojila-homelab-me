#!/bin/bash

# WiFi Connection Script
# Usage: ./wifi-connect.sh <SSID> <PASSWORD>
# This script turns off hotspot and connects to a specified WiFi network

# Check if correct number of arguments provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <SSID> <PASSWORD>"
    echo "Example: $0 MyWiFi mypassword123"
    exit 1
fi

SSID="$1"
PASSWORD="$2"

echo "WiFi Connection Script"
echo "====================="
echo "Target SSID: $SSID"
echo ""

# Step 1: Turn off hotspot if it's running
echo "Step 1: Checking and stopping hotspot..."
if nmcli connection show --active | grep -q "hotspot"; then
    echo "Hotspot is active, turning it off..."
    nmcli connection down hotspot
    if [ $? -eq 0 ]; then
        echo "✓ Hotspot turned off successfully"
    else
        echo "✗ Failed to turn off hotspot"
        exit 1
    fi
else
    echo "✓ Hotspot is not active"
fi

echo ""

# Step 2: Check if WiFi connection already exists
echo "Step 2: Checking existing WiFi connections..."
if nmcli connection show | grep -q "$SSID"; then
    echo "Connection profile for '$SSID' already exists"
    echo "Attempting to connect using existing profile..."
    nmcli connection up "$SSID"
else
    echo "Creating new connection profile for '$SSID'..."
    # Step 3: Create and connect to WiFi
    nmcli device wifi connect "$SSID" password "$PASSWORD"
fi

echo ""

# Step 4: Verify connection
echo "Step 3: Verifying connection..."
sleep 3

if nmcli connection show --active | grep -q "$SSID"; then
    echo "✓ Successfully connected to '$SSID'"
    echo ""
    echo "Connection Details:"
    nmcli connection show --active | grep "$SSID"
    echo ""
    echo "IP Information:"
    ip addr show | grep -A 2 "wlan0" | grep "inet "
else
    echo "✗ Failed to connect to '$SSID'"
    echo "Please check:"
    echo "  - SSID name is correct"
    echo "  - Password is correct"
    echo "  - WiFi network is in range"
    exit 1
fi

echo ""
echo "WiFi connection completed successfully!"