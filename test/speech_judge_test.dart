import 'package:flutter_test/flutter_test.dart';
import 'package:thai_universe/services/speech_judge.dart';

void main() {
  // 테스트용 단순 분절기: 공백 기준
  List<String> seg(String s) =>
      s.split(' ').where((w) => w.isNotEmpty).toList();

  group('SpeechJudge.coverage', () {
    test('정확히 일치하면 1.0 (조사 ครับ 는 제외)', () {
      const target = 'สวัสดี ครับ ผม ชื่อ มินโฮ';
      const recognized = 'สวัสดีครับผมชื่อมินโฮ';
      expect(SpeechJudge.coverage(target, recognized, seg), 1.0);
    });

    test('단어 하나 빠지면 (n-1)/n', () {
      const target = 'สวัสดี ครับ ผม ชื่อ มินโฮ'; // 판정 단어 4개
      const recognized = 'สวัสดี ผม มินโฮ'; // ชื่อ 누락
      expect(SpeechJudge.coverage(target, recognized, seg), closeTo(0.75, 1e-9));
    });

    test('비슷하게 인식된 단어도 인정 (퍼지 ≥ 0.5)', () {
      const target = 'อร่อย มาก';
      // อร่อย → อร่อ (1글자 누락), มาก → มา (1글자 누락)
      const recognized = 'อร่อ มา';
      expect(SpeechJudge.coverage(target, recognized, seg), 1.0);
    });

    test('아무것도 인식되지 않으면 0', () {
      expect(SpeechJudge.coverage('สวัสดี ครับ', '', seg), 0.0);
      expect(SpeechJudge.coverage('สวัสดี ครับ', '  ', seg), 0.0);
    });

    test('evaluate: 빠진 단어 표시와 임계값 통과', () {
      final r = SpeechJudge.evaluate(
        'สวัสดี ครับ ผม ชื่อ มินโฮ',
        'สวัสดี ผม มินโฮ',
        seg,
        threshold: 0.5,
      );
      expect(r.words, ['สวัสดี', 'ผม', 'ชื่อ', 'มินโฮ']);
      expect(r.said, [true, true, false, true]);
      expect(r.missedCount, 1);
      expect(r.passed, isTrue);
      expect(
        SpeechJudge.evaluate('สวัสดี ครับ ผม ชื่อ มินโฮ', 'สวัสดี ผม มินโฮ',
                seg,
                threshold: 0.9)
            .passed,
        isFalse,
      );
    });
  });
}
