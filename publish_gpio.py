import time
import math
import random
import zmq
from pythonosc.udp_client import SimpleUDPClient

import board
import busio
import adafruit_ads1x15.ads1115 as ADS1115
from adafruit_ads1x15.analog_in import AnalogIn

i2c = busio.I2C(board.SCL, board.SDA)

ads = ADS1115.ADS1115(i2c)
chan0 = AnalogIn(ads, 0)  # Channel 0
chan1 = AnalogIn(ads, 1)  # Channel 1

osc = SimpleUDPClient("127.0.0.1", 57120)
ctx = zmq.Context()
pub = ctx.socket(zmq.PUB)
pub.bind("tcp://*:5557")

low1 = 1.0   # volts
high1 = 2.9  # volts
low2 = 0.15
high2 = 0.5

target_x1 = 1.5
target_x2 = 1.5
last_target_time = time.time()
target_interval = 60.0

def normalize(v, low, high):
    return max(0.0, min(1.0, (v - low) / (high - low)))

while True:
    try:
        x1 = chan0.voltage
        x2 = chan1.voltage

        norm_x1 = normalize(x1, low1, high1)
        norm_x2 = normalize(x2, low2, high2)

        now = time.time()
        if now - last_target_time > target_interval:
            while True:
                new_x1 = random.uniform(low1, high1)
                new_x2 = random.uniform(low2, high2)

                norm_new_x1 = normalize(new_x1, low1, high1)
                norm_new_x2 = normalize(new_x2, low2, high2)

                norm_old_x1 = normalize(target_x1, low1, high1)
                norm_old_x2 = normalize(target_x2, low2, high2)

                dist = math.sqrt((norm_new_x1 - norm_old_x1) ** 2 + (norm_new_x2 - norm_old_x2) ** 2)

                if dist >= 0.5:
                    target_x1, target_x2 = new_x1, new_x2
                    last_target_time = now
                    print(f"🎯 New targets -> x1: {target_x1:.2f}, x2: {target_x2:.2f}")
                    break

        
        norm_target_x1 = normalize(target_x1, low1, high1)
        norm_target_x2 = normalize(target_x2, low2, high2)

        dist = math.sqrt((norm_x1 - norm_target_x1) ** 2 + (norm_x2 - norm_target_x2) ** 2)
        tolerance = 0.1
        led_tolerance = 0.3

        if dist < led_tolerance:
            led_glitch = 0.0
        else:
            scaled = (dist - tolerance) / (1.0 - tolerance)
            eased = pow(scaled, 2.5)  # makes the start very gentle, ramps up later
            led_glitch = min(eased * 0.7, 1.0)  # even milder at start


        if dist < tolerance:
            distort = 0.0
        else:
            scaled = (dist - tolerance) / (1.0 - tolerance)
            distort = min(pow(scaled, 1.5), 1.0)

        pub.send_string(f"/set,distort,{distort:.2f}")
        distort_audio = min((scaled ** 0.9) * 1.2, 1.0) if dist >= tolerance else 0.0

        print(f"x1: {x1:.2f} x2: {x2:.2f} → video: {distort:.2f} | audio: {distort_audio:.2f}")
        osc.send_message("/set/distort", distort_audio)

        # LED glitch = stronger flicker
        #led_glitch = min((scaled ** 1.2), 1.0) if dist >= 0.3 else 0.0
        pub.send_string(f"/set,ledglitch,{led_glitch:.2f}")


    except Exception as e:
        print("Error:", e)

    time.sleep(0.1)

