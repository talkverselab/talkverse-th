import 'package:flutter/material.dart';

import 'core/embed_env.dart';
import 'core/l10n.dart';
import 'core/thai_font.dart';
import 'core/theme.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'data/entitlement.dart';
import 'data/purchase.dart';
import 'screens/main_screen.dart';
import 'screens/sync_screen.dart';
import 'services/auth_service.dart';
import 'services/cliff_service.dart';
import 'services/content_store.dart';
import 'services/content_sync.dart';
import 'services/dev_notes.dart';
import 'services/ko_reading.dart';
import 'services/learner_prefs.dart';
import 'services/update_service.dart';
import 'widgets/dev_note_overlay.dart';

export 'core/embed_env.dart' show embedded;

/// 통합 앱(Talkverse) 연결점 — 2026-11-09 ~/talkverse/talkverse-app/EMBED_GUIDE.md.
/// 단독 앱 `main()` 도 이 두 함수를 쓴다: `await embedInit(standalone: true)` → `runApp(embedApp())`.
/// 통합 앱: `await embedInit()` → 이 언어 화면을 열 때 `embedApp(onSwitchLanguage: …)`.

late final AppDatabase appDb;
bool _inited = false;
bool _syncFirst = false;

/// 「다른 언어 배우기」 — 통합 앱이 넘긴 콜백(없으면 메뉴를 안 보인다).
VoidCallback? switchLanguage;

/// 초기화 전부(runApp 제외). 여러 번 불러도 한 번만 한다.
Future<void> embedInit({bool standalone = false}) async {
  if (_inited) return;
  _inited = true;
  embedded = !standalone;
  WidgetsFlutterBinding.ensureInitialized();
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
  await KoReadingPrefs.load();
  await AppLangPrefs.load();
  await LearnerPrefs.load();
  await ThaiFontPrefs.load();
  await ContentStore.instance.init();
  CliffService.instance.ensureLoaded(); // 절벽구간 배지 — 기다리지 않음
  await DevNotes.instance.load();
  await AuthService.instance.init(); // 실패해도 앱은 뜬다(오프라인)
  Purchase.ownStream = standalone; // 통합 앱이면 결제 스트림은 공용 결제가 넘겨준다
  Entitlement.configure(); // 스토어 상품(기다리지 않음) — 가격표 ~/talkverse/PRICING.md
  if (standalone) UpdateService.instance.loadCurrent(); // 앱 버전 표시(단독 앱만)
  // 그림(장면 컷·단어 그림)·회화 음성 기기 내려받기: 버전이 다르면 로딩 화면에서 받고 시작
  _syncFirst = await ContentSync.instance.init(large: _isTablet(), female: LearnerPrefs.isFemale);
  // 콘텐츠만 바뀐 수정은 APK 없이 받는다 — 받으면 화면들이 revision 을 듣고 다시 읽는다.
  ContentStore.instance.refresh();
  DevNotes.instance.flushQueue();
}

/// 짧은 변 600 이상(태블릿·폴드 펼침)이면 큰 장면 컷(1168)을 받는다.
bool _isTablet() {
  try {
    final v = WidgetsBinding.instance.platformDispatcher.views.first;
    final s = v.physicalSize / v.devicePixelRatio;
    return s.shortestSide >= 600;
  } catch (_) {
    return false;
  }
}

/// runApp 에 넘기는 위젯(통합 앱은 이 언어 화면으로). [onSwitchLanguage] 가 있으면 프로필 설정 맨 위에 「다른 언어 배우기」.
Widget embedApp({VoidCallback? onSwitchLanguage}) {
  switchLanguage = onSwitchLanguage;
  return ThaiUniverseApp(syncFirst: _syncFirst);
}

class ThaiUniverseApp extends StatelessWidget {
  final bool syncFirst;
  const ThaiUniverseApp({super.key, this.syncFirst = false});

  @override
  Widget build(BuildContext context) {
    // 표시 언어가 바뀌면 key 가 바뀌어 앱 전체가 새로 그려진다 (홈으로 돌아감).
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLangPrefs.lang,
      builder: (context, lang, _) => ValueListenableBuilder<String>(
        // 태국어 글꼴이 바뀌면 테마만 바뀐다(화면 위치는 그대로)
        valueListenable: ThaiFontPrefs.id,
        builder: (context, _, _) => MaterialApp(
          key: ValueKey(lang),
          title: tr('태국어유니버스'),
          debugShowCheckedModeBanner: false,
          navigatorKey: DevNotes.instance.navigatorKey,
          navigatorObservers: [DevNotes.instance.observer],
          theme: AppTheme.light(fontFamily: ThaiFontPrefs.family),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          // 아이폰 Dynamic Type·갤럭시 글자 크기 설정이 커도 타일이 깨지지 않게 1.2배까지만
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2)),
              child: DevNoteOverlay(child: child ?? const SizedBox.shrink()),
            );
          },
          home: syncFirst ? const SyncScreen(next: MainScreen()) : const MainScreen(),
        ),
      ),
    );
  }
}
