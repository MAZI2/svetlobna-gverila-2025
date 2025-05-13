#!/bin/bash

# === AUDIO + VIDEO SYNCHRONIZED LAUNCH WITH TUNABLE DELAYS ===

# --- Get arguments ---
VIDEO_FILE="${1:-testvideo.mp4}"
AUDIO_START_DELAY="${2:-0.0}"    # Default: 0.0 seconds
VIDEO_START_DELAY="${3:-8.0}"    # Default: 8.0 seconds

# --- Paths ---
AUDIO_SCRIPT="run_audio.sh"
VIDEO_SCRIPT="run_ffglitch.sh"

# --- Cleanup ---
echo "🧹 Cleaning up old processes..."
sudo pkill -9 sclang
sudo pkill -9 scsynth
sudo pkill -9 ffmpeg
sudo pkill -9 aplay
sudo pkill -9 ffgac
sudo pkill -9 fflive
sudo pkill -9 -f publish_gpio.py
sudo pkill -9 -f led_flicker.py
sleep 1

# --- Launch GPIO publisher and LED flicker ---
echo "⚡ Starting GPIO input and LED flicker scripts..."
/root/venv/bin/python3 /home/dietpi/ffglitch-livecoding/publish_gpio.py > /tmp/gpio.log 2>&1 &
GPIO_PID=$!

/root/venv/bin/python3 /home/dietpi/ffglitch-livecoding/led_flicker.py > /tmp/led.log 2>&1 &
LED_PID=$!

# --- Launch AUDIO ---
echo "⏳ Waiting $AUDIO_START_DELAY seconds before launching AUDIO..."
sleep "$AUDIO_START_DELAY"
echo "🔊 Launching audio pipeline..."
bash "$AUDIO_SCRIPT" "$VIDEO_FILE" > /tmp/audio.log 2>&1 &
AUDIO_PID=$!

# --- Launch VIDEO ---
echo "⏳ Waiting $VIDEO_START_DELAY seconds before launching VIDEO..."
sleep "$VIDEO_START_DELAY"
echo "🎞️ Launching video pipeline..."
bash "$VIDEO_SCRIPT" "$VIDEO_FILE" > /tmp/video.log 2>&1 &
VIDEO_PID=$!

# --- Optional: Wait for all ---
wait $GPIO_PID $LED_PID $AUDIO_PID $VIDEO_PID
echo "✅ All processes exited."

