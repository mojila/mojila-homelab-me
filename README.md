# Raspberry Pi Wi-Fi Management Suite

A comprehensive solution for managing Wi-Fi connections on Raspberry Pi, featuring automatic hotspot fallback and a web-based configuration interface.

## 🚀 Features

### Hotspot Setup Script (`setup_hotspot.sh`)
- **Automatic Wi-Fi Fallback**: Creates a hotspot when no saved Wi-Fi networks are available
- **Complete Package Installation**: Installs and configures `hostapd` and `dnsmasq`
- **Intelligent Monitoring**: Checks Wi-Fi connectivity every minute
- **Seamless Switching**: Automatically switches between client and hotspot modes
- **Comprehensive Logging**: Detailed logs for troubleshooting

### Web Configuration Interface (`wifi_config_web.py`)
- **📱 Responsive Web UI**: Modern, mobile-friendly interface
- **🔍 Network Scanning**: Discover available Wi-Fi networks
- **🔐 Security Support**: WPA/WPA2, WEP, and open networks
- **📊 Real-time Status**: Live connection monitoring
- **🔄 Network Management**: Connect, disconnect, and restart networking
- **📋 System Logs**: Built-in log viewer
- **⚙️ Systemd Integration**: Runs as a system service

## 📋 Requirements

- Raspberry Pi with Raspberry Pi OS
- Wi-Fi adapter (built-in or USB)
- Root/sudo access
- Internet connection for initial setup

## 🛠️ Installation

### Quick Start

1. **Clone or download the files to your Raspberry Pi**
2. **Install the hotspot functionality:**
   ```bash
   sudo ./setup_hotspot.sh
   ```
3. **Install the web interface:**
   ```bash
   sudo ./install_wifi_web.sh
   ```

### Manual Installation

#### Hotspot Setup
```bash
# Make script executable
chmod +x setup_hotspot.sh

# Run installation
sudo ./setup_hotspot.sh
```

#### Web Interface Setup
```bash
# Make script executable
chmod +x install_wifi_web.sh

# Run installation
sudo ./install_wifi_web.sh
```

## 🔧 Configuration

### Hotspot Configuration

Edit the variables in `setup_hotspot.sh` before running:

```bash
SSID="RaspberryPi-Hotspot"        # Hotspot network name
PASSWORD="raspberry123"           # Hotspot password
HOTSPOT_IP="192.168.4.1"         # Hotspot IP address
DHCP_RANGE_START="192.168.4.2"   # DHCP range start
DHCP_RANGE_END="192.168.4.20"    # DHCP range end
```

### Web Interface Configuration

The web interface runs on port 80 by default. Key configuration:

- **Installation Directory**: `/opt/wifi-config/`
- **Log File**: `/var/log/wifi_config.log`
- **Service Name**: `wifi-config-web`
- **Default Port**: 80 (falls back to 8080 if not root)

## 🌐 Usage

### Accessing the Web Interface

1. **Find your Raspberry Pi's IP address:**
   ```bash
   hostname -I
   ```

2. **Open in web browser:**
   ```
   http://[YOUR_PI_IP]/
   ```
   or
   ```
   http://raspberrypi.local/
   ```

### Web Interface Features

#### 📡 Connection Status
- View current Wi-Fi connection
- See IP address and signal strength
- Real-time status updates

#### 🔍 Network Scanning
- Click "Scan Networks" to discover available Wi-Fi
- View signal strength and security type
- One-click connection to networks

#### 🔐 Manual Connection
- Enter SSID and password manually
- Support for WPA/WPA2, WEP, and open networks
- Automatic configuration of wpa_supplicant

#### ⚙️ System Controls
- Restart networking services
- Disconnect from current network
- View system logs

### Hotspot Behavior

The system automatically:
1. **Checks for Wi-Fi connection every minute**
2. **Starts hotspot if no connection is available**
3. **Stops hotspot when Wi-Fi connection is restored**
4. **Logs all activities to `/var/log/wifi_check.log`**

## 📁 File Structure

```
.
├── setup_hotspot.sh           # Main hotspot setup script
├── wifi_config_web.py          # Web interface application
├── install_wifi_web.sh         # Web interface installer
├── wifi-config-web.service     # Systemd service file
├── requirements.txt            # Python dependencies
└── README.md                   # This documentation
```

### Generated Files

After installation, these files are created/modified:

#### Hotspot Files
- `/etc/hostapd/hostapd.conf` - Hotspot configuration
- `/etc/dnsmasq.conf` - DHCP server configuration
- `/etc/dhcpcd.conf` - Network interface configuration
- `/etc/default/hostapd` - Hostapd daemon configuration
- `/usr/local/bin/wifi_check.sh` - Wi-Fi monitoring script
- `/var/log/wifi_check.log` - Hotspot activity logs

#### Web Interface Files
- `/opt/wifi-config/wifi_config_web.py` - Main application
- `/etc/systemd/system/wifi-config-web.service` - Service definition
- `/var/log/wifi_config.log` - Web interface logs
- `/etc/logrotate.d/wifi-config-web` - Log rotation configuration

## 🔧 Service Management

### Web Interface Service

```bash
# Start service
sudo systemctl start wifi-config-web

# Stop service
sudo systemctl stop wifi-config-web

# Restart service
sudo systemctl restart wifi-config-web

# Check status
sudo systemctl status wifi-config-web

# View logs
sudo journalctl -u wifi-config-web -f

# Enable auto-start
sudo systemctl enable wifi-config-web

# Disable auto-start
sudo systemctl disable wifi-config-web
```

### Hotspot Services

```bash
# Manual hotspot control
sudo systemctl start hostapd
sudo systemctl start dnsmasq

# Stop hotspot
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Check Wi-Fi monitoring
sudo /usr/local/bin/wifi_check.sh
```

## 🔍 Troubleshooting

### Common Issues

#### Web Interface Not Accessible
1. **Check if service is running:**
   ```bash
   sudo systemctl status wifi-config-web
   ```

2. **Check logs:**
   ```bash
   sudo journalctl -u wifi-config-web -n 50
   ```

3. **Verify port 80 is available:**
   ```bash
   sudo netstat -tlnp | grep :80
   ```

#### Hotspot Not Starting
1. **Check Wi-Fi monitoring logs:**
   ```bash
   sudo tail -f /var/log/wifi_check.log
   ```

2. **Manually test hotspot:**
   ```bash
   sudo systemctl stop wpa_supplicant
   sudo systemctl start hostapd
   sudo systemctl start dnsmasq
   ```

3. **Check hostapd configuration:**
   ```bash
   sudo hostapd -d /etc/hostapd/hostapd.conf
   ```

#### Wi-Fi Connection Issues
1. **Check wpa_supplicant configuration:**
   ```bash
   sudo cat /etc/wpa_supplicant/wpa_supplicant.conf
   ```

2. **Test manual connection:**
   ```bash
   sudo wpa_cli reconfigure
   sudo dhclient wlan0
   ```

3. **Check interface status:**
   ```bash
   iwconfig wlan0
   ip addr show wlan0
   ```

### Log Files

- **Web Interface**: `/var/log/wifi_config.log`
- **Hotspot Monitoring**: `/var/log/wifi_check.log`
- **System Logs**: `sudo journalctl -u wifi-config-web`
- **Network Logs**: `sudo journalctl -u wpa_supplicant`

## 🔒 Security Considerations

### Web Interface Security
- **Root Privileges**: Required for Wi-Fi management
- **Network Access**: Accessible from local network
- **No Authentication**: Consider adding authentication for production use
- **Firewall**: Configure firewall rules as needed

### Hotspot Security
- **Default Password**: Change the default hotspot password
- **WPA2 Encryption**: Uses WPA2 for security
- **Network Isolation**: Hotspot clients are isolated by default

### Recommendations
1. **Change default passwords**
2. **Use strong Wi-Fi passwords**
3. **Limit network access if needed**
4. **Regular security updates**
5. **Monitor logs for suspicious activity**

## 🤝 Contributing

Contributions are welcome! Please consider:

1. **Bug Reports**: Use detailed descriptions and logs
2. **Feature Requests**: Explain use cases and benefits
3. **Code Contributions**: Follow existing code style
4. **Documentation**: Help improve documentation

## 📄 License

This project is provided as-is for educational and personal use. Please ensure compliance with local regulations regarding Wi-Fi hotspots and network management.

## 🆘 Support

For support:
1. **Check this README** for common solutions
2. **Review log files** for error messages
3. **Test individual components** to isolate issues
4. **Check Raspberry Pi forums** for similar issues

---

**Happy networking! 🎉**