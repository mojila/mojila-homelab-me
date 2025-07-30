#!/bin/bash

# WiFi Connection Script
# Usage: ./wifi-connect.sh --ssid="SSID Name" --password="password"
# This script turns off hotspot and connects to a specified WiFi network

# Initialize variables
SSID=""
PASSWORD=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ssid=*)
            SSID="${1#*=}"
            shift
            ;;
        --password=*)
            PASSWORD="${1#*=}"
            shift
            ;;
        --ssid)
            SSID="$2"
            shift 2
            ;;
        --password)
            PASSWORD="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 --ssid=\"SSID Name\" --password=\"password\""
            echo "   or: $0 --ssid \"SSID Name\" --password \"password\""
            echo ""
            echo "Options:"
            echo "  --ssid=SSID        WiFi network name (SSID)"
            echo "  --password=PASS    WiFi network password"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --ssid=\"My Home WiFi\" --password=\"mypassword123\""
            echo "  $0 --ssid \"Coffee Shop\" --password \"guestpass\""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$SSID" ] || [ -z "$PASSWORD" ]; then
    echo "Error: Both --ssid and --password are required"
    echo "Usage: $0 --ssid=\"SSID Name\" --password=\"password\""
    echo "Use --help for more information"
    exit 1
fi

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
if nmcli connection show | grep -Fq "$SSID"; then
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

if nmcli connection show --active | grep -Fq "$SSID"; then
    echo "✓ Successfully connected to '$SSID'"
    echo ""
    echo "Connection Details:"
    nmcli connection show --active | grep -F "$SSID"
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