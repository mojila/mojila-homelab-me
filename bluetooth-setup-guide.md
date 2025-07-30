# Bluetooth Setup Guide for Ubuntu on Orange Pi

This guide provides instructions for enabling Bluetooth discoverability on Ubuntu using BlueZ stack.

## Quick Commands for Manual Setup

### Basic Bluetooth Control Commands

```bash
# Start Bluetooth service
sudo systemctl start bluetooth

# Enable Bluetooth service at boot
sudo systemctl enable bluetooth

# Check Bluetooth service status
sudo systemctl status bluetooth
```

### Manual bluetoothctl Commands

```bash
# Enter bluetoothctl interactive mode
bluetoothctl

# Within bluetoothctl:
power on
pairable on
discoverable on
agent on
default-agent
exit
```

### One-liner Command (Non-interactive)

```bash
# Execute all commands in sequence
echo -e 'power on\npairable on\ndiscoverable on\nagent on\ndefault-agent\nexit' | bluetoothctl
```

## Making Settings Persistent

### Method 1: Modify BlueZ Configuration

Edit the main BlueZ configuration file:

```bash
sudo nano /etc/bluetooth/main.conf
```

Add or modify these settings:

```ini
[General]
# Enable discoverability by default
DiscoverableTimeout = 0

# Enable pairing by default
PairableTimeout = 0

# Auto-enable controller
AutoEnable = true

[Policy]
# Auto-enable profiles
AutoEnable = true
```

### Method 2: Create a Startup Script

Create a script that runs at boot:

```bash
sudo nano /usr/local/bin/bluetooth-setup.sh
```

Add the following content:

```bash
#!/bin/bash

# Wait for Bluetooth service to be ready
sleep 5

# Configure Bluetooth settings
echo 'power on' | bluetoothctl
sleep 2
echo 'pairable on' | bluetoothctl
sleep 1
echo 'discoverable on' | bluetoothctl
sleep 1
echo 'agent on' | bluetoothctl
sleep 1
echo 'default-agent' | bluetoothctl

echo "Bluetooth configured: powered on, pairable, and discoverable"
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/bluetooth-setup.sh
```

## Creating a Systemd Service

### Create the Service File

```bash
sudo nano /etc/systemd/system/bluetooth-auto-setup.service
```

Add the following content:

```ini
[Unit]
Description=Bluetooth Auto Setup Service
After=bluetooth.service
Wants=bluetooth.service
Requires=bluetooth.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/bluetooth-setup.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
```

### Enable and Start the Service

```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Enable the service to start at boot
sudo systemctl enable bluetooth-auto-setup.service

# Start the service immediately (optional)
sudo systemctl start bluetooth-auto-setup.service

# Check service status
sudo systemctl status bluetooth-auto-setup.service
```

## Alternative: Using udev Rules

Create a udev rule for automatic setup:

```bash
sudo nano /etc/udev/rules.d/99-bluetooth-auto.rules
```

Add:

```
ACTION=="add", KERNEL=="hci0", RUN+="/usr/local/bin/bluetooth-setup.sh"
```

Reload udev rules:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Verification Commands

```bash
# Check if Bluetooth is powered on
bluetoothctl show

# List available controllers
bluetoothctl list

# Check discoverable status
bluetoothctl show | grep Discoverable

# Check pairable status
bluetoothctl show | grep Pairable

# Scan for nearby devices (to test functionality)
bluetoothctl scan on
```

## Troubleshooting

### Common Issues and Solutions

1. **Bluetooth service not starting:**
   ```bash
   sudo systemctl restart bluetooth
   sudo journalctl -u bluetooth -f
   ```

2. **No Bluetooth adapter found:**
   ```bash
   lsusb | grep -i bluetooth
   dmesg | grep -i bluetooth
   ```

3. **Permissions issues:**
   ```bash
   sudo usermod -a -G bluetooth $USER
   # Logout and login again
   ```

4. **Reset Bluetooth completely:**
   ```bash
   sudo systemctl stop bluetooth
   sudo rm -rf /var/lib/bluetooth/*
   sudo systemctl start bluetooth
   ```

### Check Logs

```bash
# View Bluetooth service logs
sudo journalctl -u bluetooth -f

# View our custom service logs
sudo journalctl -u bluetooth-auto-setup -f

# View system logs for Bluetooth
dmesg | grep -i bluetooth
```

## Security Considerations

- **Discoverable mode** makes your device visible to all nearby Bluetooth devices
- Consider setting a **DiscoverableTimeout** in `/etc/bluetooth/main.conf` for security
- Use strong PIN codes for pairing
- Regularly review paired devices: `bluetoothctl paired-devices`

## Summary

After following this guide:
1. Your Orange Pi will automatically power on Bluetooth at boot
2. The device will be pairable and discoverable
3. Settings will persist across reboots
4. You can monitor the service status using systemctl commands

The systemd service approach is recommended as it provides better integration with the system and proper dependency management.