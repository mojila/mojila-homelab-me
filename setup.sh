#!/bin/bash

# Ubuntu Noble Hotspot Setup Script
# This script creates a WiFi hotspot using NetworkManager

echo "Setting up WiFi hotspot..."

# Ensure WiFi is enabled
echo "Configuring WiFi interface..."
nmcli radio wifi on

# Stop any existing hotspot and clean up old connections
echo "Stopping any existing hotspot..."
nmcli device disconnect wlan0 2>/dev/null || true

# Delete any existing hotspot connections (including old 'Hotspot' with capital H)
echo "Cleaning up old hotspot connections..."
nmcli connection delete "Hotspot" 2>/dev/null || true
nmcli connection delete "hotspot" 2>/dev/null || true
nmcli connection delete "Homelab" 2>/dev/null || true

# Create hotspot using simplified command
echo "Creating WiFi hotspot..."
sudo nmcli device wifi hotspot ssid Homelab password homelab123 ifname wlan0

echo "Hotspot configuration created successfully!"

# Test hotspot connection
echo "Testing hotspot connection..."
if nmcli device status | grep -q "wlan0.*connected"; then
    echo "✓ Hotspot is active!"
    sleep 2
    echo "✓ Hotspot will be managed by the WiFi monitor service"
else
    echo "⚠ Hotspot may not be active. This will be handled by the WiFi monitor service."
fi

# Get the current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create systemd service for wifi-check
echo "Creating systemd service for WiFi monitoring..."

# Create the service file
sudo tee /etc/systemd/system/wifi-monitor.service > /dev/null <<EOF
[Unit]
Description=WiFi Monitor and Hotspot Fallback
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_DIR/wifi-check.sh
User=root
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

# Create timer for the service (runs every 30 seconds)
sudo tee /etc/systemd/system/wifi-monitor.timer > /dev/null <<EOF
[Unit]
Description=Run WiFi Monitor every 30 seconds
Requires=wifi-monitor.service

[Timer]
OnBootSec=60
OnUnitActiveSec=30
Unit=wifi-monitor.service

[Install]
WantedBy=timers.target
EOF

# Make wifi-check.sh executable
chmod +x "$SCRIPT_DIR/wifi-check.sh"

# Reload systemd and enable the timer
echo "Enabling and starting WiFi monitor service..."
sudo systemctl daemon-reload
sudo systemctl enable wifi-monitor.timer
sudo systemctl start wifi-monitor.timer

echo ""
echo "Setup completed successfully!"
echo "=========================================="
echo "Hotspot Details:"
echo "  SSID: Homelab"
echo "  Password: homelab123"
echo "  Gateway IP: 192.168.4.1"
echo ""
echo "WiFi Monitor Service:"
echo "  Service: wifi-monitor.service"
echo "  Timer: wifi-monitor.timer (runs every 30 seconds)"
echo "  Status: systemctl status wifi-monitor.timer"
echo ""
echo "Manual Commands:"
echo "  Start hotspot: sudo nmcli device wifi hotspot ssid Homelab password homelab123 ifname wlan0"
echo "  Stop hotspot: nmcli device disconnect wlan0"
echo "  Check service: systemctl status wifi-monitor.timer"
echo "  View logs: journalctl -u wifi-monitor.service -f"