import '../core/l10n.dart';
/// 문장 말하기 판정 — 순수 Dart (Flutter 의존 없음, 단위 테스트 가능).
///
/// 목표 태국어 문장을 단어로 분절한 뒤, 음성 인식 결과 안에
/// 각 단어가 "들어 있는지"만 본다. 발음 품질은 보지 않고
/// 빠진 단어가 없는지(coverage)로 통과/미통과를 가른다.
class SpeechJudge {
  SpeechJudge._();

  /// 퍼지 매칭 최소 유사도 (낮을수록 관대).
  static const double fuzzyRatio = 0.5;

  /// 판정 기준 기본값 (coverage ≥ 이 값이면 통과 = 원썸).
  static const double defaultThreshold = 0.5;

  /// 이 이상이면 투썸 (빠진 단어가 거의 없음).
  static const double twoThumbsCoverage = 0.9;

  /// 판정에서 제외하는 어말 조사·감탄사.
  static const Set<String> particles = {
    'ครับ', 'ค่ะ', 'คะ', 'นะ', 'ๆ', 'จ้ะ', 'จ้า', 'จ๊ะ', 'สิ', 'ซิ',
    'เถอะ', 'ล่ะ', 'หรอ', 'เหรอ', 'นะคะ', 'นะครับ', 'ครับผม', 'ฮะ', 'ฮ่ะ',
  };

  static final RegExp _strip = RegExp(r'[\s\p{P}\p{S}]+', unicode: true);

  /// 공백·문장부호·기호 제거.
  static String normalize(String s) => s.replaceAll(_strip, '');

  /// 목표 문장을 판정 대상 단어 목록으로 (2자 미만·조사 제외).
  static List<String> targetWords(
    String target,
    List<String> Function(String) segment,
  ) {
    final out = <String>[];
    for (final raw in segment(target)) {
      final w = normalize(raw);
      if (w.length < 2) continue;
      if (particles.contains(w)) continue;
      out.add(w);
    }
    return out;
  }

  /// 레벤슈타인 거리.
  static int levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (j) => j);
    var cur = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      cur[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        var v = prev[j] + 1;
        if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
        if (prev[j - 1] + cost < v) v = prev[j - 1] + cost;
        cur[j] = v;
      }
      final t = prev;
      prev = cur;
      cur = t;
    }
    return prev[b.length];
  }

  /// 0~1 유사도 (1 = 동일).
  static double similarity(String a, String b) {
    final n = a.length > b.length ? a.length : b.length;
    if (n == 0) return 1;
    return 1 - levenshtein(a, b) / n;
  }

  /// 단어가 인식 텍스트(정규화됨)에 "말해진" 것으로 보이는가.
  /// 부분 문자열 포함 또는 비슷한 길이의 창(window)과 퍼지 유사도 ≥ [fuzzyRatio].
  static bool wordSaid(String word, String recognizedNorm) {
    if (word.isEmpty || recognizedNorm.isEmpty) return false;
    if (recognizedNorm.contains(word)) return true;
    final n = recognizedNorm.length;
    final minLen = (word.length - 1).clamp(1, n);
    final maxLen = (word.length + 1).clamp(1, n);
    for (var len = minLen; len <= maxLen; len++) {
      for (var i = 0; i + len <= n; i++) {
        if (similarity(word, recognizedNorm.substring(i, i + len)) >=
            fuzzyRatio) {
          return true;
        }
      }
    }
    return false;
  }

  /// 목표 단어 중 인식된 비율 (0~1). 인식 텍스트가 비면 0.
  /// 판정할 단어가 없으면(조사만 있는 문장 등) 뭔가 인식됐을 때 1.
  static double coverage(
    String target,
    String recognized,
    List<String> Function(String) segment,
  ) {
    final rec = normalize(recognized);
    if (rec.isEmpty) return 0;
    final words = targetWords(target, segment);
    if (words.isEmpty) return 1;
    final said = words.where((w) => wordSaid(w, rec)).length;
    return said / words.length;
  }

  /// 상세 판정 (UI 표시용).
  static SpeechJudgeResult evaluate(
    String target,
    String recognized,
    List<String> Function(String) segment, {
    double threshold = defaultThreshold,
  }) {
    final rec = normalize(recognized);
    final words = targetWords(target, segment);
    final said = [for (final w in words) rec.isNotEmpty && wordSaid(w, rec)];
    final double cov;
    if (rec.isEmpty) {
      cov = 0;
    } else if (words.isEmpty) {
      cov = 1;
    } else {
      cov = said.where((s) => s).length / words.length;
    }
    return SpeechJudgeResult(
      words: words,
      said: said,
      coverage: cov,
      passed: cov >= threshold,
    );
  }
}

class SpeechJudgeResult {
  final List<String> words;
  final List<bool> said;
  final double coverage;
  final bool passed;
  SpeechJudgeResult({
    required this.words,
    required this.said,
    required this.coverage,
    required this.passed,
  });

  int get missedCount => said.where((s) => !s).length;

  /// 3단계 평가 — 아쉬워요 / 원썸 👍 / 투썸 👍👍.
  SpeechRating get rating => !passed
      ? SpeechRating.weak
      : coverage >= SpeechJudge.twoThumbsCoverage
          ? SpeechRating.two
          : SpeechRating.one;
}

/// 문장 평가 3단계.
enum SpeechRating {
  weak('아쉬워요', ''),
  one('원썸', '👍'),
  two('투썸', '👍👍');

  final String _label;
  final String thumbs;
  const SpeechRating(this._label, this.thumbs);

  /// 표시 언어에 맞춘 이름.
  String get label => tr(_label);

  /// 배지 문구: "👍👍 투썸" / "👍 원썸" / "아쉬워요"
  String get badge => thumbs.isEmpty ? label : '$thumbs $label';
}
