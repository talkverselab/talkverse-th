import 'dart:math' as math;

import 'contour.dart';

double ramp(double x, double a, double b) =>
    ((x - a) / (b - a)).clamp(0.0, 1.0).toDouble();

/// 학습자 곡선과 기준(원어민) 곡선의 모양 비교 — 높이(음역)는 빼고 모양만.
class ContourMatch {
  const ContourMatch(this.rmse, this.correlation, this.score);

  /// 평균을 맞춘 뒤의 차이(반음).
  final double rmse;

  /// 오르내림 방향이 같은 정도 -1~1(기준이 평평하면 0).
  final double correlation;

  /// 0~1.
  final double score;
}

ContourMatch compareContours(Contour learner, Contour reference) {
  final a = learner.centered().st;
  final b = reference.centered().st;
  if (a.length != b.length) {
    throw ArgumentError('점 개수가 다릅니다: ${a.length} / ${b.length}');
  }
  var se = 0.0, saa = 0.0, sbb = 0.0, sab = 0.0;
  for (var i = 0; i < a.length; i++) {
    final d = a[i] - b[i];
    se += d * d;
    saa += a[i] * a[i];
    sbb += b[i] * b[i];
    sab += a[i] * b[i];
  }
  final rmse = math.sqrt(se / a.length);
  final flat = reference.range < 1.5;
  final r = (saa > 1e-9 && sbb > 1e-9) ? sab / math.sqrt(saa * sbb) : 0.0;
  final near = 1 - ramp(rmse, 1, 4);
  final score = flat ? near : 0.5 * near + 0.5 * ramp(r, 0.3, 0.9);
  return ContourMatch(rmse, flat ? 0 : r, score);
}

/// 문장용: 빠르기가 달라도 맞춰 보는 비교(DTW, 폭 제한). 두 곡선 모두 평균을 뺀 모양으로 비교한다.
/// 문장은 음절별 채점이 불안정하므로 이 값은 참고용이다.
ContourMatch compareContoursWarped(Contour learner, Contour reference,
    {double band = 0.06}) {
  final a = learner.centered().st;
  final b = reference.centered().st;
  final n = a.length, m = b.length;
  final w = math.max((band * math.max(n, m)).round(), (n - m).abs() + 1);
  final inf = double.infinity;
  var prev = List<double>.filled(m + 1, inf);
  var cur = List<double>.filled(m + 1, inf);
  var prevLen = List<int>.filled(m + 1, 0);
  var curLen = List<int>.filled(m + 1, 0);
  prev[0] = 0;
  for (var i = 1; i <= n; i++) {
    cur.fillRange(0, m + 1, inf);
    final center = (i * m / n).round();
    for (var j = math.max(1, center - w); j <= math.min(m, center + w); j++) {
      final d = (a[i - 1] - b[j - 1]) * (a[i - 1] - b[j - 1]);
      var best = prev[j - 1];
      var len = prevLen[j - 1];
      if (prev[j] < best) {
        best = prev[j];
        len = prevLen[j];
      }
      if (cur[j - 1] < best) {
        best = cur[j - 1];
        len = curLen[j - 1];
      }
      if (best == inf) continue;
      cur[j] = best + d;
      curLen[j] = len + 1;
    }
    final t = prev;
    prev = cur;
    cur = t;
    final tl = prevLen;
    prevLen = curLen;
    curLen = tl;
  }
  if (prev[m] == inf) return compareContours(learner, reference);
  final rmse = math.sqrt(prev[m] / prevLen[m]);
  return ContourMatch(rmse, 0, 1 - ramp(rmse, 0.8, 3));
}
