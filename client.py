import asyncio
from bleak import BleakClient, BleakScanner

COMMAND_UUID = "12345678-1234-5678-1234-56789abcdef1"

async def send_command(command):
    print("[🔍] Scanning for Orange Pi BLE...")
    devices = await BleakScanner.discover()
    for d in devices:
        if "OrangePi" in d.name:
            async with BleakClient(d.address) as client:
                print(f"[🔗] Connected to {d.name}")
                await client.write_gatt_char(COMMAND_UUID, command.encode())
                print("[✅] Command sent")
                return
    print("[❌] Orange Pi not found.")

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python ble_client.py <command>")
        exit(1)
    asyncio.run(send_command(sys.argv[1]))
