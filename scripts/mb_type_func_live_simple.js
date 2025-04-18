// ./bin/fflive -i CEP00109_mpeg4.avi -s scripts/mpeg4/mv_average.js
import * as zmq from "zmq";

const CANDIDATE_MB_TYPE_INTRA = (1 << 0);
const CANDIDATE_MB_TYPE_INTER = (1 << 1);

let zmqctx = new zmq.Context();
let zmqoscsocket = zmqctx.socket(zmq.SUB);
zmqoscsocket.setsockopt(zmq.SUBSCRIBE, "");
zmqoscsocket.connect("tcp://localhost:5557");

let osc = { distort: 0.0 };

function handleOSC(message) {
  const parts = message.split(",");
  if (parts[0] === "/set") {
    osc[parts[1]] = parseFloat(parts[2]);
  }
}

export function setup(args) {}

export function mb_type_func(args) {
  try {
    let msg = zmqoscsocket.recv_str(zmq.DONTWAIT);
    while (msg) {
      handleOSC(msg);
      msg = zmqoscsocket.recv_str(zmq.DONTWAIT);
    }
  } catch (e) {}

  const distort = osc.distort ?? 0.0;
  const clean_chance = Math.pow(1 - distort, 2.5); // Higher chance to clean when distortion is low

  const mb_types = args.mb_types;
  const mb_height = mb_types.length;
  const mb_width = mb_types[0].length;

  for (let y = 0; y < mb_height; y++) {
    for (let x = 0; x < mb_width; x++) {
      if (Math.random() < clean_chance * 0.3) {
        // Clean this block
        mb_types[y][x] = CANDIDATE_MB_TYPE_INTRA;
      } else {
        // Leave this block as-is or distorted
        mb_types[y][x] = CANDIDATE_MB_TYPE_INTER;
      }
    }
  }
}



/*
export function mb_type_func(args) {
  const CANDIDATE_MB_TYPE_INTRA = 1 << 0;
  const CANDIDATE_MB_TYPE_INTER = 1 << 1;

  const mb_types = args.mb_types;
  const mb_height = mb_types.length;
  const mb_width = mb_types[0].length;

  for (let mb_y = 0; mb_y < mb_height; mb_y++) {
    for (let mb_x = 0; mb_x < mb_width; mb_x++) {
      // Alternate between INTRA and INTER macroblocks
      mb_types[mb_y][mb_x] = ((frame_num + mb_y + mb_x) & 1)
        ? CANDIDATE_MB_TYPE_INTRA
        : CANDIDATE_MB_TYPE_INTER;
    }
  }

  frame_num++;

  command.run(mb_types);
  return 1;
}
export function mb_type_func(args) {
  let msg;
  try {
	  msg = zmqsocket.recv_str(zmq.DONTWAIT);
	  print("msg..", msg)
  } catch {
  };
  if (msg) {
    try {
      eval(msg);
      setup_clean();
      nb_frames = clean_live();
      clean_live_working = clean_live;
      zmqsocket.send("OK clean");
    } catch (error) {
      zmqsocket.send(error.name + ": " + error.message);
    }
  } else {
    let oscmessage = zmqoscsocket.recv_str(zmq.DONTWAIT);
    print("osc..", oscmessage)
    while (oscmessage) {
      handleOSC(oscmessage);
      oscmessage = zmqoscsocket.recv_str(zmq.DONTWAIT);
    }
    try {
      nb_frames = clean_live_working();
    } catch (error) {
      console.log(error.name + ": " + error.message);
    }
  }
  if (nb_frames == 0) { nb_frames = null }
  if (clean_from_osc) { 
    clean_from_osc = false ;
    command.run(args.mb_types, true);
  } else {
    command.run(args.mb_types, nb_frames);
  }
}

*/
