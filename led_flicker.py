import time
import random
import zmq
from rpi_ws281x import PixelStrip, Color, ws

# === LED CONFIG ===
LED_COUNT = 150
LED_PIN = 13              # GPIO13 = PWM1
LED_FREQ_HZ = 800000
LED_DMA = 10
LED_BRIGHTNESS = 128
LED_INVERT = False
LED_CHANNEL = 1
LED_STRIP_TYPE = ws.WS2811_STRIP_GRB

strip = PixelStrip(
    LED_COUNT,
    LED_PIN,
    LED_FREQ_HZ,
    LED_DMA,
    LED_INVERT,
    LED_BRIGHTNESS,
    LED_CHANNEL,
    strip_type=LED_STRIP_TYPE
)
strip.begin()

# === ZMQ SETUP ===
ctx = zmq.Context()
sub = ctx.socket(zmq.SUB)
sub.connect("tcp://localhost:5557")
sub.setsockopt_string(zmq.SUBSCRIBE, "/set,ledglitch")

# === COLOR HELPERS ===
def orange_color(brightness):
    r = int(min(255, brightness))
    g = int(min(255, brightness * 0.3))
    return Color(r, g, 0)

def flash_color():
    return Color(255, 120, 0)  # intense orange flash

# === MAIN LOOP ===
glitch_strength = 0.0

try:
    while True:
        # --- Read incoming glitch strength ---
        try:
            while sub.poll(0):
                msg = sub.recv_string()
                _, _, value = msg.split(",")
                glitch_strength = max(0.0, min(1.0, float(value)))
        except Exception as e:
            print("ZMQ error:", e)

        if glitch_strength < 0.01:
            color = orange_color(255)
            for i in range(strip.numPixels()):
                strip.setPixelColor(i, color)
            try:
                strip.show()
            except Exception as e:
                print("LED show() error:", e)
            time.sleep(0.2)
            continue


        # --- Flicker logic ---
        base = int(64 + (glitch_strength * 191))
        flicker_chance = 0.5 + glitch_strength * 0.5
        off_chance = glitch_strength * 0.2
        flash_chance = glitch_strength * 0.05

        
        # Pick color
        if random.random() < flash_chance:
            color = flash_color()
        elif random.random() < off_chance:
            color = Color(0, 0, 0)
        elif random.random() < flicker_chance:
            brightness = random.randint(int(base * 0.1), min(base + 50, 255))
            color = orange_color(brightness)
        else:
            color = orange_color(base)

        for i in range(strip.numPixels()):
            strip.setPixelColor(i, color)

        try:
            strip.show()
        except Exception as e:
            print("LED show() error:", e)

        # More aggressive flickering = faster updates
        #delay = 0.2 - glitch_strength * 0.15
        #delay = max(0.05, delay)
        delay = max(0.03, 0.1 - glitch_strength * 0.07)

        time.sleep(delay)

except KeyboardInterrupt:
    strip.fill(Color(0, 0, 0))
    strip.show()
    print("\nLED glitch stopped.")

