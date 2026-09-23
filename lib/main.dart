import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'screens/main_screen.dart';
import 'services/ko_reading.dart';
import 'core/l10n.dart';
import 'services/auth_service.dart';
import 'services/content_store.dart';
import 'services/dev_notes.dart';
import 'services/update_service.dart';
import 'widgets/dev_note_overlay.dart';

late final AppDatabase appDb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
  await KoReadingPrefs.load();
  await AppLangPrefs.load();
  await ContentStore.instance.init();
  await DevNotes.instance.load();
  await AuthService.instance.init(); // 실패해도 앱은 뜬다(오프라인)
  UpdateService.instance.loadCurrent();
  runApp(const ThaiUniverseApp());
  // 콘텐츠만 바뀐 수정은 APK 없이 받는다 — 받으면 화면들이 revision 을 듣고 다시 읽는다.
  ContentStore.instance.refresh();
  DevNotes.instance.flushQueue();
}

class ThaiUniverseApp extends StatelessWidget {
  const ThaiUniverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 표시 언어가 바뀌면 key 가 바뀌어 앱 전체가 새로 그려진다 (홈으로 돌아감).
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLangPrefs.lang,
      builder: (context, lang, _) => MaterialApp(
        key: ValueKey(lang),
        title: tr('태국어유니버스'),
        debugShowCheckedModeBanner: false,
        navigatorKey: DevNotes.instance.navigatorKey,
        navigatorObservers: [DevNotes.instance.observer],
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        // 아이폰 Dynamic Type·갤럭시 글자 크기 설정이 커도 타일이 깨지지 않게 1.2배까지만
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2),
            ),
            child: DevNoteOverlay(child: child ?? const SizedBox.shrink()),
          );
        },
        home: const MainScreen(),
      ),
    );
  }
}
