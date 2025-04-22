(
s.options.device = "hw:3,0";
s.options.numOutputBusChannels = 1;
s.options.sampleRate = 44100;

s.waitForBoot {
  {
    SinOsc.ar(440, 0, 0.2)
  }.play;
};
)

