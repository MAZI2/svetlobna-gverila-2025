import * as zmq from "zmq";

console.log("live_from_gpio.js loaded");

// Global OSC state
let osc = { distort: 0.0 };

// ZMQ OSC setup
let ctx = new zmq.Context();
let zmqoscsocket = ctx.socket(zmq.SUB);
zmqoscsocket.setsockopt(zmq.SUBSCRIBE, "");
zmqoscsocket.connect("tcp://localhost:5557");

function handle_osc(message) {
  const parts = message.split(",");
  if (parts[0] === "/set") {
    osc[parts[1]] = parseFloat(parts[2]);
  }
}

export function setup(args) {
  args.features = ["mv"];
}

// Tile shift memory with per-tile direction mode ("x" or "y")
let tile_shift_memory = new Map();

export function glitch_frame(frame) {
  const mv = frame.mv?.forward;
  if (!mv) return;

  // Read latest OSC messages
  try {
    let msg = zmqoscsocket.recv_str(zmq.DONTWAIT);
    while (msg) {
      handle_osc(msg);
      msg = zmqoscsocket.recv_str(zmq.DONTWAIT);
    }
  } catch (e) {}

  const raw_distort = osc.distort ?? 0.0;
  const distortion = Math.pow(raw_distort, 2.5);         // for glitch activation
  const healing = Math.pow(1 - raw_distort, 2.5);        // for repair probability

  const block_size = 8;

  mv.forEach((vec, row, col) => {
    if (!vec) return;

    const tile_x = Math.floor(col / block_size);
    const tile_y = Math.floor(row / block_size);
    const tile_key = `${tile_x},${tile_y}`;

    // Load or initialize tile memory: xshift, yshift, direction mode
    let [xshift, yshift, mode] = tile_shift_memory.get(tile_key) || [0, 0, null];

    // Assign mode randomly if not set yet
    if (mode === null) {
      mode = Math.random() < 0.5 ? "x" : "y";
    }

    // Random distortion flicker per tile
    if (Math.random() < distortion * 0.5) {
      const max_jump = 4 + raw_distort * 8;
      if (mode === "x") {
        xshift += (Math.random() - 0.5) * max_jump;
      } else {
        yshift += (Math.random() - 0.5) * max_jump;
      }
    }

    // Apply capped shift
    vec[0] += Math.max(-10, Math.min(10, xshift));
    vec[1] += Math.max(-10, Math.min(10, yshift));

    // Rare burst noise
    if (Math.random() < distortion * 0.05) {
      if (mode === "x") {
        vec[0] += (Math.random() - 0.5) * 10;
      } else {
        vec[1] += (Math.random() - 0.5) * 10;
      }
    }

    // Decay with randomness
    const decay_factor = 0.9 + Math.random() * 0.1;
    xshift *= decay_factor;
    yshift *= decay_factor;

    // Random cleanup (more likely at low distortion)
    if (Math.random() < healing * 0.2) {
      xshift *= 0.5;
      yshift *= 0.5;
    }

    tile_shift_memory.set(tile_key, [xshift, yshift, mode]);
  });
}

