(
s.options.device = "loopcombo";
s.options.sampleRate = 44100;
s.options.hardwareBufferSize = 1024;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

s.waitForBoot({
    Ndef(\liveDecimate, {
        var input = SoundIn.ar([0, 1]);
        var gmin = \gmin.kr(1);  // probability gate lower threshold
        var offset = \offset.kr(0);  // audio dropout threshold
        var gmax = 1.0;

		// probability modulator
        var gendy = Gendy1.ar(
            minfreq: 300, maxfreq: 400,
            ampdist: 1, durdist: 1,
            adparam: 1, ddparam: 1.6
        ).range(gmin, gmax)-offset;

        var trig = CoinGate.ar(gendy, Impulse.ar(s.sampleRate / 2));

        Latch.ar(input, trig)
    }).play;

    OSCdef(\setDistort, { |msg|
        var distort = msg[1].clip(0.0, 1.0);

        var gmin = (1.0 - distort);

        // audio dropouts
        var offset = if(distort > 0.7, {
            distort.linlin(0.7, 1, 0, 0.6)
        }, {
            0.0
        });

        Ndef(\liveDecimate).set(\gmin, gmin, \offset, offset);

        ("🎛️ Distort: %.2f → gmin: %.2f | offset: %.2f"
            .format(distort, gmin, offset)).postln;
    }, '/set/distort');
});
)
