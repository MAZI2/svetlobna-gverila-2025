(
s.options.device = "ALSA : loopcombo";
s.options.sampleRate = 44100;
s.options.hardwareBufferSize = 1024;
s.options.numInputBusChannels = 1;
s.options.numOutputBusChannels = 1;

s.waitForBoot {
    {
        var input = SoundIn.ar(0);
        Out.ar(0, input);  // passthrough
    }.play;
};
)

