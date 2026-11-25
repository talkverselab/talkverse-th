import 'dart:math' as math;
import 'dart:typed_data';

import 'package:talkverse_pitch/talkverse_pitch.dart';
import 'package:test/test.dart';

const sr = 16000;

/// 합성음: [path] = (위치 0~1, 기준 대비 반음) 꺾은선, 배음 5개 + 잡음, 앞뒤 무음 0.1초.
Float64List synth(double medianHz, List<List<double>> path,
    {double seconds = 0.4, double noise = 0.02, int seed = 1}) {
  final rnd = math.Random(seed);
  final pad = (0.1 * sr).round();
  final n = (seconds * sr).round();
  final out = Float64List(n + 2 * pad);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final p = i / (n - 1);
    var k = 0;
    while (k + 1 < path.length - 1 && path[k + 1][0] < p) {
      k++;
    }
    final a = (p - path[k][0]) / (path[k + 1][0] - path[k][0]);
    final st = path[k][1] + (path[k + 1][1] - path[k][1]) * a.clamp(0.0, 1.0);
    final f = medianHz * math.pow(2, st / 12);
    phase += 2 * math.pi * f / sr;
    var v = 0.0;
    for (var h = 1; h <= 5; h++) {
      v += math.sin(phase * h) / h;
    }
    final fade = math.min(1.0, math.min(i, n - 1 - i) / (0.02 * sr));
    out[pad + i] = 0.3 * v * fade;
  }
  for (var i = 0; i < out.length; i++) {
    out[i] += noise * (rnd.nextDouble() * 2 - 1);
  }
  return out;
}

final tones = <int, List<List<double>>>{
  1: [[0, 3], [1, 3]],
  2: [[0, -1], [1, 4]],
  3: [[0, 0], [0.5, -5], [1, 0.5]],
  4: [[0, 5], [1, -4]],
};

Contour contourOf(Float64List x, double medianHz) {
  final track = const PitchTracker(sampleRate: sr).track(x);
  return Contour.fromTrack(track, refHz: medianHz)!;
}

void main() {
  test('고른 음높이를 1.5% 안에서 잰다', () {
    for (final hz in [110.0, 220.0, 330.0]) {
      final track = const PitchTracker(sampleRate: sr).track(synth(hz, [[0, 0], [1, 0]]));
      final v = track.voicedHz..sort();
      expect(v.length, greaterThan(20));
      expect((v[v.length ~/ 2] - hz).abs() / hz, lessThan(0.015), reason: '$hz');
    }
  });

  test('오르는 곡선의 시작·끝 높이', () {
    final c = contourOf(synth(200, [[0, -2], [1, 4]]), 200);
    expect(c.start, closeTo(-1.6, 0.8));
    expect(c.end, closeTo(3.6, 0.8));
    expect(c.maxPos, greaterThan(0.8));
  });

  test('무음·잡음만 있으면 곡선 없음', () {
    final rnd = math.Random(3);
    final x = Float64List.fromList(List.generate(sr ~/ 2, (_) => 0.02 * (rnd.nextDouble() * 2 - 1)));
    final track = const PitchTracker(sampleRate: sr).track(x);
    expect(Contour.fromTrack(track, refHz: 200), isNull);
    expect(Contour.fromTrack(const PitchTracker(sampleRate: sr).track(Float64List(sr ~/ 2)), refHz: 200), isNull);
  });

  for (final median in [120.0, 220.0]) {
    test('성조 네 개를 가른다 (평소 음높이 $median Hz)', () {
      for (final t in tones.keys) {
        final s = scoreMandarinTone(contourOf(synth(median, tones[t]!), median), t);
        expect(s.heard, t, reason: '목표 $t 점수 ${s.scores}');
        expect(s.verdict, ToneVerdict.good, reason: '목표 $t 점수 ${s.scores}');
      }
    });
  }

  test('다른 성조로 말하면 통과하지 않는다', () {
    for (final target in tones.keys) {
      for (final said in tones.keys) {
        if (said == target) continue;
        final s = scoreMandarinTone(contourOf(synth(180, tones[said]!), 180), target);
        expect(s.verdict, isNot(ToneVerdict.good), reason: '목표 $target, 말한 것 $said, ${s.scores}');
      }
    }
  });

  test('문장 안의 낮은 3성(21)도 3성으로', () {
    final s = scoreMandarinTone(contourOf(synth(190, [[0, -2], [1, -5]]), 190), 3);
    expect(s.heard, 3, reason: '${s.scores}');
  });

  test('덜 올린 2성은 힌트가 나온다', () {
    final s = scoreMandarinTone(contourOf(synth(200, [[0, 0], [1, 2]]), 200), 2);
    expect(s.verdict, isNot(ToneVerdict.good));
    expect(s.hints, contains('end_higher'));
  });

  test('모양 비교: 음역이 달라도 같은 모양이면 높은 점수', () {
    final ref = contourOf(synth(220, tones[2]!), 220);
    final same = contourOf(synth(120, tones[2]!, seed: 7), 120);
    final opposite = contourOf(synth(120, tones[4]!, seed: 7), 120);
    expect(compareContours(same, ref).score, greaterThan(0.8));
    expect(compareContours(opposite, ref).score, lessThan(0.3));
  });

  test('음역: 5도 눈금과 PCM 변환', () {
    final r = SpeakerRange.fromHz([for (var i = 0; i <= 100; i++) 100.0 + i]);
    expect(r.level5(r.lowHz), closeTo(1, 1e-9));
    expect(r.level5(r.highHz), closeTo(5, 1e-9));
    expect(SpeakerRange.fromJson(r.toJson()).medianHz, r.medianHz);
    final f = pcm16ToFloat(Uint8List.fromList([0x00, 0x40, 0x00, 0xC0]));
    expect(f[0], closeTo(0.5, 1e-9));
    expect(f[1], closeTo(-0.5, 1e-9));
  });
}
