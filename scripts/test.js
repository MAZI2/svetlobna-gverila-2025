export function setup(args) {
  args.features = ["mv"];  // enable motion vectors
}

export function glitch_frame(frame) {
  for (let mb of frame.macroblocks) {
    if (Math.random() < 0.1) {
      mb.mb_type = "Intra";
      mb.qscale = 25;
    }
  }
}

