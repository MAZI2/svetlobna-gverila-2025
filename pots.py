import spidev

spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 1350000

def read_adc(channel):
    assert 0 <= channel <= 7
    r = spi.xfer2([1, (8 + channel) << 4, 0])
    print("Raw SPI response:", r)
    value = ((r[1] & 3) << 8) | r[2]
    return value

value = read_adc(0)
print("Value from CH0:", value)

