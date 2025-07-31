import bluetooth
import argparse

def find_pi():
    print("[🔍] Searching for Bluetooth devices...")
    devices = bluetooth.discover_devices(duration=5, lookup_names=True)
    for addr, name in devices:
        print(f"  Found {name} - {addr}")
        if "OrangePi" in name or "raspberrypi" in name:
            return addr
    raise Exception("Orange Pi not found")

def send_command(addr, command):
    port = 1  # Common RFCOMM port
    sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
    sock.connect((addr, port))
    print(f"[📡] Connected to {addr}")
    sock.send(command)
    response = sock.recv(4096).decode()
    print("[📬] Response:\n" + response)
    sock.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", help="Shell command to send to Orange Pi")
    args = parser.parse_args()

    try:
        pi_address = find_pi()
        send_command(pi_address, args.command)
    except Exception as e:
        print("[❌] Error:", e)
