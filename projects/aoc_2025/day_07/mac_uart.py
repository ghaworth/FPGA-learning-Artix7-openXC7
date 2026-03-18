import serial
port = '/dev/ttyUSB1'
baud = 115200
ser = serial.Serial(port, baud, timeout=10)
print("Waiting for data... press button")
while True:
    b = ser.read(1)
    if len(b) == 0:
        print("Timeout")
        break
    if b[0] == 0xAA:
        b2 = ser.read(1)
        if len(b2) > 0 and b2[0] == 0x55:
            result_bytes = ser.read(2)
            timer_bytes = ser.read(4)
            result = int.from_bytes(result_bytes, byteorder='little')
            cycles = int.from_bytes(timer_bytes, byteorder='little')
            time_ms = cycles / 100_000
            print(f"Result: {result}")
            print(f"Cycles: {cycles}")
            print(f"Time: {time_ms:.6f} ms")
            break