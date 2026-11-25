import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'mandarin.dart' show ToneVerdict;
import 'sequence.dart' show splitSyllables;
import 'tracker.dart';

/// 두 음절 낱말을 음절로 자르지 않고 통째로 견준다.
///
/// 이어 말하면 유성음(m·n·l·y·w)으로 붙은 음절은 경계가 소리 세기로 안 드러나고, 앞 성조의
/// 끝과 뒤 성조의 시작이 서로 끌려간다. 그래서 음절별 문턱 대신 「이 낱말의 음높이 흐름이
/// 어느 성조 조합의 본보기들과 가장 닮았나」를 본다(본보기 = 원어민 음성에서 뽑은 곡선).
/// 높이(목소리 높낮이)와 폭(오르내림 크기)은 빼고 모양만 견준다.

/// 낱말 전체의 음높이 흐름: 유성 칸만 이어 붙여 [points] 개로 맞추고, 평균 0·폭 1 로 고른다.
/// 폭이 [floor] 반음보다 작으면 [floor] 로 나눈다(평평한 말의 잔떨림이 부풀지 않게).
/// 유성 칸이 8개 미만이면 null.
Float64List? wordContour(PitchTrack track,
    {int points = 40, double floor = 1.5, bool align = false}) {
  // 2칸(20ms) 이하로 혼자 떨어진 유성 칸은 잡음으로 보고 버린다.
  List<double> voiced(List<PitchFrame> f) {
    final hz = <double>[];
    for (var i = 0; i < f.length;) {
      if (!f[i].voiced) {
        i++;
        continue;
      }
      var j = i;
      while (j < f.length && f[j].voiced) {
        j++;
      }
      if (j - i >= 3) {
        for (var x = i; x < j; x++) {
          hz.add(f[x].hz!);
        }
      }
      i = j;
    }
    return hz;
  }

  // align: 음절 경계를 찾아 앞 음절·뒤 음절을 같은 길이로 맞춘다(경계가 곡선 한가운데 오게).
  final List<List<double>> segs;
  if (align) {
    final parts = splitSyllables(track, 2);
    if (parts.length != 2) return null;
    segs = [for (final p in parts) voiced(p.frames)];
    if (segs.any((s) => s.length < 3)) return null;
  } else {
    segs = [voiced(track.frames)];
  }
  final hz = [for (final s in segs) ...s];
  if (hz.length < 8) return null;
  final sorted = [...hz]..sort();
  final med = sorted[sorted.length ~/ 2];
  final out = Float64List(points);
  final per = points ~/ segs.length;
  var at = 0;
  for (final seg in segs) {
    final st = [for (final h in seg) 12 * math.log(h / med) / math.ln2];
    // 3점 가운뎃값으로 튀는 점을 지운다.
    final sm = List<double>.of(st);
    for (var i = 1; i + 1 < st.length; i++) {
      final a = st[i - 1], b = st[i], c = st[i + 1];
      sm[i] = math.max(math.min(a, b), math.min(math.max(a, b), c));
    }
    for (var i = 0; i < per; i++) {
      final x = (sm.length - 1) * i / (per - 1);
      final k = math.min(x.floor(), sm.length - 2);
      out[at++] = sm[k] + (sm[k + 1] - sm[k]) * (x - k);
    }
  }
  var mean = 0.0;
  for (var i = 0; i < points; i++) {
    mean += out[i];
  }
  mean /= points;
  var v = 0.0;
  for (var i = 0; i < points; i++) {
    out[i] -= mean;
    v += out[i] * out[i];
  }
  final sd = math.max(math.sqrt(v / points), floor);
  for (var i = 0; i < points; i++) {
    out[i] /= sd;
  }
  return out;
}

/// 성조 조합별 본보기 곡선 묶음. 조합 이름은 「1-4」「3-0」 꼴(0 = 경성, 3-3 은 2-3 에 들어 있다).
class ToneWordModel {
  ToneWordModel(this.exemplars,
      {this.points = 40,
      this.floor = 1.5,
      this.band = 6,
      this.k = 3,
      this.slack = 0.1});

  /// {"points":40,"floor":1.5,"band":6,"k":3,"q":32,"classes":{"1-1":"<base64 int8>"}}
  factory ToneWordModel.fromJson(Map<String, dynamic> j) {
    final points = j['points'] as int;
    final q = (j['q'] as num).toDouble();
    final ex = <String, List<Float64List>>{};
    (j['classes'] as Map<String, dynamic>).forEach((cls, b64) {
      final raw = Int8List.sublistView(base64.decode(b64 as String));
      ex[cls] = [
        for (var o = 0; o + points <= raw.length; o += points)
          Float64List.fromList([for (var i = 0; i < points; i++) raw[o + i] / q])
      ];
    });
    return ToneWordModel(ex,
        points: points,
        floor: (j['floor'] as num).toDouble(),
        band: j['band'] as int,
        k: j['k'] as int,
        slack: (j['slack'] as num?)?.toDouble() ?? 0.1);
  }

  final Map<String, List<Float64List>> exemplars;
  final int points;
  final double floor;

  /// 시간 늘이기 허용 폭(점 개수).
  final int band;

  /// 조합마다 가장 가까운 본보기 몇 개의 평균을 그 조합과의 거리로 삼는가.
  final int k;

  /// 닮은 정도를 낼 때 두 거리에 똑같이 더하는 값 — 둘 다 아주 가까우면(거의 같은 곡선)
  /// 작은 차이가 큰 비율로 부풀지 않게 한다.
  final double slack;

  bool get isEmpty => exemplars.isEmpty;

  Map<String, dynamic> toJson({double q = 32}) => {
        'points': points,
        'floor': floor,
        'band': band,
        'k': k,
        'slack': slack,
        'q': q,
        'classes': {
          for (final e in exemplars.entries)
            e.key: base64.encode(Int8List.fromList([
              for (final x in e.value)
                for (final v in x) (v * q).round().clamp(-127, 127)
            ]).buffer.asUint8List())
        },
      };

  /// 시간을 조금 늘이고 줄여 맞춘 뒤의 차이(점당 제곱평균제곱근).
  double distance(Float64List a, Float64List b) {
    final n = points;
    const inf = double.infinity;
    var prev = Float64List(n + 1)..fillRange(0, n + 1, inf);
    var cur = Float64List(n + 1);
    prev[0] = 0;
    for (var i = 1; i <= n; i++) {
      cur.fillRange(0, n + 1, inf);
      final lo = math.max(1, i - band), hi = math.min(n, i + band);
      for (var j = lo; j <= hi; j++) {
        final d = a[i - 1] - b[j - 1];
        var best = prev[j - 1];
        if (prev[j] < best) best = prev[j];
        if (cur[j - 1] < best) best = cur[j - 1];
        cur[j] = d * d + best;
      }
      final t = prev;
      prev = cur;
      cur = t;
    }
    return math.sqrt(prev[n] / n);
  }

  /// 조합별 거리(작을수록 닮음). [skip] 은 본보기를 빼고 볼 때(자료 점검용).
  Map<String, double> distances(Float64List contour, {Float64List? skip}) {
    final out = <String, double>{};
    exemplars.forEach((cls, list) {
      final d = <double>[
        for (final e in list)
          if (!identical(e, skip)) distance(contour, e)
      ]..sort();
      if (d.isEmpty) return;
      final n = math.min(k, d.length);
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += d[i];
      }
      out[cls] = s / n;
    });
    return out;
  }
}

/// 낱말 한 번의 견준 결과.
class WordMatch {
  WordMatch(this.distances, {this.slack = 0.1}) {
    var b = distances.keys.first;
    for (final e in distances.entries) {
      if (e.value < distances[b]!) b = e.key;
    }
    best = b;
  }

  /// 조합별 거리.
  final Map<String, double> distances;
  final double slack;

  /// 가장 닮은 조합.
  late final String best;

  /// 그 조합이 가장 닮은 조합에 견주어 얼마나 닮았나 0~1(1 = 가장 닮음).
  double similarity(String cls) {
    final d = distances[cls];
    if (d == null) return 0;
    return ((distances[best]! + slack) / (d + slack)).clamp(0.0, 1.0);
  }

  /// [index] 번째 음절이 [tones] 중 하나인 조합들 가운데 가장 닮은 것의 닮은 정도.
  double syllableSimilarity(int index, Set<int> tones) {
    var s = 0.0;
    for (final cls in distances.keys) {
      if (tones.contains(int.parse(cls.split('-')[index]))) {
        s = math.max(s, similarity(cls));
      }
    }
    return s;
  }
}

WordMatch? matchToneWord(PitchTrack track, ToneWordModel model) {
  if (model.isEmpty) return null;
  final c = wordContour(track, points: model.points, floor: model.floor);
  if (c == null) return null;
  return WordMatch(model.distances(c), slack: model.slack);
}

/// 음절별 판정.
class WordJudgement {
  const WordJudgement(this.verdicts, this.heard, this.scores, this.joint);
  final List<ToneVerdict> verdicts;

  /// 가장 닮은 조합의 성조(0 = 경성).
  final List<int> heard;

  /// 음절마다 성조별 닮은 정도 0~1.
  final List<Map<int, double>> scores;

  /// 목표 조합 전체의 닮은 정도.
  final double joint;

  bool get passed => verdicts.every((v) => v == ToneVerdict.good);
}

/// [accepted] = 음절마다 통과로 치는 성조(경성은 {0}).
/// 목표 조합이 가장 닮은 조합에 견주어 [good] 이상 닮았으면 모두 통과. 아니면 음절마다
/// 「그 자리가 목표 성조인 조합 중 가장 닮은 것」으로 어느 음절이 어긋났는지 가린다.
WordJudgement judgeToneWord(WordMatch m, List<Set<int>> accepted,
    {double good = 0.75, double close = 0.55}) {
  final n = accepted.length;
  final heard = [for (final t in m.best.split('-')) int.parse(t)];
  final scores = <Map<int, double>>[
    for (var i = 0; i < n; i++)
      {
        for (final t in const [0, 1, 2, 3, 4])
          if (m.syllableSimilarity(i, {t}) > 0) t: m.syllableSimilarity(i, {t})
      }
  ];
  var joint = 0.0;
  for (final cls in m.distances.keys) {
    final t = cls.split('-');
    var ok = t.length == n;
    for (var i = 0; ok && i < n; i++) {
      ok = accepted[i].contains(int.parse(t[i]));
    }
    if (ok) joint = math.max(joint, m.similarity(cls));
  }
  if (joint >= good) {
    return WordJudgement(
        List.filled(n, ToneVerdict.good), heard, scores, joint);
  }
  final s = [for (var i = 0; i < n; i++) m.syllableSimilarity(i, accepted[i])];
  final v = [
    for (final x in s)
      x >= good
          ? ToneVerdict.good
          : (x >= close ? ToneVerdict.close : ToneVerdict.off)
  ];
  if (v.every((x) => x == ToneVerdict.good)) {
    // 따로 보면 다 맞는데 함께는 안 맞는다 — 덜 닮은 쪽을 「거의」로.
    var worst = 0;
    for (var i = 1; i < n; i++) {
      if (s[i] <= s[worst]) worst = i;
    }
    v[worst] = ToneVerdict.close;
  }
  return WordJudgement(v, heard, scores, joint);
}
