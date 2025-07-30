#!/bin/bash

# Installation script for Bluetooth Auto-Setup on Ubuntu/Orange Pi
# This script installs and configures automatic Bluetooth setup at boot

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="bluetooth-auto-setup"
SCRIPT_NAME="bluetooth-setup.sh"
SERVICE_FILE="${SERVICE_NAME}.service"
INSTALL_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system"

echo "=== Bluetooth Auto-Setup Installer ==="
echo "This script will:"
echo "1. Install the Bluetooth setup script"
echo "2. Create and enable a systemd service"
echo "3. Configure Bluetooth for auto-discovery at boot"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    echo "Usage: sudo $0"
    exit 1
fi

# Check if required files exist
if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
    echo "Error: $SCRIPT_NAME not found in current directory"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/$SERVICE_FILE" ]; then
    echo "Error: $SERVICE_FILE not found in current directory"
    exit 1
fi

# Function to check if Bluetooth is available
check_bluetooth() {
    echo "Checking Bluetooth availability..."
    
    if ! command -v bluetoothctl &> /dev/null; then
        echo "Error: bluetoothctl not found. Please install BlueZ:"
        echo "sudo apt update && sudo apt install bluez"
        exit 1
    fi
    
    if ! systemctl list-unit-files | grep -q "bluetooth.service"; then
        echo "Error: Bluetooth service not found. Please install BlueZ:"
        echo "sudo apt update && sudo apt install bluez"
        exit 1
    fi
    
    echo "✓ Bluetooth/BlueZ is available"
}

# Function to install the script
install_script() {
    echo "Installing Bluetooth setup script..."
    
    # Copy script to system location
    cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_PATH/$SCRIPT_NAME"
    chmod +x "$INSTALL_PATH/$SCRIPT_NAME"
    
    echo "✓ Script installed to $INSTALL_PATH/$SCRIPT_NAME"
}

# Function to install and enable the service
install_service() {
    echo "Installing systemd service..."
    
    # Copy service file
    cp "$SCRIPT_DIR/$SERVICE_FILE" "$SERVICE_PATH/$SERVICE_FILE"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable the service
    systemctl enable "$SERVICE_NAME"
    
    echo "✓ Service installed and enabled"
}

# Function to start Bluetooth service
start_bluetooth_service() {
    echo "Ensuring Bluetooth service is running..."
    
    systemctl enable bluetooth
    systemctl start bluetooth
    
    echo "✓ Bluetooth service is running"
}

# Function to test the setup
test_setup() {
    echo "Testing the setup..."
    
    # Start our service
    systemctl start "$SERVICE_NAME"
    
    # Check service status
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "✓ Service started successfully"
    else
        echo "⚠ Service failed to start. Checking logs..."
        journalctl -u "$SERVICE_NAME" --no-pager -n 10
        return 1
    fi
    
    # Wait a moment for Bluetooth to configure
    sleep 3
    
    # Check Bluetooth status
    if bluetoothctl show | grep -q "Powered: yes"; then
        echo "✓ Bluetooth is powered on"
    else
        echo "⚠ Bluetooth is not powered on"
        return 1
    fi
    
    if bluetoothctl show | grep -q "Discoverable: yes"; then
        echo "✓ Bluetooth is discoverable"
    else
        echo "⚠ Bluetooth is not discoverable"
        return 1
    fi
    
    echo "✓ All tests passed!"
}

# Function to show status and next steps
show_completion() {
    echo ""
    echo "🎉 Installation completed successfully!"
    echo ""
    echo "Your Orange Pi will now automatically configure Bluetooth at boot to be:"
    echo "- Powered on"
    echo "- Pairable"
    echo "- Discoverable"
    echo ""
    echo "Useful commands:"
    echo "- Check service status: sudo systemctl status $SERVICE_NAME"
    echo "- View service logs: sudo journalctl -u $SERVICE_NAME -f"
    echo "- Restart service: sudo systemctl restart $SERVICE_NAME"
    echo "- Disable service: sudo systemctl disable $SERVICE_NAME"
    echo "- Manual setup: sudo $INSTALL_PATH/$SCRIPT_NAME"
    echo ""
    echo "Bluetooth status:"
    bluetoothctl show 2>/dev/null | grep -E "(Powered|Discoverable|Pairable)" || echo "Run 'bluetoothctl show' to check status"
}

# Function to uninstall (if requested)
uninstall() {
    echo "Uninstalling Bluetooth auto-setup..."
    
    # Stop and disable service
    systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    
    # Remove files
    rm -f "$SERVICE_PATH/$SERVICE_FILE"
    rm -f "$INSTALL_PATH/$SCRIPT_NAME"
    
    # Reload systemd
    systemctl daemon-reload
    
    echo "✓ Uninstallation completed"
    exit 0
}

# Parse command line arguments
if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
    uninstall
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: sudo $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h        Show this help message"
    echo "  --uninstall, -u   Uninstall the Bluetooth auto-setup"
    echo ""
    echo "This script installs automatic Bluetooth configuration for Orange Pi."
    exit 0
fi

# Main installation process
echo "Starting installation..."
echo ""

check_bluetooth
start_bluetooth_service
install_script
install_service

echo ""
echo "Testing the installation..."
if test_setup; then
    show_completion
else
    echo ""
    echo "❌ Installation completed but testing failed."
    echo "The service is installed but may need manual configuration."
    echo "Check logs with: sudo journalctl -u $SERVICE_NAME -f"
fi