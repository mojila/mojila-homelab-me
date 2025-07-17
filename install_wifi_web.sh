#!/bin/bash

# Wi-Fi Configuration Web Interface Installation Script
# This script installs and configures the web interface for Wi-Fi management

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/wifi-config"
SERVICE_NAME="wifi-config-web"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check if files exist
check_files() {
    print_status "Checking required files..."
    
    local required_files=(
        "$CURRENT_DIR/wifi_config_web.py"
        "$CURRENT_DIR/wifi-config-web.service"
        "$CURRENT_DIR/requirements.txt"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file not found: $file"
            exit 1
        fi
    done
    
    print_status "All required files found"
}

# Function to install Python dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    # Update package list
    apt-get update -y
    
    # Install Python3 and pip if not already installed
    apt-get install -y python3 python3-pip python3-venv
    
    # Install system dependencies for wireless tools
    apt-get install -y wireless-tools wpasupplicant
    
    # Install Python packages
    pip3 install -r "$CURRENT_DIR/requirements.txt"
    
    print_status "Dependencies installed successfully"
}

# Function to create installation directory
create_install_directory() {
    print_status "Creating installation directory..."
    
    # Create directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"
    
    # Copy files
    cp "$CURRENT_DIR/wifi_config_web.py" "$INSTALL_DIR/"
    cp "$CURRENT_DIR/requirements.txt" "$INSTALL_DIR/"
    
    # Set permissions
    chmod +x "$INSTALL_DIR/wifi_config_web.py"
    chown -R root:root "$INSTALL_DIR"
    
    print_status "Files copied to $INSTALL_DIR"
}

# Function to install systemd service
install_systemd_service() {
    print_status "Installing systemd service..."
    
    # Copy service file
    cp "$CURRENT_DIR/wifi-config-web.service" "$SERVICE_FILE"
    
    # Set proper permissions
    chmod 644 "$SERVICE_FILE"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable "$SERVICE_NAME"
    
    print_status "Systemd service installed and enabled"
}

# Function to configure log rotation
setup_log_rotation() {
    print_status "Setting up log rotation..."
    
    cat > /etc/logrotate.d/wifi-config-web << EOF
/var/log/wifi_config.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload-or-restart wifi-config-web
    endscript
}
EOF
    
    print_status "Log rotation configured"
}

# Function to create log file
setup_logging() {
    print_status "Setting up logging..."
    
    # Create log file with proper permissions
    touch /var/log/wifi_config.log
    chmod 644 /var/log/wifi_config.log
    chown root:root /var/log/wifi_config.log
    
    print_status "Logging configured"
}

# Function to configure firewall (if ufw is installed)
configure_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        print_status "Configuring firewall..."
        
        # Allow HTTP traffic on port 80
        ufw allow 80/tcp comment "Wi-Fi Config Web Interface"
        
        print_status "Firewall configured to allow port 80"
    else
        print_warning "UFW firewall not found, skipping firewall configuration"
    fi
}

# Function to start the service
start_service() {
    print_status "Starting Wi-Fi configuration web service..."
    
    # Start the service
    systemctl start "$SERVICE_NAME"
    
    # Check if service started successfully
    sleep 3
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_status "Service started successfully"
    else
        print_error "Service failed to start. Check logs with: journalctl -u $SERVICE_NAME"
        exit 1
    fi
}

# Function to get system IP
get_system_ip() {
    # Try to get IP from wlan0 first, then eth0, then any interface
    local ip
    ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    
    if [[ -z "$ip" ]]; then
        ip=$(hostname -I | awk '{print $1}')
    fi
    
    echo "$ip"
}

# Function to print summary
print_summary() {
    local system_ip
    system_ip=$(get_system_ip)
    
    echo
    echo "======================================"
    echo "   WI-FI WEB INTERFACE INSTALLED"
    echo "======================================"
    echo
    print_status "Installation completed successfully!"
    echo
    echo "Service Information:"
    echo "  • Service Name: $SERVICE_NAME"
    echo "  • Installation Directory: $INSTALL_DIR"
    echo "  • Log File: /var/log/wifi_config.log"
    echo "  • Service File: $SERVICE_FILE"
    echo
    echo "Access Information:"
    if [[ -n "$system_ip" ]]; then
        echo "  • Web Interface: http://$system_ip/"
        echo "  • Local Access: http://localhost/"
    else
        echo "  • Web Interface: http://[YOUR_PI_IP]/"
    fi
    echo "  • Port: 80 (HTTP)"
    echo
    echo "Service Management:"
    echo "  • Start:   sudo systemctl start $SERVICE_NAME"
    echo "  • Stop:    sudo systemctl stop $SERVICE_NAME"
    echo "  • Restart: sudo systemctl restart $SERVICE_NAME"
    echo "  • Status:  sudo systemctl status $SERVICE_NAME"
    echo "  • Logs:    sudo journalctl -u $SERVICE_NAME -f"
    echo
    echo "Features:"
    echo "  • 📱 Responsive web interface"
    echo "  • 🔍 Network scanning"
    echo "  • 🔐 WPA/WPA2 and open network support"
    echo "  • 📊 Real-time connection status"
    echo "  • 🔄 Network management controls"
    echo "  • 📋 System logs viewer"
    echo
    print_warning "Note: The web interface requires root privileges to manage Wi-Fi"
    print_warning "Make sure to secure your Raspberry Pi if accessible from the internet"
    echo
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if service is running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_status "✓ Service is running"
    else
        print_error "✗ Service is not running"
        return 1
    fi
    
    # Check if service is enabled
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        print_status "✓ Service is enabled for auto-start"
    else
        print_warning "✗ Service is not enabled for auto-start"
    fi
    
    # Check if port 80 is listening
    if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
        print_status "✓ Port 80 is listening"
    else
        print_warning "✗ Port 80 is not listening (may be normal if not running as root)"
    fi
    
    # Check log file
    if [[ -f "/var/log/wifi_config.log" ]]; then
        print_status "✓ Log file exists"
    else
        print_warning "✗ Log file not found"
    fi
    
    print_status "Installation verification completed"
}

# Main execution
main() {
    echo "======================================"
    echo "  Wi-Fi Web Interface Installation"
    echo "======================================"
    echo
    
    check_root
    check_files
    install_dependencies
    create_install_directory
    install_systemd_service
    setup_logging
    setup_log_rotation
    configure_firewall
    start_service
    verify_installation
    print_summary
}

# Run main function
main "$@"