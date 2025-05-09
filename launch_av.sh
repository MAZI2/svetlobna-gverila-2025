#!/bin/bash

# === AUDIO + VIDEO SYNCHRONIZED LAUNCH WITH TUNABLE DELAYS ===

# --- Configurable delays ---
AUDIO_START_DELAY=0.0   # Seconds to wait before launching audio
VIDEO_START_DELAY=8.0   # Seconds to wait before launching video

# --- Paths ---
AUDIO_SCRIPT="run_audio.sh"
VIDEO_SCRIPT="run_ffglitch.sh"
VIDEO_FILE="${1:-testvideo.mp4}"

# --- Cleanup ---
echo "🧹 Cleaning up old processes..."
sudo pkill -9 sclang
sudo pkill -9 scsynth
sudo pkill -9 ffmpeg
sudo pkill -9 aplay
sudo pkill -9 ffgac
sudo pkill -9 fflive
sleep 1

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

# --- Optional: Wait for both ---
wait $AUDIO_PID $VIDEO_PID
echo "✅ Audio and video pipelines exited."

