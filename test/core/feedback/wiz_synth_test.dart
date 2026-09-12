import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/wiz_synth.dart';

/// The floor for "this kind makes a sound at all". Not a spec number and not
/// a level to tune to: it only guards against a render that comes back
/// silent. The quietest kind, detent — noise alone at the spec's gain .02 —
/// measures 0.0105, so there is room to spare.
const double nonSilentPeak = 0.005;

/// The loudest sample in a rendered buffer.
double peakOf(Float32List pcm) =>
    pcm.fold<double>(0, (p, s) => s.abs() > p ? s.abs() : p);

/// The buffer's length in milliseconds.
int msOf(FeedbackKind kind) =>
    (WizSynth.render(kind).length * 1000 / WizSynth.sampleRate).round();

void main() {
  test('every kind has a recipe', () {
    for (var kind in FeedbackKind.values) {
      expect(WizSynth.recipes[kind], isNotNull, reason: '$kind has no recipe');
      expect(WizSynth.recipes[kind], isNotEmpty, reason: '$kind has no voice');
    }
    expect(WizSynth.recipes, hasLength(FeedbackKind.values.length));
  });

  test('every kind renders a short, bounded, audible buffer', () {
    // Spec §13: "nothing longer than 150 ms", at 44.1 kHz.
    const longest = WizSynth.sampleRate * 150 ~/ 1000;
    for (var kind in FeedbackKind.values) {
      var pcm = WizSynth.render(kind);
      expect(
        pcm.length,
        greaterThan(WizSynth.sampleRate ~/ 100),
        reason: '$kind too short',
      );
      expect(pcm.length, lessThanOrEqualTo(longest), reason: '$kind too long');
      var peak = peakOf(pcm);
      expect(peak, lessThanOrEqualTo(1.0), reason: '$kind clips');
      expect(peak, greaterThan(nonSilentPeak), reason: '$kind is silent');
    }
  });

  test('the master gain is in the samples', () {
    // reject is a single sawtooth at the spec's gain .05, so its peak lands
    // just under gain × masterGain: 0.04303 today, and 0.04781 — over the
    // bound below — if render stopped applying the master gain.
    const rejectGain = 0.05;
    var peak = peakOf(WizSynth.render(FeedbackKind.reject));
    expect(peak, lessThanOrEqualTo(rejectGain * WizSynth.masterGain));
    expect(peak, greaterThan(rejectGain * WizSynth.masterGain * 0.5));
  });

  test('durations follow the recipes', () {
    expect(msOf(FeedbackKind.detent), closeTo(6 + 20, 2));
    expect(msOf(FeedbackKind.press), closeTo(45 + 20, 2));
    expect(msOf(FeedbackKind.power), closeTo(90 + 20, 2));
    expect(msOf(FeedbackKind.confirm), closeTo(55 + 70 + 20, 2));
    expect(msOf(FeedbackKind.reject), closeTo(120 + 20, 2));
  });

  test('rendering is deterministic', () {
    expect(
      WizSynth.renderWav(FeedbackKind.tick),
      WizSynth.renderWav(FeedbackKind.tick),
    );
  });

  test('the WAV header describes 16-bit mono at 44.1 kHz', () {
    var wav = WizSynth.renderWav(FeedbackKind.tick);
    var samples = WizSynth.render(FeedbackKind.tick).length;
    var view = ByteData.sublistView(wav);
    String ascii(int at) => String.fromCharCodes(wav.sublist(at, at + 4));

    expect(wav, hasLength(44 + samples * 2));
    expect(ascii(0), 'RIFF');
    expect(view.getUint32(4, Endian.little), 36 + samples * 2);
    expect(ascii(8), 'WAVE');
    expect(ascii(12), 'fmt ');
    expect(view.getUint32(16, Endian.little), 16, reason: 'fmt chunk size');
    expect(view.getUint16(20, Endian.little), 1, reason: 'PCM');
    expect(view.getUint16(22, Endian.little), 1, reason: 'mono');
    expect(view.getUint32(24, Endian.little), WizSynth.sampleRate);
    expect(
      view.getUint32(28, Endian.little),
      WizSynth.sampleRate * 2,
      reason: 'byte rate',
    );
    expect(view.getUint16(32, Endian.little), 2, reason: 'block align');
    expect(view.getUint16(34, Endian.little), 16, reason: 'bits per sample');
    expect(ascii(36), 'data');
    expect(view.getUint32(40, Endian.little), samples * 2);
  });

  test('samples are little-endian 16-bit signed PCM', () {
    for (var kind in FeedbackKind.values) {
      var pcm = WizSynth.render(kind);
      var view = ByteData.sublistView(WizSynth.renderWav(kind));
      for (var i = 0; i < pcm.length; i++) {
        expect(
          view.getInt16(44 + i * 2, Endian.little),
          (pcm[i] * 32767).round(),
          reason: '$kind sample $i',
        );
      }
    }
  });
}
