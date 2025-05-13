#!/bin/bash

# Ensure log files are writable
LOG_FILES=(/tmp/audio.log /tmp/video.log /tmp/gpio.log /tmp/led.log /tmp/avlaunch_debug.log)

for f in "${LOG_FILES[@]}"; do
    rm -f "$f"
    touch "$f"
    chmod 666 "$f"
done

# Arguments with defaults
VIDEO_FILE="${1:-gverila_1024.mp4}"
AUDIO_START_DELAY="${2:-0.0}"
VIDEO_START_DELAY="${3:-3.0}"

AUDIO_SCRIPT="run_audio.sh"
VIDEO_SCRIPT="run_ffglitch.sh"

# Cleanup
echo "🧹 Cleaning up old processes..."
sudo pkill -9 sclang scsynth ffmpeg aplay ffgac fflive
sudo pkill -9 -f publish_gpio.py led_flicker.py
sleep 1

# Launch GPIO publisher and LED flicker
echo "⚡ Starting GPIO input and LED flicker scripts..."
/root/venv/bin/python3 publish_gpio.py > /tmp/gpio.log 2>&1 &
GPIO_PID=$!

/root/venv/bin/python3 led_flicker.py > /tmp/led.log 2>&1 &
LED_PID=$!

# Launch AUDIO
echo "⏳ Waiting $AUDIO_START_DELAY seconds before launching AUDIO..."
sleep "$AUDIO_START_DELAY"
echo "🔊 Launching audio pipeline..."
bash "$AUDIO_SCRIPT" "$VIDEO_FILE" > /tmp/audio.log 2>&1 &
AUDIO_PID=$!
echo "AUDIO_PID=$AUDIO_PID" >> /tmp/avlaunch_debug.log

# Launch VIDEO
echo "⏳ Waiting $VIDEO_START_DELAY seconds before launching VIDEO..."
sleep "$VIDEO_START_DELAY"
echo "🎞️ Launching video pipeline..."
bash "$VIDEO_SCRIPT" "$VIDEO_FILE" > /tmp/video.log 2>&1 &
VIDEO_PID=$!
echo "VIDEO_PID=$VIDEO_PID" >> /tmp/avlaunch_debug.log

# Properly wait to keep systemd alive
wait $GPIO_PID $LED_PID $AUDIO_PID $VIDEO_PID
echo "✅ All processes exited."

# Keep script running if desired
while true; do sleep 60; done

