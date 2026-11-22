import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_universe/screens/sense_course_screen.dart';

/// 과정 데이터가 커서 에셋 읽기가 실제 비동기로 돈다 — pumpAndSettle 대신 실제 시간으로 기다린다(일본어앱 시험과 같은 꼴).
Future<void> settle(WidgetTester t, Finder until) async {
  for (var i = 0; i < 100 && until.evaluate().isEmpty; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump();
  }
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final w in const [320.0, 900.0]) {
    testWidgets('언어감각 목록 폭 $w — 10급 · 급마다 외울 대화 1회 + 참고, 넘침 없음', (t) async {
      t.view.physicalSize = Size(w, 6000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: SenseCourseScreen()));
      await settle(t, find.text('L1  문장 끝 말맛'));
      expect(t.takeException(), isNull);
      expect(find.text('L1  문장 끝 말맛'), findsOneWidget);
      for (var i = 1; i <= 10; i++) {
        expect(find.byKey(ValueKey('sense-L$i-talk')), findsOneWidget);
        expect(find.byKey(ValueKey('sense-L$i-ref')), findsOneWidget);
      }
      expect(find.text('참고'), findsNWidgets(10));
      expect(find.text('0/10회 마침'), findsOneWidget);
    });
  }

  testWidgets('외울 대화 회차 — 영상 자리, 색 표시가 글자에 안 남음, 마침 → 참고를 건너뛰고 L2', (t) async {
    t.view.physicalSize = const Size(320, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: SenseLessonScreen(index: 0)));
    await settle(t, find.byKey(const ValueKey('sense-finish')));
    expect(t.takeException(), isNull);
    expect(find.byKey(const ValueKey('memorize-video')), findsNothing);   // 영상 주소 없으면 칸 숨김(심사 2026-11-22)
    expect(find.textContaining('{', findRichText: true), findsNothing);
    expect(plainMarked('ขอบคุณ{ครับ|1}'), 'ขอบคุณครับ');
    await t.tap(find.byKey(const ValueKey('sense-finish')));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(await SenseCourse.done(), contains('L1-talk'));
  });

  testWidgets('참고 — 문장 끝 말, 닫기는 기록 안 함', (t) async {
    t.view.physicalSize = const Size(320, 12000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: SenseLessonScreen(index: 1)));
    await settle(t, find.text('닫기'));
    expect(t.takeException(), isNull);
    expect(find.textContaining('นะ'), findsWidgets);
    await t.tap(find.byKey(const ValueKey('sense-finish')));
    await t.pump(const Duration(milliseconds: 300));
    expect(await SenseCourse.done(), isNot(contains('L1-ref')));
  });
}
