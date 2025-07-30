#!/bin/bash

# Ubuntu Noble Hotspot Uninstall Script
# This script removes the WiFi hotspot setup and systemd services

echo "Uninstalling WiFi hotspot setup..."

# Stop and disable the systemd timer and service
echo "Stopping and disabling WiFi monitor service..."
sudo systemctl stop wifi-monitor.timer 2>/dev/null || true
sudo systemctl disable wifi-monitor.timer 2>/dev/null || true
sudo systemctl stop wifi-monitor.service 2>/dev/null || true
sudo systemctl disable wifi-monitor.service 2>/dev/null || true

# Remove systemd service files
echo "Removing systemd service files..."
sudo rm -f /etc/systemd/system/wifi-monitor.service
sudo rm -f /etc/systemd/system/wifi-monitor.timer

# Reload systemd to reflect changes
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Stop any active hotspot
echo "Stopping any active hotspot..."
nmcli device disconnect wlan0 2>/dev/null || true

# Remove hotspot connections
echo "Removing hotspot connections..."
nmcli connection delete "Hotspot" 2>/dev/null || true
nmcli connection delete "hotspot" 2>/dev/null || true
nmcli connection delete "Homelab" 2>/dev/null || true

# Clean up any auto-generated hotspot connections
echo "Cleaning up auto-generated connections..."
nmcli connection show | grep -i hotspot | awk '{print $1}' | xargs -I {} nmcli connection delete "{}" 2>/dev/null || true

echo ""
echo "Uninstall completed successfully!"
echo "=========================================="
echo "Removed components:"
echo "  ✓ WiFi monitor systemd service and timer"
echo "  ✓ Systemd service files"
echo "  ✓ Hotspot connections"
echo "  ✓ Active hotspot (if running)"
echo ""
echo "Note: The script files (setup.sh, wifi-check.sh, wifi-connect.sh)"
echo "      have been left intact and can be removed manually if desired."
echo ""
echo "To verify removal:"
echo "  Check services: systemctl list-timers | grep wifi-monitor"
echo "  Check connections: nmcli connection show"
echo "  Check device status: nmcli device status"