#!/bin/bash

# --- Environment setup ---
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export SDL_VIDEODRIVER=kmsdrm
export XDG_RUNTIME_DIR=/tmp/runtime-dietpi
mkdir -p "$XDG_RUNTIME_DIR"
chown dietpi:dietpi "$XDG_RUNTIME_DIR"

# --- Switch to the right virtual terminal ---
# This assumes tty3 is where KMSDRM apps can run
chvt 3

# --- Stop conflicting terminal login (optional) ---
systemctl stop getty@tty3.service

# --- Launch the Python script with real GPIO potentiometer input ---
FILE="${1:-testvideo.mp4}"

./bin/ffgac -stream_loop -1 -i "$FILE" -vcodec mpeg4 -mpv_flags +nopimb+forcemv   -qscale:v 1 -fcode 5 -g max -sc_threshold max   -mb_type_script ./scripts/mb_type_func_live_simple.js   -f m4v pipe: | ./bin/fflive -i -f m4v pipe: -s ./scripts/live_from_gpio.js
