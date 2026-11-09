// 아이패드·태블릿·폴드 펼침 두 화면(레일 + 왼쪽 탭 | 오른쪽 칸) 확인용 스크린샷 흐름.
// 실행: python3 tools/pane_shots.py <아이패드 UDID> <출력폴더>
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:thai_universe/core/l10n.dart';
import 'package:thai_universe/data/db/app_database.dart';
import 'package:thai_universe/data/db/seed_loader.dart';
import 'package:thai_universe/embed.dart';
import 'package:thai_universe/services/ko_reading.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester t, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await wait(t, 2000);
    // ignore: avoid_print
    print('SHOT:$name');
    await wait(t, 3000);
  }

  testWidgets('two pane', timeout: const Timeout(Duration(minutes: 10)), (t) async {
    appDb = AppDatabase();
    await SeedLoader(appDb).seedIfNeeded();
    await KoReadingPrefs.load();
    await AppLangPrefs.load();
    await t.pumpWidget(const ThaiUniverseApp());
    await wait(t, 2000);
    await shot(t, '01_home');

    await t.tap(find.text('단어장').last);
    await shot(t, '02_home_pane_vocab');

    await t.tap(find.text('학습').last);
    await wait(t, 1000);
    await shot(t, '03_learn');
    await t.tap(find.textContaining('첫 만남').first);
    await wait(t, 2000);
    await shot(t, '04_episode_split');
    await t.tap(find.textContaining('저는 파예요').first);
    await shot(t, '05_episode_card_right');
    await t.pageBack();
    await wait(t, 1500);

    await t.tap(find.text('프로필').last);
    await shot(t, '06_profile');
  });
}
