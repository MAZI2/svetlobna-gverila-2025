#!/bin/bash

# Preload loopback by playing a long sine tone
echo "[1/3] Starting SOX tone on hw:7,0..."
sox -n -t alsa -r 44100 -c 1 -e signed -b 16 hw:7,0 synth 999 sine 440 vol 0.2 &

SOX_PID=$!
sleep 1  # Wait for loopback to initialize

echo "[2/3] Checking if loopback is readable..."
# Try reading a short burst to ensure capture is alive
arecord -f S16_LE -r 44100 -c 1 -d 1 -t raw -D hw:7,1 > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Loopback capture not ready. Aborting."
  kill $SOX_PID
  exit 1
fi

echo "[3/3] Starting SuperCollider..."
sclang test_scd.scd

# Cleanup
kill $SOX_PID

