(
s.options.device = "loopcombo";
s.options.sampleRate = 44100;
s.options.hardwareBufferSize = 1024;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

s.waitForBoot({
    Ndef(\liveDecimate, {
        var input = SoundIn.ar([0, 1]);

        var bitDepth = \bitDepth.kr(12).max(1);
        var sampleRate = \sampleRate.kr(44100).max(1);

        Decimator.ar(
            in: input,
            rate: sampleRate,
            bits: bitDepth
        )
    }).play;

    OSCdef(\setDistort, { |msg|
        var distort, shaped, bits, rate;

	distort = msg[1].clip(0.0, 1.0);
	shaped = pow(distort, 0.8);  // steeper ramp-up

	bits = (5 + (12 * (1.0 - shaped))).round(1);
	rate = (10000 + (34100 * (1.0 - shaped))).round;
	
	Ndef(\liveDecimate).set(\bitDepth, bits, \sampleRate, rate);
	("🎛️ Distort %.2f → shaped: %.2f → bits: %, rate: %"
	    .format(distort, shaped, bits, rate)).postln;
    }, '/set/distort');
});
)

