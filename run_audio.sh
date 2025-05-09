#!/bin/bash

# --- Step 1: Clean up any old SuperCollider processes ---
echo "Stopping any existing sclang or scsynth processes..."
sudo pkill -9 sclang
sudo pkill -9 scsynth
sleep 1

# --- Step 2: Reload audio drivers ---
echo "Loading audio drivers..."
sudo modprobe -r snd-aloop
sudo modprobe snd-bcm2835
sudo modprobe snd-aloop enable=1,1 index=7
sleep 1

# --- Step 3: Start SuperCollider script ---
echo "Starting SuperCollider (bit_crush.scd)..."
sclang /home/dietpi/ffglitch-livecoding/bit_crush.scd &
SCLANG_PID=$!

# Wait for sclang to boot properly
echo "Waiting for SuperCollider to initialize..."
sleep 5

FILE="${1:-audio_only.mp4}"

# --- Step 4: Start ffmpeg -> aplay pipeline ---
echo "Starting audio pipeline (ffmpeg -> aplay)..."
ffmpeg -i "$FILE" \
    -f s16le -ac 1 -ar 44100 \
    -af "aresample=44100,pan=mono|c0=FL" - \
    | aplay -f S16_LE -r 44100 -c 1 -D loop_out

