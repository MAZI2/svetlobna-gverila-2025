#!/bin/bash

echo "🛑 Stopping audio/video processes..."

# List of process names to kill
PROCESSES=(
  sclang
  scsynth
  ffgac
  fflive
  ffmpeg
  aplay
)

# Kill each process forcefully
for proc in "${PROCESSES[@]}"; do
    echo "Killing $proc..."
    sudo pkill -9 "$proc"
done

# Optional: restore getty on tty3 if it was stopped
echo "🔁 Restarting getty on tty3 (login terminal)..."
sudo systemctl start getty@tty3.service

echo "✅ All processes stopped."
