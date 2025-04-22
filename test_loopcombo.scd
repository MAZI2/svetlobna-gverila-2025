(
s.options.device = "loopcombo";
s.options.sampleRate = 44100;
s.options.hardwareBufferSize = 1024;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

SynthDef(\heavyReverb, {
    var in, fx;
    in = SoundIn.ar([0, 1]);
    // Extremely strong reverb effect
    fx = FreeVerb.ar(in, mix: 1.0, room: 0.99, damp: 0.2);
    Out.ar(0, fx);
}).add;

s.waitForBoot {
    Synth(\heavyReverb);
};
)

