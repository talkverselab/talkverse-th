import 'package:flutter_test/flutter_test.dart';
import 'package:thai_universe/services/speech_judge.dart';

void main() {
  List<String> seg(String s) => s.split(' ');

  test('3단계 평가 — 아쉬워요 / 원썸 / 투썸', () {
    const target = 'สวัสดี ครับ ผม ชื่อ มินโฮ ยินดี ที่ ได้ รู้จัก';
    // 전부 말함 → 투썸
    expect(SpeechJudge.evaluate(target, target, seg).rating, SpeechRating.two);
    // 일부(기준 이상) → 원썸
    final one = SpeechJudge.evaluate(target, 'สวัสดี ผม ชื่อ มินโฮ', seg);
    expect(one.passed, isTrue);
    expect(one.rating, SpeechRating.one);
    // 거의 못 말함 → 아쉬워요
    final weak = SpeechJudge.evaluate(target, 'สวัสดี', seg);
    expect(weak.passed, isFalse);
    expect(weak.rating, SpeechRating.weak);
    // 배지 문구
    expect(SpeechRating.two.badge, '👍👍 투썸');
    expect(SpeechRating.one.badge, '👍 원썸');
    expect(SpeechRating.weak.badge, '아쉬워요');
  });
}
