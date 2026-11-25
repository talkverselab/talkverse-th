import 'dart:math' as math;

import 'tracker.dart';

/// 기준 음높이에서 몇 반음 떨어졌는지.
double semitones(double hz, double refHz) =>
    12 * math.log(hz / refHz) / math.ln2;

/// 그 사람의 음역 — 처음에 "편하게 가장 낮게 / 가장 높게"와 평소 말소리로 한 번 잡아 둔다.
class SpeakerRange {
  const SpeakerRange({
    required this.lowHz,
    required this.highHz,
    required this.medianHz,
  });

  /// 유성 칸들의 5·50·95 백분위로 잡는다.
  factory SpeakerRange.fromHz(List<double> hz) {
    if (hz.isEmpty) throw ArgumentError('유성 칸이 없습니다');
    final s = [...hz]..sort();
    double p(double q) => s[((s.length - 1) * q).round()];
    return SpeakerRange(lowHz: p(0.05), highHz: p(0.95), medianHz: p(0.5));
  }

  factory SpeakerRange.fromJson(Map<String, dynamic> j) => SpeakerRange(
        lowHz: (j['low'] as num).toDouble(),
        highHz: (j['high'] as num).toDouble(),
        medianHz: (j['median'] as num).toDouble(),
      );

  final double lowHz;
  final double highHz;
  final double medianHz;

  Map<String, dynamic> toJson() =>
      {'low': lowHz, 'high': highHz, 'median': medianHz};

  /// 5도 눈금(1 = 그 사람 최저, 5 = 최고). 중국어 55·35·214·51 의 눈금.
  double level5(double hz) {
    final r = math.log(highHz / lowHz);
    if (r <= 0) return 3;
    return 1 + 4 * (math.log(hz / lowHz) / r).clamp(0.0, 1.0);
  }
}

/// 한 음절(또는 한 구간)의 음높이 곡선을 같은 개수의 점으로 맞춘 것. 단위는 반음.
class Contour {
  Contour(this.st, this.duration);

  /// 고르게 나눈 점들(기준 음높이 대비 반음).
  final List<double> st;

  /// 유성 구간 길이(초).
  final double duration;

  /// 유성 칸이 너무 적으면 null.
  static Contour? fromTrack(
    PitchTrack track, {
    required double refHz,
    int points = 20,
    int minVoicedFrames = 5,
  }) {
    final t = <double>[];
    final v = <double>[];
    for (final f in track.frames) {
      if (f.hz != null) {
        t.add(f.time);
        v.add(semitones(f.hz!, refHz));
      }
    }
    if (t.length < minVoicedFrames) return null;
    final t0 = t.first, t1 = t.last;
    final out = <double>[];
    var k = 0;
    for (var i = 0; i < points; i++) {
      final x = t0 + (t1 - t0) * i / (points - 1);
      while (k + 1 < t.length - 1 && t[k + 1] < x) {
        k++;
      }
      final span = t[k + 1] - t[k];
      final a = span > 0 ? ((x - t[k]) / span).clamp(0.0, 1.0) : 0.0;
      out.add(v[k] + (v[k + 1] - v[k]) * a);
    }
    return Contour(out, t1 - t0);
  }

  int get _edge => math.max(1, (st.length * 0.15).round());
  double _avg(int from, int to) {
    var s = 0.0;
    for (var i = from; i < to; i++) {
      s += st[i];
    }
    return s / (to - from);
  }

  /// 시작 높이(앞 15% 평균).
  double get start => _avg(0, _edge);

  /// 끝 높이(뒤 15% 평균).
  double get end => _avg(st.length - _edge, st.length);
  double get mean => _avg(0, st.length);
  double get min => st.reduce(math.min);
  double get max => st.reduce(math.max);
  double get range => max - min;

  /// 최저점 위치 0~1.
  double get minPos => st.indexOf(min) / (st.length - 1);

  /// 최고점 위치 0~1.
  double get maxPos => st.indexOf(max) / (st.length - 1);

  /// 기울기(반음/초).
  double get slope => duration > 0 ? (end - start) / duration : 0;

  /// 평균을 0 으로 옮긴 곡선(모양만 비교할 때).
  Contour centered() {
    final m = mean;
    return Contour([for (final x in st) x - m], duration);
  }
}
