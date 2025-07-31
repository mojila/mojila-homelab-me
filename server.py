import bluetooth

server_sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
server_sock.bind(("", bluetooth.PORT_ANY))
server_sock.listen(1)

port = server_sock.getsockname()[1]
bluetooth.advertise_service(server_sock, "PiCommandServer",
                            service_classes=[bluetooth.SERIAL_PORT_CLASS],
                            profiles=[bluetooth.SERIAL_PORT_PROFILE])

print(f"[🔵] Waiting for connection on RFCOMM channel {port}...")

client_sock, client_info = server_sock.accept()
print(f"[✅] Accepted connection from {client_info}")

try:
    while True:
        data = client_sock.recv(1024).decode().strip()
        if not data:
            break
        print(f"[📥] Received: {data}")
        # Execute command
        import subprocess
        result = subprocess.run(data, shell=True, capture_output=True, text=True)
        response = result.stdout + result.stderr
        client_sock.send(response.encode())
except OSError:
    pass

print("[🛑] Disconnected.")
client_sock.close()
server_sock.close()
