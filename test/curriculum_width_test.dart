import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_universe/screens/curriculum_screen.dart';

/// 코스 고르기 줄(3·5·10 칩 + 추천으로 채우기)이 폰 폭·300px 폭에서 넘치지 않는지(uk 전달, 2026-11-22).
void main() {
  testWidgets('커리큘럼 코스 고르기 — 300px·폰 폭에서 넘치지 않음', (t) async {
    SharedPreferences.setMockInitialValues({'th_curriculum_v1': '{"level":"R1","dailyGoal":2}'});
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(300, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
    for (var i = 0; i < 10 && find.text('추천으로 채우기').evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.pump();
    }
    expect(find.text('추천으로 채우기'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.tap(find.text('추천으로 채우기'));
    await t.pump();
    for (final w in [300.0, 390.0, 744.0]) {
      t.view.physicalSize = Size(w, 900);
      await t.pump();
      expect(t.takeException(), isNull, reason: '폭 $w');
    }
  });
}
