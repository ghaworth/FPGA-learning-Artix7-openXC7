import serial

port = '/dev/tty.usbserial-83401'
baud = 115200

ser = serial.Serial(port, baud, timeout=5)

result_bytes = ser.read(2)
timer_bytes = ser.read(4)

result = int.from_bytes(result_bytes, byteorder='little')
cycles = int.from_bytes(timer_bytes, byteorder='little')

time_ms = cycles/25000

print(f"Result: {result}")
print(f"Cycles: {cycles}")
print(f"Time: {time_ms:.6f} ms")