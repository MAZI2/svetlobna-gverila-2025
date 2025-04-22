(
s.options.device = "loopcombo";
s.options.sampleRate = 44100;
s.options.hardwareBufferSize = 1024;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

s.waitForBoot {
  {
    var input = SoundIn.ar([0, 1]);  // stereo input
    Out.ar(0, input);                // stereo passthrough
  }.play;
};
)

