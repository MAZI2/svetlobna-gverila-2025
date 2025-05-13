#!/bin/bash

# === CONFIGURE LOG FILES ===
LOG_FILES=(/tmp/audio.log /tmp/video.log /tmp/gpio.log /tmp/led.log /tmp/avlaunch_debug.log)

for f in "${LOG_FILES[@]}"; do
    rm -f "$f"
    touch "$f"
    chmod 666 "$f"
done

# === ARGUMENTS ===
VIDEO_FILE="${1:-gverila_1024.mp4}"
AUDIO_START_DELAY="${2:-0.0}"
VIDEO_START_DELAY="${3:-5.0}"
DURATION="${4:-330}"  # Total AV cycle duration

AUDIO_SCRIPT="run_audio.sh"
VIDEO_SCRIPT="run_ffglitch.sh"

# === INITIAL CLEANUP ===
echo "🧹 Cleaning up old processes..."
sudo pkill -9 scsynth
sudo pkill -9 sclang
sudo pkill -9 ffmpeg
sudo pkill -9 aplay
sudo pkill -9 ffgac
sudo pkill -9 fflive
sudo pkill -9 -f led_flicker.py
sudo pkill -9 -f publish_gpio.py
sleep 1

# === START GPIO + LED ===
echo "⚡ Starting GPIO input and LED flicker scripts..."
/root/venv/bin/python3 publish_gpio.py > /tmp/gpio.log 2>&1 &
GPIO_PID=$!

/root/venv/bin/python3 led_flicker.py > /tmp/led.log 2>&1 &
LED_PID=$!

# === START SuperCollider ===
echo "🎵 Starting SuperCollider (bit_crush.scd)..."
sclang /home/dietpi/ffglitch-livecoding/bit_crush.scd &
SCLANG_PID=$!

echo "⏳ Waiting 5 seconds for SuperCollider to initialize..."
sleep 5

# === MAIN AUDIO/VIDEO LOOP ===
while true; do
    echo "🔁 Starting AV cycle..."

    # AUDIO START
    echo "⏳ Waiting $AUDIO_START_DELAY seconds before launching AUDIO..."
    sleep "$AUDIO_START_DELAY"
    echo "🔊 Launching audio pipeline..."
    bash "$AUDIO_SCRIPT" "$VIDEO_FILE" > /tmp/audio.log 2>&1 &
    AUDIO_PID=$!
    echo "AUDIO_PID=$AUDIO_PID" >> /tmp/avlaunch_debug.log

    # VIDEO START
    echo "⏳ Waiting $VIDEO_START_DELAY seconds before launching VIDEO..."
    sleep "$VIDEO_START_DELAY"
    echo "🎞️ Launching video pipeline..."
    bash "$VIDEO_SCRIPT" "$VIDEO_FILE" > /tmp/video.log 2>&1 &
    VIDEO_PID=$!
    echo "VIDEO_PID=$VIDEO_PID" >> /tmp/avlaunch_debug.log

    echo "⏳ Waiting $DURATION seconds for AV playback to finish..."
    sleep "$DURATION"

    echo "🧹 Killing audio and video processes..."
    sudo pkill -9 ffmpeg
    sudo pkill -9 aplay
    sudo pkill -9 ffgac
    sudo pkill -9 fflive
done

# === Fallback keepalive (not needed if loop runs) ===
# wait $GPIO_PID $LED_PID $SCLANG_PID
# while true; do sleep 60; done

