import 'package:flutter_test/flutter_test.dart';

import 'package:thai_universe/main.dart';

void main() {
  testWidgets('홈 화면이 뜨고 하단 탭이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiUniverseApp());
    await tester.pump();

    // 인사말과 주요 탭 라벨 확인
    expect(find.text('สวัสดีครับ 👋'), findsOneWidget);
    expect(find.text('알파벳'), findsWidgets);
    expect(find.text('성조'), findsWidgets);
  });
}
