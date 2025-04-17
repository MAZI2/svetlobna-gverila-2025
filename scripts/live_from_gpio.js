import * as zmq from "zmq";

console.log("live_from_gpio.js loaded");

// ✅ Declare globally so it's accessible in both setup() and glitch_frame()
let osc = { distort: 0.0 };

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
  // ✅ Must declare which features this script uses!
  args.features = ["mv"];
}

export function glitch_frame(frame) {
  const mv = frame.mv?.forward;
  if (!mv) return;

  // ✅ Non-blocking OSC message polling
  try {
    let msg = zmqoscsocket.recv_str(zmq.DONTWAIT);
    while (msg) {
      handle_osc(msg);
      msg = zmqoscsocket.recv_str(zmq.DONTWAIT);
    }
  } catch (e) {
    // ignore if nothing is received
  }

  print(osc.distort)

  const distortion = osc.distort ?? 0.5;

  const block_size = 0.5;
  const tile_shift_map = new Map();

  const height = mv.height;
  const width = mv.width;

  mv.forEach((vec, row, col) => {
    if (!vec) return;

    // Tile key based on block_size
    const tile_x = Math.floor(col / block_size);
    const tile_y = Math.floor(row / block_size);
    const tile_key = `${tile_x},${tile_y}`;

    // Assign shift per tile (and cache it)
    if (!tile_shift_map.has(tile_key)) {
      const xshift = (Math.random() - 0.5) * distortion * 20;
      const yshift = (Math.random() - 0.5) * distortion * 20;
      tile_shift_map.set(tile_key, [xshift, yshift]);
    }

    const [xshift, yshift] = tile_shift_map.get(tile_key);
    vec[0] += xshift;
    vec[1] += yshift;

    // Add a little noise
    if (Math.random() < distortion * 0.05) {
      vec[0] += (Math.random() - 0.5) * 2;
      vec[1] += (Math.random() - 0.5) * 2;
    }
  });


}

