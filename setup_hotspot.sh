#!/bin/bash

# Raspberry Pi Wi-Fi Hotspot Setup Script
# This script configures a Raspberry Pi to act as a Wi-Fi hotspot
# only when no saved Wi-Fi networks are available

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
SSID="MojilaHomelab-Hotspot"
PASSWORD="mojila123"
HOTSPOT_IP="192.168.4.1"
DHCP_RANGE_START="192.168.4.2"
DHCP_RANGE_END="192.168.4.20"
INTERFACE="wlan0"

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

# Function to update package list
update_packages() {
    print_status "Updating package list..."
    apt-get update -y
}

# Function to install required packages
install_packages() {
    print_status "Installing required packages (hostapd, dnsmasq)..."
    apt-get install -y hostapd dnsmasq
    
    # Stop services initially
    systemctl stop hostapd
    systemctl stop dnsmasq
    systemctl disable hostapd
    systemctl disable dnsmasq
}

# Function to create hostapd configuration
create_hostapd_config() {
    print_status "Creating hostapd configuration..."
    
    cat > /etc/hostapd/hostapd.conf << EOF
# Interface to use
interface=wlan0

# Driver to use
driver=nl80211

# Network name
ssid=${SSID}

# Network mode (g = 2.4GHz)
hw_mode=g

# Channel to use
channel=7

# Enable WPA2
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=${PASSWORD}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

    print_status "hostapd configuration created at /etc/hostapd/hostapd.conf"
}

# Function to create dnsmasq configuration
create_dnsmasq_config() {
    print_status "Creating dnsmasq configuration..."
    
    # Backup original config
    if [[ -f /etc/dnsmasq.conf ]]; then
        cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
    fi
    
    cat > /etc/dnsmasq.conf << EOF
# Interface to bind to
interface=wlan0

# Don't bind to other interfaces
bind-interfaces

# DHCP range
dhcp-range=${DHCP_RANGE_START},${DHCP_RANGE_END},255.255.255.0,24h

# DNS servers
server=8.8.8.8
server=8.8.4.4

# Domain name
domain-needed
bogus-priv
EOF

    print_status "dnsmasq configuration created at /etc/dnsmasq.conf"
}

# Function to configure dhcpcd
configure_dhcpcd() {
    print_status "Configuring dhcpcd..."
    
    # Backup original config
    if [[ -f /etc/dhcpcd.conf ]]; then
        cp /etc/dhcpcd.conf /etc/dhcpcd.conf.backup
    fi
    
    # Add hotspot configuration to dhcpcd.conf
    cat >> /etc/dhcpcd.conf << EOF

# Hotspot configuration
# This will be used when acting as an access point
interface wlan0
nohook wpa_supplicant
static ip_address=${HOTSPOT_IP}/24
static routers=${HOTSPOT_IP}
static domain_name_servers=${HOTSPOT_IP}
EOF

    print_status "dhcpcd configuration updated"
}

# Function to update hostapd default configuration
update_hostapd_default() {
    print_status "Updating hostapd default configuration..."
    
    # Backup original file
    if [[ -f /etc/default/hostapd ]]; then
        cp /etc/default/hostapd /etc/default/hostapd.backup
    fi
    
    # Update the DAEMON_CONF line
    sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
    
    # If the line doesn't exist, add it
    if ! grep -q "DAEMON_CONF=" /etc/default/hostapd; then
        echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd
    fi
    
    print_status "hostapd default configuration updated"
}

# Function to create Wi-Fi check script
create_wifi_check_script() {
    print_status "Creating Wi-Fi monitoring script..."
    
    cat > /usr/local/bin/wifi_check.sh << 'EOF'
#!/bin/bash

# Wi-Fi Connection Monitor Script
# Checks for Wi-Fi connection and starts hotspot if not connected

LOGFILE="/var/log/wifi_check.log"
INTERFACE="wlan0"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOGFILE"
}

# Function to check if connected to Wi-Fi
check_wifi_connection() {
    # Check if wlan0 has an IP address and is connected
    if iwgetid "$INTERFACE" >/dev/null 2>&1; then
        # Double check with ping to ensure internet connectivity
        if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
            return 0  # Connected
        fi
    fi
    return 1  # Not connected
}

# Function to start hotspot
start_hotspot() {
    log_message "Starting hotspot mode"
    
    # Stop wpa_supplicant
    systemctl stop wpa_supplicant
    
    # Restart dhcpcd to apply static IP
    systemctl restart dhcpcd
    sleep 5
    
    # Start hostapd and dnsmasq
    systemctl start hostapd
    systemctl start dnsmasq
    
    log_message "Hotspot started successfully"
}

# Function to stop hotspot
stop_hotspot() {
    log_message "Stopping hotspot mode"
    
    # Stop hostapd and dnsmasq
    systemctl stop hostapd
    systemctl stop dnsmasq
    
    # Restart wpa_supplicant and dhcpcd
    systemctl start wpa_supplicant
    systemctl restart dhcpcd
    
    log_message "Hotspot stopped, returning to client mode"
}

# Main logic
if check_wifi_connection; then
    log_message "Wi-Fi connection detected"
    # If hotspot is running, stop it
    if systemctl is-active --quiet hostapd; then
        stop_hotspot
    fi
else
    log_message "No Wi-Fi connection detected"
    # If hotspot is not running, start it
    if ! systemctl is-active --quiet hostapd; then
        start_hotspot
    fi
fi
EOF

    chmod +x /usr/local/bin/wifi_check.sh
    print_status "Wi-Fi monitoring script created at /usr/local/bin/wifi_check.sh"
}

# Function to setup cron job
setup_cron_job() {
    print_status "Setting up cron job for Wi-Fi monitoring..."
    
    # Add cron job to run every minute
    (crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/wifi_check.sh") | crontab -
    
    # Also add to run at boot
    (crontab -l 2>/dev/null; echo "@reboot sleep 30 && /usr/local/bin/wifi_check.sh") | crontab -
    
    print_status "Cron job configured to run Wi-Fi check every minute"
}

# Function to enable IP forwarding (optional, for internet sharing)
enable_ip_forwarding() {
    print_status "Enabling IP forwarding..."
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    
    # Apply immediately
    sysctl -p
    
    print_status "IP forwarding enabled"
}

# Function to create log directory
setup_logging() {
    print_status "Setting up logging..."
    
    # Ensure log file exists and has proper permissions
    touch /var/log/wifi_check.log
    chmod 644 /var/log/wifi_check.log
    
    print_status "Logging configured"
}

# Function to print summary
print_summary() {
    echo
    echo "======================================"
    echo "    RASPBERRY PI HOTSPOT SETUP"
    echo "======================================"
    echo
    print_status "Setup completed successfully!"
    echo
    echo "Configuration Summary:"
    echo "  • Hotspot SSID: $SSID"
    echo "  • Hotspot Password: $PASSWORD"
    echo "  • Hotspot IP: $HOTSPOT_IP"
    echo "  • DHCP Range: $DHCP_RANGE_START - $DHCP_RANGE_END"
    echo
    echo "Files created/modified:"
    echo "  • /etc/hostapd/hostapd.conf"
    echo "  • /etc/dnsmasq.conf"
    echo "  • /etc/dhcpcd.conf"
    echo "  • /etc/default/hostapd"
    echo "  • /usr/local/bin/wifi_check.sh"
    echo
    echo "How it works:"
    echo "  • The system will automatically check for Wi-Fi connections every minute"
    echo "  • If no saved Wi-Fi networks are available, it will start the hotspot"
    echo "  • If a Wi-Fi connection is established, it will stop the hotspot"
    echo "  • Logs are written to /var/log/wifi_check.log"
    echo
    print_warning "IMPORTANT: You may want to configure your Wi-Fi networks in /etc/wpa_supplicant/wpa_supplicant.conf"
    echo
    echo "To manually control the hotspot:"
    echo "  • Start: sudo systemctl start hostapd && sudo systemctl start dnsmasq"
    echo "  • Stop: sudo systemctl stop hostapd && sudo systemctl stop dnsmasq"
    echo
    read -p "Would you like to reboot now to apply all changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Rebooting in 5 seconds..."
        sleep 5
        reboot
    else
        print_status "Please reboot manually to ensure all changes take effect."
    fi
}

# Main execution
main() {
    echo "======================================"
    echo "  Raspberry Pi Wi-Fi Hotspot Setup"
    echo "======================================"
    echo
    
    check_root
    update_packages
    install_packages
    create_hostapd_config
    create_dnsmasq_config
    configure_dhcpcd
    update_hostapd_default
    create_wifi_check_script
    setup_cron_job
    enable_ip_forwarding
    setup_logging
    print_summary
}

# Run main function
main "$@"