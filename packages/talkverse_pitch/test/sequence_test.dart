import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:talkverse_pitch/talkverse_pitch.dart';
import 'package:test/test.dart';

const sr = 16000;

/// 이어 말할 때의 음절 모양(평소 음높이 기준 반음). 3h = 반3성, 0 = 경성.
const shapes = <String, List<List<double>>>{
  '1': [[0, 3], [1, 3]],
  '2': [[0, -1], [1, 3]],
  '3': [[0, -1], [0.5, -5], [1, -0.5]],
  '3h': [[0, -2], [1, -5]],
  '4': [[0, 4], [1, -2]],
  '0': [[0, -1], [1, -2]],
};

/// 낱말 합성. [gap] = true 면 음절 사이에 무성 자음(60ms 무음), false 면 유성음으로 이어지고 세기만 꺼진다.
Float64List word(double medianHz, List<String> syl,
    {required bool gap, int seed = 1, double scale = 1, List<double>? secs, bool dip = true}) {
  final rnd = math.Random(seed);
  final out = <double>[];
  void silence(double sec) => out.addAll(List.filled((sec * sr).round(), 0.0));
  silence(0.1);
  var phase = 0.0;
  for (var s = 0; s < syl.length; s++) {
    final path = shapes[syl[s]]!;
    final n = ((secs?[s] ?? (syl[s] == '0' ? 0.14 : 0.26)) * sr).round();
    for (var i = 0; i < n; i++) {
      final p = i / (n - 1);
      var k = 0;
      while (k + 1 < path.length - 1 && path[k + 1][0] < p) {
        k++;
      }
      final a = ((p - path[k][0]) / (path[k + 1][0] - path[k][0])).clamp(0.0, 1.0);
      final st = scale * (path[k][1] + (path[k + 1][1] - path[k][1]) * a);
      phase += 2 * math.pi * medianHz * math.pow(2, st / 12) / sr;
      var v = 0.0;
      for (var h = 1; h <= 5; h++) {
        v += math.sin(phase * h) / h;
      }
      final edge = math.min(i, n - 1 - i) / (0.04 * sr);
      final inner = !dip && ((s > 0 && i < n ~/ 2) || (s < syl.length - 1 && i >= n ~/ 2));
      final env = gap ? math.min(1.0, edge / 0.5) : (inner ? 1.0 : 0.3 + 0.7 * math.min(1.0, edge));
      out.add(0.3 * v * env);
    }
    if (gap && s < syl.length - 1) silence(0.06);
  }
  silence(0.1);
  return Float64List.fromList([for (final v in out) v + 0.01 * (rnd.nextDouble() * 2 - 1)]);
}

/// 사전 성조 → 합성에 쓸 모양(변조 적용).
List<String> spoken(List<int> tones) => [
      for (var i = 0; i < tones.length; i++)
        if (tones[i] == 3 && i + 1 < tones.length)
          (tones[i + 1] == 3 ? '2' : '3h')
        else
          '${tones[i]}'
    ];

PitchTrack trackOf(List<String> syl, double median,
        {required bool gap, int seed = 1, double scale = 1}) =>
    const PitchTracker(sampleRate: sr)
        .track(word(median, syl, gap: gap, seed: seed, scale: scale));

/// 합성 낱말로 만든 작은 본보기 모델(견주기 장치가 도는지만 본다 — 실제 판정은 모듈에 든
/// 원어민 본보기가 하고, 그 정확도는 tool/build_model.dart eval 로 잰다).
final ToneWordModel synthModel = () {
  final ex = <String, List<Float64List>>{};
  for (var a = 1; a <= 4; a++) {
    for (var b = 0; b <= 4; b++) {
      final say = spoken([a, b]);
      final cls = '${say[0][0]}-${say[1][0]}';
      for (final median in [110.0, 160.0, 230.0]) {
        for (final gap in [true, false]) {
          (ex[cls] ??= []).add(wordContour(trackOf(say, median, gap: gap))!);
        }
      }
    }
  }
  return ToneWordModel(ex);
}();

SequenceScore run(List<int> tones, double median,
    {required bool gap, List<String>? say, double scale = 1, ToneWordModel? model}) {
  final track = trackOf(say ?? spoken(tones), median, gap: gap, seed: 7, scale: scale);
  return scoreMandarinSequence(track, tones,
      speakerMedianHz: median, wordModel: model ?? synthModel);
}

void main() {
  test('변조: 3-3, 반3성, 不', () {
    expect(surfaceTones([3, 3]).map((t) => t.accepted).toList(), [{2}, {3}]);
    expect(surfaceTones([3, 3, 3]).map((t) => t.accepted).toList(), [{2, 3}, {2}, {3}]);
    expect(surfaceTones([3, 1]).first.half, isTrue);
    expect(surfaceTones([3]).first.half, isFalse);
    expect(surfaceTones([4, 4], hanzi: ['不', '是']).first.accepted, {2});
    expect(surfaceTones([4, 4], hanzi: ['再', '见']).first.accepted, {4});
    expect(surfaceTones([2, 0]).last.neutral, isTrue);
  });

  for (final gap in [true, false]) {
    final kind = gap ? '무성 자음으로 끊김' : '유성음으로 이어짐';
    test('2음절 16칸 + 경성 4칸 ($kind)', () {
      for (final median in [120.0, 210.0]) {
        for (var a = 1; a <= 4; a++) {
          for (var b = 0; b <= 4; b++) {
            final r = run([a, b], median, gap: gap);
            expect(r.valid, isTrue, reason: '$a-$b $median');
            expect(r.method, 'word');
            expect(r.syllables.length, 2);
            expect(r.passed, isTrue,
                reason: '$a-$b $median → ${[for (final s in r.syllables) '${s.verdict.name} ${s.tone?.scores}']}');
          }
        }
      }
    });

    test('3·4음절 ($kind)', () {
      for (final tones in [
        [4, 1, 2], [1, 3, 4], [3, 3, 3], [2, 4, 0], [3, 2, 1],
        [1, 2, 3, 4], [4, 4, 2, 1], [2, 3, 3, 4], [3, 1, 4, 2],
      ]) {
        final r = run(tones, 170, gap: gap);
        expect(r.syllables.length, tones.length, reason: '$tones');
        expect(r.passed, isTrue,
            reason: '$tones → ${[for (final s in r.syllables) '${s.verdict.name} ${s.tone?.scores}']}');
      }
    });
  }

  test('틀린 음절만 짚는다', () {
    // 今天(1-1)을 1-4 로 말함 → 둘째만 불통.
    final r = run([1, 1], 180, gap: true, say: ['1', '4']);
    expect(r.syllables[0].verdict, ToneVerdict.good);
    expect(r.syllables[1].verdict, isNot(ToneVerdict.good));
    expect(r.syllables[1].tone!.heard, 4);
    expect(r.syllables[1].tone!.hints, ['keep_level']);
    // 你好(3-3)를 변조 없이 낮게-낮게 → 첫째 불통.
    final r2 = run([3, 3], 180, gap: false, say: ['3h', '3']);
    expect(r2.syllables[0].verdict, isNot(ToneVerdict.good));
    expect(r2.passed, isFalse);
  });

  test('목소리 높이·오르내림 폭은 보지 않는다', () {
    for (final tones in [[1, 1], [4, 4], [2, 3], [3, 1], [4, 0]]) {
      for (final median in [95.0, 260.0]) {
        for (final scale in [0.6, 1.4]) {
          final r = run(tones, median, gap: false, scale: scale);
          expect(r.passed, isTrue, reason: '$tones $median ×$scale');
        }
      }
    }
    // 평소 음높이를 엉뚱하게 줘도(기기에서 어림이 흔들릴 때) 판정은 같다.
    final track = trackOf(['1', '1'], 150, gap: false, seed: 3);
    for (final ref in [90.0, 150.0, 240.0]) {
      expect(
          scoreMandarinSequence(track, [1, 1], speakerMedianHz: ref, wordModel: synthModel).passed,
          isTrue);
    }
  });

  test('본보기 모델: 글로 옮겼다 되읽어도 같은 판정', () {
    final back = ToneWordModel.fromJson(
        jsonDecode(jsonEncode(synthModel.toJson())) as Map<String, dynamic>);
    expect(back.exemplars.keys.toSet(), synthModel.exemplars.keys.toSet());
    expect(back.exemplars.length, 19); // 3-3 은 2-3 과 같은 꼴
    for (final tones in [[1, 4], [3, 2], [2, 0], [4, 3]]) {
      expect(run(tones, 170, gap: true, model: back).passed, isTrue);
      expect(run(tones, 170, gap: true, model: back, say: ['4', '1']).passed, isFalse);
    }
  });

  test('모듈에 든 원어민 본보기', () {
    final m = mandarinWordModel;
    expect(m.exemplars.length, 19);
    // 본보기 하나를 빼고 나머지와 견주면 제 조합으로 통과해야 한다(자료가 깨끗한지).
    var ok = 0, n = 0;
    m.exemplars.forEach((cls, list) {
      expect(list.length, greaterThanOrEqualTo(15), reason: cls);
      final acc = [for (final t in cls.split('-')) {int.parse(t)}];
      for (final e in list) {
        final w = WordMatch(m.distances(e, skip: e), slack: m.slack);
        n++;
        if (judgeToneWord(w, acc).passed) ok++;
      }
    });
    expect(ok / n, greaterThan(0.85), reason: '$ok/$n');
  });

  test('세 음절 이상·모델이 없으면 음절별 특징으로', () {
    expect(run([1, 4], 170, gap: true, model: ToneWordModel(const {})).method, 'rules');
    final x = trackOf(['4', '1', '2'], 170, gap: true);
    expect(scoreMandarinSequence(x, [4, 1, 2]).method, 'rules');
  });

  test('세기가 안 꺼져도 음높이를 다시 올리는 곳에서 음절을 나눈다', () {
    // 现在(4-4)처럼 붙여 말함: 첫 음절이 짧고(0.18초) 둘째가 길다(0.34초) — 가운데서 자르면 틀린다.
    for (final first in ['4', '3h']) {
      for (final second in ['4', '1']) {
        final x = word(170, [first, second], gap: false, secs: [0.18, 0.34], dip: false, seed: 5);
        final parts = splitSyllables(const PitchTracker(sampleRate: sr).track(x), 2);
        expect(parts.length, 2);
        final cut = parts[1].frames.first.time;
        expect(cut, closeTo(0.1 + 0.18, 0.03), reason: '$first-$second');
      }
    }
  });

  test('말소리가 없으면 무효', () {
    final track = const PitchTracker(sampleRate: sr).track(Float64List(sr));
    expect(scoreMandarinSequence(track, [1, 2]).valid, isFalse);
  });

  test('문장 비교: 느리게 말해도 같은 모양이면 통과, 다른 모양이면 낮음', () {
    Contour c(List<String> syl, double median, {int seed = 1}) {
      final track = const PitchTracker(sampleRate: sr).track(word(median, syl, gap: false, seed: seed));
      return Contour.fromTrack(track, refHz: median, points: 50)!;
    }

    final ref = c(['2', '3h', '4', '1', '4'], 220);
    final same = c(['2', '3h', '4', '1', '4'], 125, seed: 5);
    final other = c(['4', '1', '2', '4', '2'], 125, seed: 5);
    expect(compareContoursWarped(same, ref).score, greaterThan(0.8));
    expect(compareContoursWarped(other, ref).score, lessThan(0.4));
  });
}
