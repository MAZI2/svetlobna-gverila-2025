import zmq
import time
import random

ctx = zmq.Context()
pub = ctx.socket(zmq.PUB)
pub.bind("tcp://*:5557")

while True:
    distort = random.uniform(0.0, 1.0)
    pub.send_string(f"/set,distort,{distort:.2f}")
    time.sleep(0.1)
