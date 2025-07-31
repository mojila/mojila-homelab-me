from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, dbus_property, signal
import subprocess
import asyncio

COMMAND_UUID = "12345678-1234-5678-1234-56789abcdef1"

class CommandService(ServiceInterface):
    def __init__(self):
        super().__init__("org.bluez.GattCharacteristic1")

    @method()
    async def WriteValue(self, value, options):
        command = bytes(value).decode()
        print(f"[📥] Received command: {command}")
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            print("[🖥] Output:", result.stdout or result.stderr)
        except Exception as e:
            print(f"[⚠️] Error: {e}")

async def main():
    bus = await MessageBus().connect()
    # You'd need to register service and characteristic properly here
    # We can use `aiobleserver` or BlueZ profile example if needed

    print("[🔵] BLE GATT server started (mock-up)")
    await asyncio.Future()

asyncio.run(main())
