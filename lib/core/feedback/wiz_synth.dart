import 'dart:math' as math;
import 'dart:typed_data';

import 'feedback_kind.dart';

/// The three oscillator shapes the recipes ask for (spec §13, `tone(f, f2,
/// dur, gain, type, at)`).
enum Wave { sine, triangle, sawtooth }

/// One voice of a recipe: either a [NoiseSpec] burst or a [ToneSpec].
///
/// Every duration and offset is in seconds; the spec's table is in
/// milliseconds, so 12 ms reads as `0.012` below. Gains are the spec's
/// linear amplitudes, before [WizSynth.masterGain].
sealed class VoiceSpec {
  /// Seconds from the start of the sound to the start of this voice.
  double get at;

  /// The voice's own length in seconds.
  double get dur;

  /// Peak linear amplitude.
  double get gain;

  const VoiceSpec();
}

/// Spec §13: `noise(dur, cut, gain)` — "white noise with a linear decay
/// through a one-pole low-pass at `cut` Hz". The contact of a key.
class NoiseSpec extends VoiceSpec {
  @override
  final double at;
  @override
  final double dur;
  @override
  final double gain;

  /// The one-pole low-pass corner, in hertz.
  final double cut;

  const NoiseSpec(this.dur, this.cut, this.gain, {this.at = 0});
}

/// Spec §13: `tone(f, f2, dur, gain, type, at)` — an oscillator with an
/// exponential frequency ramp `f → f2` over `dur` and an exponential gain
/// envelope. The body under the contact.
class ToneSpec extends VoiceSpec {
  @override
  final double at;
  @override
  final double dur;
  @override
  final double gain;

  /// Starting frequency in hertz.
  final double f;

  /// Frequency at the end of the ramp, or null to hold [f].
  final double? f2;

  final Wave type;

  const ToneSpec(
    this.f,
    this.f2,
    this.dur,
    this.gain, {
    this.at = 0,
    this.type = Wave.sine,
  });
}

/// Sound is generated, not sampled: the app ships no audio files (spec
/// §11.4). Each of the nine kinds is a short recipe of noise and tone
/// voices, rendered once at startup into 16-bit mono PCM at 44.1 kHz.
class WizSynth {
  WizSynth._();

  /// Spec §13: "rendered once at startup into in-memory 16-bit mono WAV at
  /// 44.1 kHz".
  static const int sampleRate = 44100;

  /// Spec §13: "Master gain 0.9". Applied once, here in [render], so that
  /// every player downstream can play the sources at their own volume 1.
  static const double masterGain = 0.9;

  /// Spec §13, the tone envelope: "0.0001 → gain in 4 ms → 0.0001 at `dur`
  /// (exponential)". [attack] is that 4 ms and [floor] that 0.0001, both in
  /// the units the spec uses (seconds, linear amplitude).
  static const double attack = 0.004;
  static const double floor = 0.0001;

  /// Silence appended after the last voice ends, in seconds. Not from the
  /// spec: it is headroom so that a tone still a [floor] above zero at `dur`
  /// is not truncated into a click at the buffer's edge. 20 ms keeps the
  /// longest kind (confirm, 125 ms of voices) at 145 ms, inside the spec's
  /// "nothing longer than 150 ms".
  static const double tail = 0.02;

  /// The synthesis table of spec §13, one entry per [FeedbackKind], in the
  /// spec's own order of arguments: noise `(dur, cut, gain)`, tone `(f, f2,
  /// dur, gain, {at, type})`. Milliseconds there are seconds here.
  static const Map<FeedbackKind, List<VoiceSpec>> recipes = {
    // noise 12 ms cut 2400 gain .05; sine 200→120 45 ms gain .05
    FeedbackKind.press: [
      NoiseSpec(0.012, 2400, 0.05),
      ToneSpec(200, 120, 0.045, 0.05),
    ],
    // noise 8 ms cut 4200 gain .022
    FeedbackKind.release: [NoiseSpec(0.008, 4200, 0.022)],
    // noise 10 ms cut 3200 .05; sine 320→560 55 ms .05
    FeedbackKind.toggleOn: [
      NoiseSpec(0.010, 3200, 0.05),
      ToneSpec(320, 560, 0.055, 0.05),
    ],
    // noise 10 ms cut 2600 .045; sine 300→170 55 ms .045
    FeedbackKind.toggleOff: [
      NoiseSpec(0.010, 2600, 0.045),
      ToneSpec(300, 170, 0.055, 0.045),
    ],
    // noise 9 ms cut 3600 .035; triangle 520 30 ms .03
    FeedbackKind.tick: [
      NoiseSpec(0.009, 3600, 0.035),
      ToneSpec(520, null, 0.03, 0.03, type: Wave.triangle),
    ],
    // noise 6 ms cut 5200 .02 — the smallest sound in the product.
    FeedbackKind.detent: [NoiseSpec(0.006, 5200, 0.02)],
    // noise 14 ms cut 2200 .055; sine 150→90 90 ms .06
    FeedbackKind.power: [
      NoiseSpec(0.014, 2200, 0.055),
      ToneSpec(150, 90, 0.09, 0.06),
    ],
    // triangle 660 50 ms .04; triangle 990 70 ms .035 at 55 ms
    FeedbackKind.confirm: [
      ToneSpec(660, null, 0.05, 0.04, type: Wave.triangle),
      ToneSpec(990, null, 0.07, 0.035, at: 0.055, type: Wave.triangle),
    ],
    // sawtooth 210→140 120 ms .05
    FeedbackKind.reject: [ToneSpec(210, 140, 0.12, 0.05, type: Wave.sawtooth)],
  };

  /// Renders [kind] to mono float samples in −1..1, master gain included.
  ///
  /// Deterministic: the noise generator is seeded from the kind, so a given
  /// kind always sounds exactly the same and its WAV can be compared byte
  /// for byte in tests.
  static Float32List render(FeedbackKind kind) {
    var voices = recipes[kind]!;
    var end =
        voices.fold<double>(0, (m, v) => math.max(m, v.at + v.dur)) + tail;
    var out = Float32List((end * sampleRate).round());
    var random = math.Random(kind.index + 1);
    for (var voice in voices) {
      var start = (voice.at * sampleRate).round();
      var n = (voice.dur * sampleRate).round();
      switch (voice) {
        case NoiseSpec():
          // The spec gives noise its own envelope — "white noise with a
          // linear decay" — so the tone's 4 ms exponential does not apply
          // here. One-pole low-pass, RC form, at the recipe's corner.
          var rc = 1 / (2 * math.pi * voice.cut);
          var dt = 1 / sampleRate;
          var alpha = dt / (rc + dt);
          var y = 0.0;
          for (var i = 0; i < n && start + i < out.length; i++) {
            var x = (random.nextDouble() * 2 - 1) * (1 - i / n);
            y += alpha * (x - y);
            out[start + i] += y * voice.gain;
          }
        case ToneSpec():
          var phase = 0.0;
          for (var i = 0; i < n && start + i < out.length; i++) {
            var t = i / sampleRate;
            // Exponential ramp f → f2 over dur; a null f2 holds f.
            var f = voice.f2 == null
                ? voice.f
                : voice.f * math.pow(voice.f2! / voice.f, t / voice.dur);
            phase += f / sampleRate;
            var p = phase - phase.floorToDouble();
            var sample = switch (voice.type) {
              Wave.sine => math.sin(2 * math.pi * p),
              Wave.triangle => 2 * (2 * p - 1).abs() - 1,
              Wave.sawtooth => 2 * p - 1,
            };
            // Spec §13: floor → gain over `attack`, then back to floor at
            // `dur`, both legs exponential.
            var env = t < attack
                ? floor * math.pow(voice.gain / floor, t / attack)
                : voice.gain *
                      math.pow(
                        floor / voice.gain,
                        (t - attack) / math.max(1e-6, voice.dur - attack),
                      );
            out[start + i] += sample * env;
          }
      }
    }
    for (var i = 0; i < out.length; i++) {
      out[i] = (out[i] * masterGain).clamp(-1.0, 1.0);
    }
    return out;
  }

  /// [render] wrapped in a canonical 44-byte RIFF/WAVE header: PCM, mono,
  /// 16-bit, [sampleRate]. Ready for any player that loads from memory.
  static Uint8List renderWav(FeedbackKind kind) {
    var pcm = render(kind);
    var bytes = pcm.length * 2;
    var data = ByteData(44 + bytes);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + bytes, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little); // fmt chunk size
    data.setUint16(20, 1, Endian.little); // format: PCM
    data.setUint16(22, 1, Endian.little); // channels: mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    data.setUint16(32, 2, Endian.little); // block align
    data.setUint16(34, 16, Endian.little); // bits per sample
    ascii(36, 'data');
    data.setUint32(40, bytes, Endian.little);
    for (var i = 0; i < pcm.length; i++) {
      data.setInt16(44 + i * 2, (pcm[i] * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
