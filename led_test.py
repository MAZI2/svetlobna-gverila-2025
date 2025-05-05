import time
from rpi_ws281x import PixelStrip, Color, ws

# === LED CONFIG ===
LED_COUNT = 150         # Number of LEDs in your strip
LED_PIN = 13            # GPIO13 = PWM1
LED_FREQ_HZ = 800000    # LED signal frequency
LED_DMA = 10            # DMA channel
LED_BRIGHTNESS = 128    # 0 to 255
LED_INVERT = False      # True to invert the signal (most times False)
LED_CHANNEL = 1         # Channel 1 for GPIO13
LED_STRIP_TYPE = ws.WS2811_STRIP_GRB

# === INITIALIZE STRIP ===
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

# === COLOR WHEEL FUNCTION ===
def wheel(pos):
    """Input 0-255, output Color(R,G,B). All LEDs get the same."""
    if pos < 85:
        return Color(pos * 3, 255 - pos * 3, 0)
    elif pos < 170:
        pos -= 85
        return Color(255 - pos * 3, 0, pos * 3)
    else:
        pos -= 170
        return Color(0, pos * 3, 255 - pos * 3)

# === LOOP: FILL WHOLE STRIP WITH SAME COLOR ===
try:
    while True:
        for j in range(256):
            color = wheel(j & 255)
            for i in range(strip.numPixels()):
                strip.setPixelColor(i, color)
            strip.show()
            time.sleep(0.02)  # adjust speed here
except KeyboardInterrupt:
    strip.fill(Color(0, 0, 0))
    strip.show()

