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
echo "  Start hotspot: nmcli connection up hotspot"
echo "  Stop hotspot: nmcli connection down hotspot"
echo "  Check service: systemctl status wifi-monitor.timer"
echo "  View logs: journalctl -u wifi-monitor.service -f"