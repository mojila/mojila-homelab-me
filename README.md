# Bluetooth Auto-Setup for Ubuntu on Orange Pi

This repository contains scripts and configuration files to automatically enable Bluetooth discoverability on Ubuntu running on Orange Pi (or similar Single Board Computers) using the BlueZ Bluetooth stack.

## Quick Start

### Automatic Installation (Recommended)

1. Make the installation script executable:
   ```bash
   chmod +x install-bluetooth-setup.sh
   ```

2. Run the installer with sudo:
   ```bash
   sudo ./install-bluetooth-setup.sh
   ```

3. Reboot to test automatic startup:
   ```bash
   sudo reboot
   ```

**Note**: The installer is repeatable - you can run it multiple times to update the configuration. Use `sudo ./install-bluetooth-setup.sh --update` to explicitly update an existing installation.

### Manual Installation

If you prefer to install manually, follow the detailed guide in `bluetooth-setup-guide.md`.

## Files Included

- **`bluetooth-setup-guide.md`** - Comprehensive guide with all commands and explanations
- **`bluetooth-setup.sh`** - Main script that configures Bluetooth settings
- **`bluetooth-auto-setup.service`** - Systemd service file for automatic startup
- **`install-bluetooth-setup.sh`** - Automated installer script
- **`README.md`** - This file

## What This Does

After installation, your Orange Pi will automatically:
- Power on Bluetooth at boot
- Set the device name to "MyHomelab"
- Make the device pairable
- Make the device discoverable
- Set up a default Bluetooth agent

## Manual Commands

If you want to run the setup manually without installing the service:

```bash
# Make script executable
chmod +x bluetooth-setup.sh

# Run the setup
./bluetooth-setup.sh
```

## Quick Commands for Manual Setup:

```bash
# One-liner for immediate setup
echo -e 'power on\nsystem-alias MyHomelab\npairable on\ndiscoverable on\ndiscoverable-timeout 0\nagent on\ndefault-agent\nexit' | bluetoothctl

# Enable Bluetooth service at boot
sudo systemctl enable bluetooth
```

## Verification

Check if Bluetooth is properly configured:

```bash
# Check Bluetooth status
bluetoothctl show

# Check service status
sudo systemctl status bluetooth-auto-setup

# View service logs
sudo journalctl -u bluetooth-auto-setup -f
```

## Troubleshooting

### Service Not Starting

```bash
# Check service status
sudo systemctl status bluetooth-auto-setup

# View detailed logs
sudo journalctl -u bluetooth-auto-setup -n 50

# Restart the service
sudo systemctl restart bluetooth-auto-setup
```

### Bluetooth Not Working

```bash
# Check if Bluetooth hardware is detected
lsusb | grep -i bluetooth
dmesg | grep -i bluetooth

# Restart Bluetooth service
sudo systemctl restart bluetooth

# Check Bluetooth service logs
sudo journalctl -u bluetooth -f
```

### Script Verification Issues

```bash
# Run script with debug mode to see detailed output
DEBUG=1 ./bluetooth-setup.sh

# Check bluetoothctl output format manually
bluetoothctl show
```

### Reset Bluetooth Configuration

```bash
# Stop services
sudo systemctl stop bluetooth-auto-setup
sudo systemctl stop bluetooth

# Clear Bluetooth data
sudo rm -rf /var/lib/bluetooth/*

# Restart services
sudo systemctl start bluetooth
sudo systemctl start bluetooth-auto-setup
```

## Uninstallation

To remove the auto-setup:

```bash
sudo ./install-bluetooth-setup.sh --uninstall
```

Or manually:

```bash
# Stop and disable service
sudo systemctl stop bluetooth-auto-setup
sudo systemctl disable bluetooth-auto-setup

# Remove files
sudo rm /etc/systemd/system/bluetooth-auto-setup.service
sudo rm /usr/local/bin/bluetooth-setup.sh

# Reload systemd
sudo systemctl daemon-reload
```

## Security Considerations

⚠️ **Important**: Making your device discoverable means it will be visible to all nearby Bluetooth devices. Consider:

- Using this only in trusted environments
- Setting up proper PIN codes for pairing
- Regularly reviewing paired devices
- Consider modifying the script to set a discoverable timeout

## Requirements

- Ubuntu (tested on Orange Pi)
- BlueZ Bluetooth stack
- systemd
- Bluetooth hardware support

## Installation Requirements

If BlueZ is not installed:

```bash
sudo apt update
sudo apt install bluez
```

## Compatibility

This setup has been tested on:
- Orange Pi running Ubuntu
- Raspberry Pi running Ubuntu
- Other ARM-based SBCs with Ubuntu

Should work on any Linux system using BlueZ and systemd.

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review the detailed guide in `bluetooth-setup-guide.md`
3. Check system logs for Bluetooth-related errors
4. Ensure your hardware supports Bluetooth

## License

Free to use and modify for personal and commercial purposes.