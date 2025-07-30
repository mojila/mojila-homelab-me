#!/bin/bash

# Bluetooth Auto-Setup Script for Ubuntu on Orange Pi
# This script configures Bluetooth to be powered on, pairable, and discoverable

set -e

echo "Starting Bluetooth auto-setup..."

# Function to check if Bluetooth service is running
check_bluetooth_service() {
    if ! systemctl is-active --quiet bluetooth; then
        echo "Starting Bluetooth service..."
        sudo systemctl start bluetooth
        sleep 3
    fi
}

# Function to wait for Bluetooth adapter to be ready
wait_for_adapter() {
    local timeout=30
    local count=0
    
    echo "Waiting for Bluetooth adapter to be ready..."
    while [ $count -lt $timeout ]; do
        if bluetoothctl list | grep -q "Controller"; then
            echo "Bluetooth adapter found!"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    echo "Error: Bluetooth adapter not found after ${timeout} seconds"
    return 1
}

# Function to configure Bluetooth settings
configure_bluetooth() {
    echo "Configuring Bluetooth settings..."
    
    # Use expect-like approach with bluetoothctl
    {
        echo "power on"
        sleep 2
        echo "system-alias MyHomelab"
        sleep 1
        echo "pairable on"
        sleep 1
        echo "pairable-timeout 60"
        sleep 1
        echo "discoverable on"
        sleep 1
        echo "discoverable-timeout 0"
        sleep 1
        echo "agent on"
        sleep 1
        echo "default-agent"
        sleep 1
        echo "quit"
    } | bluetoothctl
    
    echo "Bluetooth configuration completed!"
}

# Function to verify configuration
verify_configuration() {
    echo "Verifying Bluetooth configuration..."
    
    local status=$(bluetoothctl show 2>/dev/null)
    
    # Debug: Show full status if DEBUG environment variable is set
    if [ "$DEBUG" = "1" ]; then
        echo "Debug: Full bluetoothctl show output:"
        echo "$status"
        echo "---"
    fi
    
    if echo "$status" | grep -qi "powered.*yes"; then
        echo "✓ Bluetooth is powered on"
    else
        echo "✗ Bluetooth is not powered on"
        echo "Debug: Powered status in output:"
        echo "$status" | grep -i powered || echo "No powered status found"
        return 1
    fi
    
    if echo "$status" | grep -qi "alias.*MyHomelab"; then
        echo "✓ Device name set to MyHomelab"
    else
        echo "✗ Device name not set correctly"
        echo "Debug: Alias status in output:"
        echo "$status" | grep -i alias || echo "No alias found"
        return 1
    fi
    
    if echo "$status" | grep -qi "discoverable.*yes"; then
        echo "✓ Bluetooth is discoverable"
    else
        echo "✗ Bluetooth is not discoverable"
        echo "Debug: Discoverable status in output:"
        echo "$status" | grep -i discoverable || echo "No discoverable status found"
        return 1
    fi
    
    if echo "$status" | grep -qi "pairable.*yes"; then
        echo "✓ Bluetooth is pairable"
    else
        echo "✗ Bluetooth is not pairable"
        echo "Debug: Pairable status in output:"
        echo "$status" | grep -i pairable || echo "No pairable status found"
        return 1
    fi
    
    echo "All Bluetooth settings configured successfully!"
    return 0
}

# Main execution
main() {
    echo "=== Bluetooth Auto-Setup Script ==="
    echo "This script will configure Bluetooth to be:"
    echo "- Powered on"
    echo "- Named 'MyHomelab'"
    echo "- Pairable for 1 minute"
    echo "- Always discoverable (no timeout)"
    echo ""
    
    # Check if running as root for service operations
    if [ "$EUID" -eq 0 ]; then
        echo "Running as root - can manage Bluetooth service"
    else
        echo "Running as user - assuming Bluetooth service is already running"
    fi
    
    # Ensure Bluetooth service is running
    check_bluetooth_service
    
    # Wait for adapter to be ready
    if ! wait_for_adapter; then
        echo "Failed to detect Bluetooth adapter. Please check:"
        echo "1. Bluetooth hardware is connected"
        echo "2. Bluetooth drivers are installed"
        echo "3. Bluetooth service is running: sudo systemctl status bluetooth"
        exit 1
    fi
    
    # Configure Bluetooth
    configure_bluetooth
    
    # Verify configuration
    sleep 2
    if verify_configuration; then
        echo ""
        echo "🎉 Bluetooth setup completed successfully!"
        echo "Your device is now discoverable and pairable."
    else
        echo ""
        echo "❌ Bluetooth setup encountered issues."
        echo "Please check the output above for details."
        exit 1
    fi
}

# Run main function
main "$@"