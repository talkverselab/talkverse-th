import 'compare.dart';
import 'contour.dart';

enum ToneVerdict { good, close, off }

/// 중국어 성조 한 음절의 채점 결과.
class ToneScore {
  const ToneScore({
    required this.target,
    required this.heard,
    required this.scores,
    required this.verdict,
    required this.hints,
  });

  /// 목표 성조 1~4.
  final int target;

  /// 가장 가깝게 들린 성조 1~4.
  final int heard;

  /// 성조별 0~1.
  final Map<int, double> scores;
  final ToneVerdict verdict;

  /// 고칠 점(문구는 앱이 정한다): keep_level·end_higher·middle_lower·fall_more.
  /// (higher·start_higher 는 0.2 부터 내지 않는다 — 높이는 판정하지 않음.)
  final List<String> hints;

  double get score => scores[target]!;
}

/// 성조를 가르는 특징으로 채점한다(곡선 전체의 닮은 정도가 아니라).
/// [contour] 는 그 사람 평소 음높이(가운뎃값)를 기준으로 한 반음 곡선이어야 한다.
/// 문턱값은 합성음으로 맞춘 처음 값이다. 두 음절 낱말은 이 길 대신 본보기 견주기
/// (word_match.dart)를 쓰고, 이 길은 한 음절·세 음절 이상에만 남아 있다.
///
/// [connected] = 낱말·문장 안의 음절. 이어 말하면 오르내림 폭이 줄어드므로 문턱을 낮춘다.
ToneScore scoreMandarinTone(Contour contour, int target,
    {bool connected = false}) {
  if (target < 1 || target > 4) throw ArgumentError('성조는 1~4: $target');
  final c = contour;
  final k = connected ? 0.7 : 1.0;
  final rise = c.end - c.start;
  final fall = -rise;

  // 1성(55): 평평. 높이는 따지지 않는다 — 기기에서 재 보니 평평하게 이어 낸 1성이
  // 「더 높게」로 떨어졌다(평소 음높이 어림이 흔들리면 높이 판정이 먼저 틀린다).
  final t1 = 1 - ramp(c.range, 2, 5);
  // 2성(35): 끝이 시작보다 충분히 높다, 최고점이 뒤쪽.
  final t2 = ramp(rise, 1.5 * k, 4 * k) * (0.6 + 0.4 * ramp(c.maxPos, 0.5, 0.8));
  // 3성(214 / 문장 안에서는 21): 가운데가 충분히 낮다, 또는 낮게 깔린다.
  final midOk = (c.minPos >= 0.25 && c.minPos <= 0.9) ? 1.0 : 0.5;
  final dip =
      ramp(c.start - c.min, 1, 3) * ramp(c.end - c.min, 0.5, 2.5) * midOk;
  final low = ramp(-c.mean, 1, 3) * (1 - ramp(c.range, 5, 9));
  final t3 = dip > 0.8 * low ? dip : 0.8 * low;
  // 4성(51): 충분히 떨어진다(시작 높이는 따지지 않는다).
  final t4 = ramp(fall, 2.5 * k, 6 * k) *
      (0.6 + 0.4 * (1 - ramp(c.maxPos, 0.3, 0.6)));

  final scores = {1: t1, 2: t2, 3: t3, 4: t4};
  var heard = 1;
  for (final e in scores.entries) {
    if (e.value > scores[heard]!) heard = e.key;
  }
  final s = scores[target]!;
  final best = scores[heard]!;
  final verdict = (s >= 0.7 && s >= best - 0.1)
      ? ToneVerdict.good
      : (s >= 0.4 ? ToneVerdict.close : ToneVerdict.off);

  final hints = <String>[];
  switch (target) {
    case 1:
      hints.add('keep_level');
    case 2:
      if (rise < 4 * k) hints.add('end_higher');
    case 3:
      if (dip < 0.7 && low < 0.7) hints.add('middle_lower');
    case 4:
      hints.add('fall_more');
  }
  return ToneScore(
    target: target,
    heard: heard,
    scores: scores,
    verdict: verdict,
    hints: verdict == ToneVerdict.good ? const [] : hints,
  );
}
