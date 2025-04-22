(
s.options.device = "hw:2,0";  // or try leaving this unset for default PortAudio device
s.options.inDevice = "";      // explicitly disable input
s.options.numInputBusChannels = 0;
s.options.numOutputBusChannels = 2;

s.options.sampleRate = 44100;
s.options.blockSize = 64;
s.options.hardwareBufferSize = 1024;

s.waitForBoot {
    {
        SinOsc.ar(440, 0, 0.1) ! 2
    }.play;
};
)

