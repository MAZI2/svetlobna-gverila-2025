import asyncio
import os
import sys
import argparse
import random
import time

FFGAC_BIN = "./bin/ffgac"
FFLIVE_BIN = "./bin/fflive"
LIVE_SCRIPT = "./scripts/live_from_gpio.js"
MB_SCRIPT = "./scripts/mb_type_func_live_simple.js"

async def run_ffglitch(input_mode, media_path, distortion_value_getter):
    read_fd, write_fd = os.pipe()

    # Prepare ffgac command
    if input_mode == "video":
        input_args = f"-stream_loop -1 -i \"{media_path}\""
    elif input_mode == "image":
        input_args = f"-loop 1 -i \"{media_path}\" -t 1000000"
    elif input_mode == "webcam":
        input_args = "-i /dev/video0"
    else:
        raise ValueError("Unsupported input mode")

    if input_mode == "video":
        input_args = f"-stream_loop -1 -i \"{media_path}\""
    elif input_mode == "image":
        input_args = f"-loop 1 -i \"{media_path}\" -t 1000000"
    elif input_mode == "webcam":
        input_args = "-f v4l2 -i /dev/video0"
    else:
        raise ValueError("Unsupported input mode")

    ffgac_cmd = (
        f"{FFGAC_BIN} -hide_banner -loglevel error {input_args} "
        f"-vcodec mpeg4 -mpv_flags +nopimb+forcemv -qscale:v 1 "
        f"-fcode 5 -g max -sc_threshold max "
        f"-mb_type_script \"{MB_SCRIPT}\" -f m4v pipe:"
    )

    fflive_cmd = (
        f"{FFLIVE_BIN} -i -f m4v pipe: -s \"{LIVE_SCRIPT}\""
    )


    print("Starting ffgac...")
    ffgac = await asyncio.create_subprocess_shell(
        ffgac_cmd,
        stdout=write_fd,
        stderr=asyncio.subprocess.DEVNULL,  # or PIPE if you want error logs
    )
    
    os.close(write_fd)

    print("Starting fflive...")
    fflive = await asyncio.create_subprocess_shell(
        fflive_cmd,
        stdin=read_fd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT,
    )

    os.close(read_fd)

    async def stream_output(proc, name):
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
            print(f"[{name}] {line.decode(errors='ignore').strip()}")




    # Simulate GPIO input
    async def fake_gpio_loop():
        while True:
            value = distortion_value_getter()
            with open("/tmp/osc_override.txt", "w") as f:
                f.write(f"/set,distort,{value:.2f}\n")
            await asyncio.sleep(0.25)

    await asyncio.gather(
        stream_output(fflive, "fflive"),
        fake_gpio_loop(),
    )


def detect_input_mode(path):
    if path.endswith(".png") or path.endswith(".jpg"):
        return "image"
    elif path.endswith(".mp4") or path.endswith(".avi"):
        return "video"
    return None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True, help="Input media file")
    args = parser.parse_args()

    mode = detect_input_mode(args.file)
    if mode is None:
        print("Unsupported file type.")
        sys.exit(1)

    # Dummy input: simulate analog distortion control
    def dummy_gpio_value():
        return random.uniform(0.0, 1.0)

    asyncio.run(run_ffglitch(mode, args.file, dummy_gpio_value))

if __name__ == "__main__":
    main()

