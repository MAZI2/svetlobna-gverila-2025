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
low1 = 300.0
high1 = 800.0

low2 = 400.0
high2 = 700.0

# Initialize target values and timing
target_x1 = 500
target_x2 = 500
last_target_time = time.time()
target_interval = 60.0  # seconds

def normalize(x1, x2):
    return (max(0.0, min(1.0, (x1 - low1) / (high1 - low1))), max(0.0, min(1.0, (x2 - low2) / (high2 - low2))))

while True:
    try:
        # Expect two values from serial like: "543,812"
        line = ser.readline().decode().strip()
        parts = line.split(",")
        if len(parts) != 2:
            continue

        x1 = float(parts[0])
        x2 = float(parts[1])

        norm_x1, norm_x2 = normalize(x1, x2)

        # Update target every 10 seconds
        now = time.time()
        if now - last_target_time > target_interval:
            target_x1 = random.uniform(low1, high1)
            target_x2 = random.uniform(low2, high2)
            last_target_time = now
            print(f"🎯 New targets -> x1: {int(target_x1)}, x2: {int(target_x2)}")

        # Normalize targets too
        norm_target_x1, norm_target_x2 = normalize(target_x1, target_x2)

        # Compute Euclidean distance between (x1, x2) and (target_x1, target_x2)

        tolerance = 0.1  # wide zone around target = no distortion

        # Raw distance
        dist = math.sqrt((norm_x1 - norm_target_x1)**2 + (norm_x2 - norm_target_x2)**2)

        # Apply non-linear mapping with a dead zone
        if dist < tolerance:
            distort = 0.0
        else:
            # Steep penalty outside tolerance zone
            scaled = (dist - tolerance) / (1.0 - tolerance)  # scale to 0–1
            
            print(scaled)
            distort = min(pow(scaled, 1.5), 1.0)

        print(f"x1: {int(x1)} x2: {int(x2)}  → distort: {distort:.2f}")
        pub.send_string(f"/set,distort,{distort:.2f}")

    except Exception as e:
        print("Error:", e)

    time.sleep(0.1)

