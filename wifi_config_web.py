#!/usr/bin/env python3
"""
Wi-Fi Configuration Web Interface
A Flask-based web application for configuring Wi-Fi connections on Raspberry Pi
Runs on port 80 and can be managed by systemd
"""

import os
import subprocess
import json
import re
from flask import Flask, render_template_string, request, jsonify, redirect, url_for
import logging
from datetime import datetime
import sys
from pathlib import Path

# Get the directory where the script is located
SCRIPT_DIR = Path(__file__).parent.absolute()
LOG_DIR = SCRIPT_DIR / 'logs'

# Create logs directory if it doesn't exist
LOG_DIR.mkdir(exist_ok=True)

# Configure logging with fallback for different platforms
log_file = LOG_DIR / 'wifi_config.log'
try:
    # Try to use the local log file first
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(str(log_file)),
            logging.StreamHandler()
        ]
    )
except PermissionError:
    # Fallback to console only if file logging fails
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[logging.StreamHandler()]
    )
    print(f"Warning: Could not create log file at {log_file}. Logging to console only.")

app = Flask(__name__)
app.secret_key = 'raspberry_pi_wifi_config_2024'

# HTML Template
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Raspberry Pi Wi-Fi Configuration</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #4CAF50, #45a049);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header p {
            opacity: 0.9;
            font-size: 1.1em;
        }
        
        .content {
            padding: 30px;
        }
        
        .status-card {
            background: #f8f9fa;
            border-left: 4px solid #4CAF50;
            padding: 20px;
            margin-bottom: 30px;
            border-radius: 5px;
        }
        
        .status-card.disconnected {
            border-left-color: #f44336;
        }
        
        .status-card h3 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .wifi-form {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }
        
        input, select {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        
        input:focus, select:focus {
            outline: none;
            border-color: #4CAF50;
        }
        
        .btn {
            background: linear-gradient(135deg, #4CAF50, #45a049);
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 600;
            transition: transform 0.2s, box-shadow 0.2s;
            margin-right: 10px;
            margin-bottom: 10px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(76, 175, 80, 0.3);
        }
        
        .btn-secondary {
            background: linear-gradient(135deg, #6c757d, #5a6268);
        }
        
        .btn-danger {
            background: linear-gradient(135deg, #dc3545, #c82333);
        }
        
        .networks-list {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        
        .network-item {
            background: white;
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 8px;
            border: 1px solid #e9ecef;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: box-shadow 0.2s;
        }
        
        .network-item:hover {
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .network-info {
            flex-grow: 1;
        }
        
        .network-name {
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
        }
        
        .network-details {
            color: #666;
            font-size: 0.9em;
        }
        
        .signal-strength {
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 0.8em;
            font-weight: 600;
            margin-left: 10px;
        }
        
        .signal-excellent { background: #d4edda; color: #155724; }
        .signal-good { background: #fff3cd; color: #856404; }
        .signal-fair { background: #f8d7da; color: #721c24; }
        
        .loading {
            text-align: center;
            padding: 20px;
            color: #666;
        }
        
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 8px;
        }
        
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .logs {
            background: #2d3748;
            color: #e2e8f0;
            padding: 20px;
            border-radius: 10px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            max-height: 300px;
            overflow-y: auto;
            white-space: pre-wrap;
        }
        
        @media (max-width: 768px) {
            .container {
                margin: 10px;
                border-radius: 10px;
            }
            
            .header {
                padding: 20px;
            }
            
            .header h1 {
                font-size: 2em;
            }
            
            .content {
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 Wi-Fi Configuration</h1>
            <p>Raspberry Pi Network Manager</p>
        </div>
        
        <div class="content">
            <!-- Status Section -->
            <div class="status-card {{ 'disconnected' if not current_connection else '' }}">
                <h3>📡 Current Status</h3>
                {% if current_connection %}
                    <p><strong>Connected to:</strong> {{ current_connection.ssid }}</p>
                    <p><strong>IP Address:</strong> {{ current_connection.ip }}</p>
                    <p><strong>Signal:</strong> {{ current_connection.signal }}%</p>
                {% else %}
                    <p><strong>Status:</strong> Not connected to any Wi-Fi network</p>
                {% endif %}
                <p><strong>Last updated:</strong> {{ current_time }}</p>
            </div>
            
            <!-- Manual Connection Form -->
            <div class="wifi-form">
                <h3>🔐 Connect to Wi-Fi Network</h3>
                <form method="POST" action="/connect">
                    <div class="form-group">
                        <label for="ssid">Network Name (SSID):</label>
                        <input type="text" id="ssid" name="ssid" required placeholder="Enter network name">
                    </div>
                    
                    <div class="form-group">
                        <label for="password">Password:</label>
                        <input type="password" id="password" name="password" placeholder="Enter password (leave blank for open networks)">
                    </div>
                    
                    <div class="form-group">
                        <label for="security">Security Type:</label>
                        <select id="security" name="security">
                            <option value="WPA">WPA/WPA2</option>
                            <option value="WEP">WEP</option>
                            <option value="NONE">Open (No Security)</option>
                        </select>
                    </div>
                    
                    <button type="submit" class="btn">🔗 Connect</button>
                </form>
            </div>
            
            <!-- Available Networks -->
            <div class="networks-list">
                <h3>📶 Available Networks</h3>
                <button onclick="scanNetworks()" class="btn btn-secondary">🔄 Scan Networks</button>
                <div id="networks-container">
                    <div class="loading">Click "Scan Networks" to discover available Wi-Fi networks...</div>
                </div>
            </div>
            
            <!-- System Controls -->
            <div class="wifi-form">
                <h3>⚙️ System Controls</h3>
                <button onclick="restartNetworking()" class="btn btn-secondary">🔄 Restart Networking</button>
                <button onclick="disconnectWifi()" class="btn btn-danger">❌ Disconnect Wi-Fi</button>
                <button onclick="showLogs()" class="btn btn-secondary">📋 View Logs</button>
            </div>
            
            <!-- Logs Section -->
            <div id="logs-section" style="display: none;">
                <h3>📋 System Logs</h3>
                <div id="logs-content" class="logs"></div>
            </div>
        </div>
    </div>
    
    <script>
        function scanNetworks() {
            const container = document.getElementById('networks-container');
            container.innerHTML = '<div class="loading">🔍 Scanning for networks...</div>';
            
            fetch('/scan')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        displayNetworks(data.networks);
                    } else {
                        container.innerHTML = '<div class="alert alert-error">❌ Failed to scan networks: ' + data.error + '</div>';
                    }
                })
                .catch(error => {
                    container.innerHTML = '<div class="alert alert-error">❌ Error: ' + error.message + '</div>';
                });
        }
        
        function displayNetworks(networks) {
            const container = document.getElementById('networks-container');
            
            if (networks.length === 0) {
                container.innerHTML = '<div class="alert alert-error">No networks found</div>';
                return;
            }
            
            let html = '';
            networks.forEach(network => {
                const signalClass = getSignalClass(network.signal);
                html += `
                    <div class="network-item">
                        <div class="network-info">
                            <div class="network-name">${network.ssid}</div>
                            <div class="network-details">
                                Security: ${network.security} | Channel: ${network.channel}
                            </div>
                        </div>
                        <div>
                            <span class="signal-strength ${signalClass}">${network.signal}%</span>
                            <button onclick="connectToNetwork('${network.ssid}', '${network.security}')" class="btn">Connect</button>
                        </div>
                    </div>
                `;
            });
            
            container.innerHTML = html;
        }
        
        function getSignalClass(signal) {
            if (signal >= 70) return 'signal-excellent';
            if (signal >= 50) return 'signal-good';
            return 'signal-fair';
        }
        
        function connectToNetwork(ssid, security) {
            const password = prompt(`Enter password for "${ssid}" (leave blank for open networks):`);
            if (password === null) return; // User cancelled
            
            const formData = new FormData();
            formData.append('ssid', ssid);
            formData.append('password', password);
            formData.append('security', security);
            
            fetch('/connect', {
                method: 'POST',
                body: formData
            })
            .then(response => response.text())
            .then(data => {
                alert('Connection attempt initiated. Please wait and refresh the page to see the status.');
                setTimeout(() => location.reload(), 3000);
            })
            .catch(error => {
                alert('Error: ' + error.message);
            });
        }
        
        function restartNetworking() {
            if (confirm('Are you sure you want to restart networking? This may temporarily disconnect you.')) {
                fetch('/restart_networking', { method: 'POST' })
                    .then(response => response.json())
                    .then(data => {
                        alert(data.message);
                        setTimeout(() => location.reload(), 5000);
                    });
            }
        }
        
        function disconnectWifi() {
            if (confirm('Are you sure you want to disconnect from Wi-Fi?')) {
                fetch('/disconnect', { method: 'POST' })
                    .then(response => response.json())
                    .then(data => {
                        alert(data.message);
                        setTimeout(() => location.reload(), 2000);
                    });
            }
        }
        
        function showLogs() {
            const logsSection = document.getElementById('logs-section');
            const logsContent = document.getElementById('logs-content');
            
            if (logsSection.style.display === 'none') {
                logsSection.style.display = 'block';
                logsContent.innerHTML = 'Loading logs...';
                
                fetch('/logs')
                    .then(response => response.json())
                    .then(data => {
                        logsContent.innerHTML = data.logs;
                    })
                    .catch(error => {
                        logsContent.innerHTML = 'Error loading logs: ' + error.message;
                    });
            } else {
                logsSection.style.display = 'none';
            }
        }
        
        // Auto-refresh status every 30 seconds
        setInterval(() => {
            location.reload();
        }, 30000);
    </script>
</body>
</html>
"""

class WiFiManager:
    """Handles Wi-Fi operations on Raspberry Pi and other platforms"""
    
    def __init__(self):
        # Platform-specific configuration
        self.is_raspberry_pi = self._detect_raspberry_pi()
        self.is_macos = sys.platform == 'darwin'
        
        if self.is_raspberry_pi:
            self.wpa_supplicant_conf = '/etc/wpa_supplicant/wpa_supplicant.conf'
            self.interface = 'wlan0'
        elif self.is_macos:
            # macOS doesn't use wpa_supplicant in the same way
            self.wpa_supplicant_conf = None
            self.interface = self._get_wifi_interface_macos()
        else:
            # Generic Linux
            self.wpa_supplicant_conf = '/etc/wpa_supplicant/wpa_supplicant.conf'
            self.interface = 'wlan0'
    
    def _detect_raspberry_pi(self):
        """Detect if running on Raspberry Pi"""
        try:
            with open('/proc/cpuinfo', 'r') as f:
                return 'BCM' in f.read() or 'Raspberry Pi' in f.read()
        except FileNotFoundError:
            return False
    
    def _get_wifi_interface_macos(self):
        """Get Wi-Fi interface name on macOS"""
        try:
            result = subprocess.run(['networksetup', '-listallhardwareports'], 
                                  capture_output=True, text=True, timeout=10)
            lines = result.stdout.split('\n')
            for i, line in enumerate(lines):
                if 'Wi-Fi' in line and i + 1 < len(lines):
                    device_line = lines[i + 1]
                    if 'Device:' in device_line:
                        return device_line.split('Device: ')[1].strip()
            return 'en0'  # Default fallback
        except Exception:
            return 'en0'  # Default fallback
    
    def get_current_connection(self):
        """Get current Wi-Fi connection status"""
        try:
            if self.is_macos:
                return self._get_current_connection_macos()
            else:
                return self._get_current_connection_linux()
        except Exception as e:
            logging.error(f"Error getting current connection: {e}")
            return None
    
    def _get_current_connection_macos(self):
        """Get current Wi-Fi connection on macOS"""
        try:
            # Get SSID on macOS
            result = subprocess.run(['/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport', '-I'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                return None
            
            ssid = None
            signal_percent = 0
            
            for line in result.stdout.split('\n'):
                if 'SSID:' in line:
                    ssid = line.split('SSID: ')[1].strip()
                elif 'agrCtlRSSI:' in line:
                    try:
                        rssi = int(line.split('agrCtlRSSI: ')[1].strip())
                        # Convert RSSI to percentage (rough approximation)
                        signal_percent = max(0, min(100, 2 * (rssi + 100)))
                    except (ValueError, IndexError):
                        signal_percent = 0
            
            if not ssid:
                return None
            
            # Get IP address on macOS
            ip_result = subprocess.run(['ifconfig', self.interface], 
                                     capture_output=True, text=True, timeout=10)
            ip_match = re.search(r'inet (\d+\.\d+\.\d+\.\d+)', ip_result.stdout)
            ip = ip_match.group(1) if ip_match else 'Unknown'
            
            return {
                'ssid': ssid,
                'ip': ip,
                'signal': signal_percent
            }
        except Exception as e:
            logging.error(f"Error getting macOS connection info: {e}")
            return None
    
    def _get_current_connection_linux(self):
        """Get current Wi-Fi connection on Linux"""
        try:
            # Get SSID
            result = subprocess.run(['iwgetid', self.interface, '--raw'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode != 0 or not result.stdout.strip():
                return None
            
            ssid = result.stdout.strip()
            
            # Get IP address
            ip_result = subprocess.run(['ip', 'addr', 'show', self.interface], 
                                     capture_output=True, text=True, timeout=10)
            ip_match = re.search(r'inet (\d+\.\d+\.\d+\.\d+)', ip_result.stdout)
            ip = ip_match.group(1) if ip_match else 'Unknown'
            
            # Get signal strength
            signal_result = subprocess.run(['iwconfig', self.interface], 
                                         capture_output=True, text=True, timeout=10)
            signal_match = re.search(r'Signal level=(-?\d+)', signal_result.stdout)
            if signal_match:
                signal_dbm = int(signal_match.group(1))
                # Convert dBm to percentage (rough approximation)
                signal_percent = max(0, min(100, 2 * (signal_dbm + 100)))
            else:
                signal_percent = 0
            
            return {
                'ssid': ssid,
                'ip': ip,
                'signal': signal_percent
            }
        except Exception as e:
            logging.error(f"Error getting Linux connection info: {e}")
            return None
    
    def scan_networks(self):
        """Scan for available Wi-Fi networks"""
        try:
            if self.is_macos:
                return self._scan_networks_macos()
            else:
                return self._scan_networks_linux()
        except Exception as e:
            logging.error(f"Error scanning networks: {e}")
            return []
    
    def _scan_networks_macos(self):
        """Scan for Wi-Fi networks on macOS"""
        try:
            # Use airport utility to scan on macOS
            result = subprocess.run(['/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport', '-s'], 
                                  capture_output=True, text=True, timeout=15)
            
            if result.returncode != 0:
                # Fallback to networksetup if airport fails
                logging.warning("Airport scan failed, trying networksetup")
                return self._scan_networks_macos_fallback()
            
            networks = []
            lines = result.stdout.split('\n')[1:]  # Skip header
            
            for line in lines:
                if not line.strip():
                    continue
                
                # Parse airport output format
                parts = line.split()
                if len(parts) >= 6:
                    ssid = parts[0]
                    if ssid == '':
                        continue
                    
                    try:
                        # Signal strength is typically in the 3rd or 4th column
                        signal_dbm = int(parts[2])
                        signal_percent = max(0, min(100, 2 * (signal_dbm + 100)))
                    except (ValueError, IndexError):
                        signal_percent = 50  # Default
                    
                    # Security info is usually in the last columns
                    security = 'Open'
                    if 'WPA' in line or 'WEP' in line:
                        security = 'WPA/WPA2'
                    
                    networks.append({
                        'ssid': ssid,
                        'signal': signal_percent,
                        'security': security,
                        'channel': 'Unknown'
                    })
            
            # Remove duplicates and sort by signal strength
            unique_networks = {}
            for network in networks:
                ssid = network.get('ssid', '')
                if ssid and ssid not in unique_networks:
                    unique_networks[ssid] = network
            
            return sorted(unique_networks.values(), 
                        key=lambda x: x.get('signal', 0), reverse=True)
        
        except Exception as e:
            logging.error(f"Error scanning networks on macOS: {e}")
            return []
    
    def _scan_networks_macos_fallback(self):
        """Fallback network scanning for macOS"""
        try:
            # This is a simplified fallback that just shows a demo network
            logging.warning("Using fallback network scanning for macOS")
            return [{
                'ssid': 'Demo-Network',
                'signal': 75,
                'security': 'WPA/WPA2',
                'channel': '6'
            }]
        except Exception as e:
            logging.error(f"Error in macOS fallback scan: {e}")
            return []
    
    def _scan_networks_linux(self):
        """Scan for Wi-Fi networks on Linux"""
        try:
            # Trigger scan
            subprocess.run(['sudo', 'iwlist', self.interface, 'scan'], 
                         capture_output=True, timeout=15)
            
            # Get scan results
            result = subprocess.run(['sudo', 'iwlist', self.interface, 'scan'], 
                                  capture_output=True, text=True, timeout=15)
            
            if result.returncode != 0:
                return []
            
            networks = []
            current_network = {}
            
            for line in result.stdout.split('\n'):
                line = line.strip()
                
                if 'Cell' in line and 'Address:' in line:
                    if current_network.get('ssid'):
                        networks.append(current_network)
                    current_network = {}
                
                elif 'ESSID:' in line:
                    ssid_match = re.search(r'ESSID:"(.+?)"', line)
                    if ssid_match:
                        current_network['ssid'] = ssid_match.group(1)
                
                elif 'Signal level=' in line:
                    signal_match = re.search(r'Signal level=(-?\d+)', line)
                    if signal_match:
                        signal_dbm = int(signal_match.group(1))
                        current_network['signal'] = max(0, min(100, 2 * (signal_dbm + 100)))
                
                elif 'Channel:' in line:
                    channel_match = re.search(r'Channel:(\d+)', line)
                    if channel_match:
                        current_network['channel'] = channel_match.group(1)
                
                elif 'Encryption key:' in line:
                    if 'off' in line:
                        current_network['security'] = 'Open'
                    else:
                        current_network['security'] = 'WPA/WPA2'
            
            # Add the last network
            if current_network.get('ssid'):
                networks.append(current_network)
            
            # Remove duplicates and sort by signal strength
            unique_networks = {}
            for network in networks:
                ssid = network.get('ssid', '')
                if ssid and ssid not in unique_networks:
                    unique_networks[ssid] = network
            
            return sorted(unique_networks.values(), 
                        key=lambda x: x.get('signal', 0), reverse=True)
        
        except Exception as e:
            logging.error(f"Error scanning networks on Linux: {e}")
            return []
    
    def connect_to_network(self, ssid, password, security='WPA'):
        """Connect to a Wi-Fi network"""
        try:
            if self.is_macos:
                return self._connect_to_network_macos(ssid, password, security)
            else:
                return self._connect_to_network_linux(ssid, password, security)
        except Exception as e:
            logging.error(f"Error connecting to network {ssid}: {e}")
            return False
    
    def _connect_to_network_macos(self, ssid, password, security='WPA'):
        """Connect to Wi-Fi network on macOS"""
        try:
            if security.upper() == 'NONE' or not password:
                # Connect to open network
                result = subprocess.run(['networksetup', '-setairportnetwork', self.interface, ssid], 
                                      capture_output=True, text=True, timeout=30)
            else:
                # Connect to secured network
                result = subprocess.run(['networksetup', '-setairportnetwork', self.interface, ssid, password], 
                                      capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                logging.info(f"Successfully connected to {ssid} on macOS")
                return True
            else:
                logging.error(f"Failed to connect to {ssid} on macOS: {result.stderr}")
                return False
        
        except Exception as e:
            logging.error(f"Error connecting to network {ssid} on macOS: {e}")
            return False
    
    def _connect_to_network_linux(self, ssid, password, security='WPA'):
        """Connect to Wi-Fi network on Linux"""
        try:
            if not self.wpa_supplicant_conf:
                logging.error("wpa_supplicant configuration file not available")
                return False
            
            # Create network configuration
            if security.upper() == 'NONE' or not password:
                network_config = f'''
network={{
    ssid="{ssid}"
    key_mgmt=NONE
}}
'''
            else:
                network_config = f'''
network={{
    ssid="{ssid}"
    psk="{password}"
}}
'''
            
            # Backup current config
            subprocess.run(['sudo', 'cp', self.wpa_supplicant_conf, 
                          f'{self.wpa_supplicant_conf}.backup'], timeout=10)
            
            # Add network to wpa_supplicant.conf
            with open(self.wpa_supplicant_conf, 'a') as f:
                f.write(network_config)
            
            # Restart wpa_supplicant
            subprocess.run(['sudo', 'systemctl', 'restart', 'wpa_supplicant'], timeout=10)
            subprocess.run(['sudo', 'systemctl', 'restart', 'dhcpcd'], timeout=10)
            
            logging.info(f"Added network configuration for {ssid}")
            return True
        
        except Exception as e:
            logging.error(f"Error connecting to network {ssid} on Linux: {e}")
            return False
    
    def disconnect_wifi(self):
        """Disconnect from current Wi-Fi"""
        try:
            if self.is_macos:
                # Disconnect Wi-Fi on macOS
                result = subprocess.run(['networksetup', '-setairportpower', self.interface, 'off'], timeout=10)
                subprocess.run(['networksetup', '-setairportpower', self.interface, 'on'], timeout=10)
                return result.returncode == 0
            else:
                # Disconnect Wi-Fi on Linux
                subprocess.run(['sudo', 'ifdown', self.interface], timeout=10)
                subprocess.run(['sudo', 'ifup', self.interface], timeout=10)
                return True
        except Exception as e:
            logging.error(f"Error disconnecting Wi-Fi: {e}")
            return False
    
    def restart_networking(self):
        """Restart networking services"""
        try:
            if self.is_macos:
                # Restart networking on macOS
                result1 = subprocess.run(['networksetup', '-setairportpower', self.interface, 'off'], timeout=10)
                result2 = subprocess.run(['networksetup', '-setairportpower', self.interface, 'on'], timeout=10)
                return result1.returncode == 0 and result2.returncode == 0
            else:
                # Restart networking on Linux
                subprocess.run(['sudo', 'systemctl', 'restart', 'dhcpcd'], timeout=15)
                subprocess.run(['sudo', 'systemctl', 'restart', 'wpa_supplicant'], timeout=15)
                return True
        except Exception as e:
            logging.error(f"Error restarting networking: {e}")
            return False

wifi_manager = WiFiManager()

@app.route('/')
def index():
    """Main page"""
    current_connection = wifi_manager.get_current_connection()
    current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    return render_template_string(HTML_TEMPLATE, 
                                current_connection=current_connection,
                                current_time=current_time)

@app.route('/scan')
def scan_networks():
    """Scan for available networks"""
    try:
        networks = wifi_manager.scan_networks()
        return jsonify({'success': True, 'networks': networks})
    except Exception as e:
        logging.error(f"Scan error: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/connect', methods=['POST'])
def connect_network():
    """Connect to a Wi-Fi network"""
    try:
        ssid = request.form.get('ssid')
        password = request.form.get('password', '')
        security = request.form.get('security', 'WPA')
        
        if not ssid:
            return jsonify({'success': False, 'error': 'SSID is required'})
        
        success = wifi_manager.connect_to_network(ssid, password, security)
        
        if success:
            logging.info(f"Successfully initiated connection to {ssid}")
            return redirect(url_for('index'))
        else:
            return jsonify({'success': False, 'error': 'Failed to connect'})
    
    except Exception as e:
        logging.error(f"Connect error: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/disconnect', methods=['POST'])
def disconnect():
    """Disconnect from Wi-Fi"""
    try:
        success = wifi_manager.disconnect_wifi()
        if success:
            return jsonify({'success': True, 'message': 'Disconnected from Wi-Fi'})
        else:
            return jsonify({'success': False, 'message': 'Failed to disconnect'})
    except Exception as e:
        logging.error(f"Disconnect error: {e}")
        return jsonify({'success': False, 'message': str(e)})

@app.route('/restart_networking', methods=['POST'])
def restart_networking():
    """Restart networking services"""
    try:
        success = wifi_manager.restart_networking()
        if success:
            return jsonify({'success': True, 'message': 'Networking services restarted'})
        else:
            return jsonify({'success': False, 'message': 'Failed to restart networking'})
    except Exception as e:
        logging.error(f"Restart networking error: {e}")
        return jsonify({'success': False, 'message': str(e)})

@app.route('/logs')
def get_logs():
    """Get system logs"""
    try:
        # Get last 50 lines of wifi config log
        result = subprocess.run(['tail', '-n', '50', '/var/log/wifi_config.log'], 
                              capture_output=True, text=True, timeout=10)
        logs = result.stdout if result.returncode == 0 else 'No logs available'
        
        return jsonify({'logs': logs})
    except Exception as e:
        return jsonify({'logs': f'Error reading logs: {e}'})

if __name__ == '__main__':
    # Platform compatibility check
    import platform
    system = platform.system()
    if system == 'Darwin':
        print("Running on macOS - some features may have limited functionality")
        print("For full functionality, run on Raspberry Pi OS or Linux")
    elif system != 'Linux':
        print(f"Running on {system} - this application is designed for Raspberry Pi OS/Linux")
        print("Some features may not work correctly")
    
    # Check if running as root (required for port 80)
    if os.geteuid() != 0:
        print("Warning: Not running as root. Port 80 may not be available.")
        print("Run with: sudo python3 wifi_config_web.py")
        # Fall back to port 8080
        port = 8080
    else:
        port = 80
    
    logging.info(f"Starting Wi-Fi Configuration Web Interface on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)