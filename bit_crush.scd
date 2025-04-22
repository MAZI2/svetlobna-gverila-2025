(
s.options.device = "loopcombo";
s.options.sampleRate = 44100;
s.options.hardwareBufferSize = 1024;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

s.waitForBoot({
    // Define and play live input processing
    Ndef(\liveDecimate, {
        var input = SoundIn.ar([0, 1]);

        // Apply decimator to input
        Decimator.ar(
            in: input,
            rate: \sampleRate.kr(44100).max(1),
            bits: \bitDepth.kr(12).max(1)
        )
    }).play;

    // OSC handler for sample rate
    OSCdef(\setSampleRate, { |msg|
        "OSC Received: %".format(msg).postln;
        Ndef(\liveDecimate).set(\sampleRate, msg[1].clip(100, 44100));
    }, '/set/sampleRate');

    // OSC handler for bit depth
    OSCdef(\setBitDepth, { |msg|
        "OSC Received: %".format(msg).postln;
        Ndef(\liveDecimate).set(\bitDepth, msg[1].clip(5, 24).round(1));
    }, '/set/bitDepth');
});
)

