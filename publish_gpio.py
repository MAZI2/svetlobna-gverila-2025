import zmq
import time
import serial
import math
import random

# Serial for Arduino or analog bridge
ser = serial.Serial('/dev/ttyACM0', 9600)

ctx = zmq.Context()
pub = ctx.socket(zmq.PUB)
pub.bind("tcp://*:5557")

# Value range from your ADC
low = 200.0
high = 1000.0

# Initialize target values and timing
target_x1 = 500
target_x2 = 500
last_target_time = time.time()
target_interval = 60.0  # seconds

def normalize(val):
    return max(0.0, min(1.0, (val - low) / (high - low)))

while True:
    try:
        # Expect two values from serial like: "543,812"
        line = ser.readline().decode().strip()
        parts = line.split(",")
        if len(parts) != 2:
            continue

        x1 = float(parts[0])
        x2 = float(parts[1])

        norm_x1 = normalize(x1)
        norm_x2 = normalize(x2)

        # Update target every 10 seconds
        now = time.time()
        if now - last_target_time > target_interval:
            target_x1 = random.uniform(low, high)
            target_x2 = random.uniform(low, high)
            last_target_time = now
            print(f"🎯 New targets -> x1: {int(target_x1)}, x2: {int(target_x2)}")

        # Normalize targets too
        norm_target_x1 = normalize(target_x1)
        norm_target_x2 = normalize(target_x2)

        # Compute Euclidean distance between (x1, x2) and (target_x1, target_x2)
        dist = math.sqrt(
            (norm_x1 - norm_target_x1) ** 2 +
            (norm_x2 - norm_target_x2) ** 2
        )
        distort = min(dist * 1.5, 1.0)  # scale and cap

        print(f"x1: {int(x1)} x2: {int(x2)}  → distort: {distort:.2f}")
        pub.send_string(f"/set,distort,{distort:.2f}")

    except Exception as e:
        print("Error:", e)

    time.sleep(0.1)

