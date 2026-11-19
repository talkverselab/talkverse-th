import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_universe/screens/loanword_quiz_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('틀린 표기 보기 — 실제 단어와 겹치지 않고 셋 이상', () {
    final m = loanwordMisspellings('คอมพิวเตอร์', {'คอมพิวเตอร์', 'คอมพิวเตอ'});
    expect(m, isNot(contains('คอมพิวเตอร์')));
    expect(m, isNot(contains('คอมพิวเตอ')));
    expect(m, contains('คอมพิวเตอร'));
    expect(m.length, greaterThanOrEqualTo(3));
    expect(loanwordMisspellings('บัส', {'บัส'}).length, greaterThanOrEqualTo(3));
    expect(loanwordMisspellings('ฟุตบอล', {'ฟุตบอล'}).length, greaterThanOrEqualTo(3));
  });

  testWidgets('퀴즈 복습 — 보기 4개, 10문제 뒤 결과, 폭 320 넘침 없음', (t) async {
    t.view.physicalSize = const Size(320, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final words = [
      for (final w in const [
        ('บัส', 'bus', '버스'), ('เบียร์', 'beer', '맥주'), ('คอมพิวเตอร์', 'computer', '컴퓨터'), ('เกม', 'game', '게임'),
        ('กาแฟ', 'coffee', '커피'), ('คัพ', 'cup', '컵'), ('ฟุตบอล', 'football', '축구'), ('โรงแรม', '', '호텔'),
        ('แท็กซี่', 'taxi', '택시'), ('ช็อกโกแลต', 'chocolate', '초콜릿'), ('ไอศกรีม', 'ice cream', '아이스크림'), ('ทีวี', 'TV', '텔레비전'),
      ])
        LQWord(w.$1, w.$2, w.$3),
    ];
    await t.pumpWidget(MaterialApp(home: LoanwordQuizScreen(words: words, seed: 7)));
    await t.pumpAndSettle();
    for (var i = 0; i < kLoanwordQuizSize; i++) {
      expect(t.takeException(), isNull);
      expect(find.byKey(const ValueKey('lq-opt-3')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('lq-opt-0')));
      await t.pump();
      await t.ensureVisible(find.byKey(const ValueKey('lq-next')));
      await t.tap(find.byKey(const ValueKey('lq-next')));
      await t.pump();
    }
    expect(t.takeException(), isNull);
    expect(find.byKey(const ValueKey('lq-again')), findsOneWidget);
  });
}
