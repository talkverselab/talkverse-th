import 'package:flutter/material.dart';

import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/learner_prefs.dart';
import '../main.dart';
import '../widgets/thai_decor.dart';
import '../widgets/today_mission.dart';
import 'alphabet_screen.dart';
import 'chunk_search_screen.dart';
import 'conversation_screen.dart';
import 'course_screen.dart';
import 'english_manual_screen.dart';
import 'episode_screen.dart';
import 'flashcard_screen.dart';
import 'grammar_hub_screen.dart';
import 'keyboard_practice_screen.dart';
import 'loanword_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'quick_phrases_screen.dart';
import 'script_quiz_screen.dart';
import 'speaking_practice_screen.dart';
import 'thai_roots_screen.dart';
import 'tones_screen.dart';
import 'vocab_hub_screen.dart';
import '../core/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static final List<Widget> _screens = [
    HomeScreen(),
    LearnScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  static List<NavigationDestination> get _tabs => [
    NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: tr('홈')),
    NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: tr('학습')),
    NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: tr('진행')),
    NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: tr('프로필')),
  ];

  final _pane = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // 폰(한 화면): 하단 탭 + 내용 전체 화면
    if (!isWide(context)) {
      return Scaffold(
        body: _screens[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _tabs,
        ),
      );
    }
    // 넓은 화면(아이패드·안드로이드 태블릿·폴드 펼침): 레일 + 왼쪽 칸(탭 화면) | 오른쪽 칸(연 화면). 두 칸까지만.
    // 일본어앱·한자앱과 같은 구조(docs/TWO_PANE_UX.md). 학습(에피소드)은 openFull 로 전체 화면.
    final w = MediaQuery.sizeOf(context).width;
    final left = (w * 0.38).clamp(320.0, 460.0);
    return Pane(
      navKey: _pane,
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _pane.currentState?.maybePop(),
        child: Scaffold(
          body: SafeArea(
            right: false,
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: w >= 900 ? NavigationRailLabelType.all : NavigationRailLabelType.selected,
                  backgroundColor: AppColors.creamDeep,
                  indicatorColor: const Color(0xFFF4E4C8),
                  selectedIconTheme: const IconThemeData(color: AppColors.kluayMai),
                  unselectedIconTheme: const IconThemeData(color: AppColors.thongDeep),
                  selectedLabelTextStyle: const TextStyle(color: AppColors.kluayMai, fontSize: 11, fontWeight: FontWeight.w600),
                  unselectedLabelTextStyle: const TextStyle(color: AppColors.thongDeep, fontSize: 11, fontWeight: FontWeight.w500),
                  destinations: [
                    for (final t in _tabs)
                      NavigationRailDestination(icon: t.icon, selectedIcon: t.selectedIcon, label: Text(t.label)),
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.thong),
                SizedBox(width: left, child: IndexedStack(index: _index, children: _screens)),
                const VerticalDivider(width: 1, color: AppColors.thong),
                Expanded(
                  child: ClipRect(
                    child: Navigator(
                      key: _pane,
                      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const _PaneEmpty()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 칸 첫 화면 — 오늘의 장면(점토 톤 그림, Grok UXUI 시안 02). 메뉴를 고르면 이 자리에 열린다.
class _PaneEmpty extends StatelessWidget {
  const _PaneEmpty();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.cream,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 470 / 645, // 그림 비율 그대로(잘리지 않게)
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/images/scene_home.jpg', fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(tr('왼쪽에서 메뉴를 고르면 여기에 열려요'),
                  style: const TextStyle(fontSize: 13, color: AppColors.thongDeep)),
            ],
          ),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, height: 260, child: MeshBackdrop()),
          SafeArea(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'สวัสดี!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.khram,
                                  letterSpacing: -1,
                                  fontFamilyFallback: AppTheme.fontFallback,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('🙏', style: TextStyle(fontSize: 22)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          ValueListenableBuilder<String>(
                            valueListenable: LearnerPrefs.name,
                            builder: (_, n, _) => Text(
                              n.isEmpty ? tr('오늘도 태국어 한 걸음') : trf('{0}님, 오늘도 태국어 한 걸음', [n]),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.khramLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const StreakChip(days: 1),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        border: Border.all(color: AppColors.thong),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person,
                          color: AppColors.kluayMai, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  tr('오늘의 학습'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kluayMai,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 8),
                const _TodayMission(),
                const SizedBox(height: 12),
                const _TodayTasks(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    GoldEmblem(text: 'เร็ว', size: 22),
                    SizedBox(width: 8),
                    Text(
                      tr('퀵메뉴'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.khram,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _QuickMenuRow(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    GoldEmblem(text: 'เมนู', size: 22),
                    SizedBox(width: 8),
                    Text(
                      tr('메인 메뉴'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.khram,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MenuGrid(),
                const SizedBox(height: 28),
                const SilkDivider(),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    tr('태국어유니버스 · 2026'),
                    style: TextStyle(
                      color: AppColors.khramLight,
                      fontSize: 11,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 홈 '오늘의 학습' — 첫 미완료 에피소드와 실제 진행도 연결.
class _TodayMission extends StatefulWidget {
  const _TodayMission();

  @override
  State<_TodayMission> createState() => _TodayMissionState();
}

class _TodayMissionState extends State<_TodayMission> {
  EpisodeMeta? _meta;
  int _learned = 0;
  int _total = 12;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await EpisodeCatalog.instance.ensureLoaded();
    final all = EpisodeCatalog.instance.all;
    if (all.isEmpty) return;
    final turns = await appDb.select(appDb.turns).get();
    final progress = await appDb.select(appDb.userProgress).get();
    final learnedIds =
        progress.where((p) => p.learned).map((p) => p.turnId).toSet();
    for (final meta in all) {
      final epTurns = turns
          .where((t) => t.level == meta.level && t.episodeId == meta.id)
          .toList();
      final total = epTurns.length;
      final learned = epTurns.where((t) => learnedIds.contains(t.id)).length;
      if (total == 0 || learned < total || meta == all.last) {
        if (mounted) {
          setState(() {
            _meta = meta;
            _learned = learned;
            _total = total == 0 ? 12 : total;
          });
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    if (meta == null) return const SizedBox(height: 120);
    return TodayMissionCard(
      level: meta.level == 'L1' ? 'BEGINNER 1' : meta.level,
      lessonTitle: '${meta.level} · ${meta.title}',
      lessonSubtitle: trf('{0} & 태국 친구 스토리 {1}', [LearnerPrefs.name.value.isEmpty ? tr('나') : LearnerPrefs.name.value, meta.emoji]),
      cta: tr('학습 시작하기'),
      progress: _learned,
      total: _total,
      onTap: () async {
        await openFull(context, (_) => EpisodeScreen(meta: meta));
        _load();
      },
    );
  }
}

/// 오늘 할 일 3장 — 이어하기 · 바로 문장 · 복습 (Grok UXUI 시안 02).
class _TodayTasks extends StatelessWidget {
  const _TodayTasks();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, Color, String, String, WidgetBuilder, bool)>[
      (Icons.menu_book_rounded, AppColors.kluayMai, tr('이어하기'), tr('회화'), (_) => const ConversationScreen(), false),
      (Icons.chat_bubble_rounded, AppColors.sunset, tr('바로 문장'), tr('자주 쓰는 말'), (_) => const QuickPhrasesScreen(), false),
      (Icons.sync_rounded, AppColors.morakot, tr('복습'), tr('최근 학습'), (_) => const FlashcardScreen(), true),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => items[i].$6 ? openFull(context, items[i].$5) : openPane(context, items[i].$5),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.thong),
                  boxShadow: const [BoxShadow(color: Color(0x1A5A3E28), blurRadius: 5, offset: Offset(0, 2), spreadRadius: -1)],
                ),
                child: Column(children: [
                  CircleAvatar(radius: 22, backgroundColor: items[i].$2, child: Icon(items[i].$1, color: Colors.white, size: 22)),
                  const SizedBox(height: 8),
                  Text(items[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.khram)),
                  Text(items[i].$4, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.khramLight)),
                ]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 퀵메뉴 — 자주 쓰는 코너 바로가기 (바로 문장이 첫 자리).
class _QuickMenuRow extends StatelessWidget {
  const _QuickMenuRow();

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, bool, WidgetBuilder)>[
      ('🎯', tr('내 코스'), true, (_) => const CourseScreen()),
      ('⚡', tr('바로 문장'), false, (_) => const QuickPhrasesScreen()),
      ('📖', tr('단어장'), false, (_) => const VocabHubScreen()),
      ('💬', tr('회화'), false, (_) => const ConversationScreen()),
      ('🎙️', tr('문장 말하기'), false, (_) => const SpeakingPracticeScreen()),
      ('⌨️', tr('키보드연습'), false, (_) => const KeyboardPracticeScreen()),
      ('🔍', tr('청크 검색'), false, (_) => const ChunkSearchScreen()),
      ('🎴', tr('복습'), false, (_) => const FlashcardScreen()),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (emoji, label, primary, builder) = items[i];
          return InkWell(
            onTap: () => openPane(context, builder),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary ? AppColors.kluayMaiDeep : Colors.white,
                border: Border.all(
                  color: primary
                      ? AppColors.kluayMaiDeep
                      : AppColors.thong.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                '$emoji $label',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: primary ? AppColors.cream : AppColors.khram,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
          label: tr('회화'),
          sub: 'Dialogue',
          emblem: 'คุย',
          color: AppColors.badges[0],
          builder: (_) => const ConversationScreen()),
      _MenuItem(
          label: tr('문장 말하기'),
          sub: tr('한글 보고 태국어로 · 7초/4초/2초'),
          emblem: 'พูด',
          color: AppColors.badges[1],
          builder: (_) => const SpeakingPracticeScreen()),
      _MenuItem(
          label: tr('문자 44'),
          sub: tr('자음 · 3분류 · 모음'),
          emblem: 'ก',
          color: AppColors.badges[2],
          builder: (_) => const AlphabetScreen()),
      _MenuItem(
          label: tr('성조 5'),
          sub: 'วรรณยุกต์',
          emblem: 'เสียง',
          color: AppColors.badges[3],
          builder: (_) => const TonesScreen()),
      _MenuItem(
          label: tr('문법'),
          sub: tr('초급 코스 16과 · เป็น · ได้ · ขึ้น/ลง'),
          emblem: 'ได้',
          color: AppColors.badges[4],
          builder: (_) => const GrammarHubScreen()),
      _MenuItem(
          label: tr('단어장'),
          sub: tr('주제별 · 중요 단어(절벽 구간)'),
          emblem: 'ศัพท์',
          color: AppColors.badges[5],
          builder: (_) => const VocabHubScreen()),
      _MenuItem(
          label: 'Manual for English',
          sub: tr('RTGS vs ours · 장음 밑줄'),
          emblem: 'ABC',
          color: AppColors.badges[6],
          builder: (_) => const EnglishManualScreen()),
      _MenuItem(
          label: tr('영어 유래 단어'),
          sub: tr('음차 규칙 8줄기 · 200'),
          emblem: 'ทับ',
          color: AppColors.badges[7],
          builder: (_) => const LoanwordScreen()),
      _MenuItem(
          label: tr('루트 단어'),
          sub: 'น้ำ → น้ำแข็ง',
          emblem: 'ราก',
          color: AppColors.badges[8],
          builder: (_) => const ThaiRootsScreen()),
      _MenuItem(
          label: tr('문자 퀴즈'),
          sub: tr('4지선다'),
          emblem: '?',
          color: AppColors.badges[9],
          builder: (_) => const ScriptQuizScreen()),
      _MenuItem(
          label: tr('키보드연습'),
          sub: 'Kedmanee',
          emblem: 'พิมพ์',
          color: AppColors.badges[10],
          builder: (_) => const KeyboardPracticeScreen()),
      _MenuItem(
          label: tr('복습'),
          sub: 'Flashcard',
          emblem: 'ทวน',
          color: AppColors.badges[11],
          builder: (_) => const FlashcardScreen()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 150, // 폭이 좁은 칸(아이패드 왼쪽 칸)에서도 글자가 넘치지 않게 높이 고정
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MenuTile(item: items[i]),
    );
  }
}

class _MenuItem {
  final String label;
  final String sub;
  final String emblem;
  final Color color;
  final WidgetBuilder builder;
  _MenuItem({
    required this.label,
    required this.sub,
    required this.emblem,
    required this.color,
    required this.builder,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          openPane(context, item.builder),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.thong),
          boxShadow: const [
            BoxShadow(color: Color(0x1A5A3E28), blurRadius: 5, offset: Offset(0, 2), spreadRadius: -1),
            BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1), spreadRadius: -1),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GoldEmblem(text: item.emblem, size: 44, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.khram,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.sub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.khramLight,
                  letterSpacing: 0.5,
                  fontFamilyFallback: AppTheme.fontFallback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────── Learn 탭 ──────────

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  List<_LessonItem> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    await EpisodeCatalog.instance.ensureLoaded();
    final turns = await appDb.select(appDb.turns).get();
    final progress = await appDb.select(appDb.userProgress).get();
    final learnedIds =
        progress.where((p) => p.learned).map((p) => p.turnId).toSet();

    final items = <_LessonItem>[];
    for (final level in ['L1', 'L2', 'L3']) {
      final metas = EpisodeCatalog.instance.forLevel(level);
      if (metas.isEmpty) continue;
      items.add(_LessonItem.header(
          EpisodeCatalog.levelLabels[level] ?? level, metas.length));
      var currentAssigned = false;
      for (var i = 0; i < metas.length; i++) {
        final meta = metas[i];
        final epTurns = turns
            .where((t) => t.level == level && t.episodeId == meta.id)
            .toList();
        final total = epTurns.length;
        final learned =
            epTurns.where((t) => learnedIds.contains(t.id)).length;
        final done = total > 0 && learned >= total;
        _LessonState state;
        if (done) {
          state = _LessonState.done;
        } else if (!currentAssigned) {
          state = _LessonState.current;
          currentAssigned = true;
        } else {
          state = _LessonState.open;
        }
        items.add(_LessonItem(
          '${level == 'L1' ? 'EP' : 'D'}${i + 1}',
          '${meta.emoji} ${meta.title}',
          state,
          meta: meta,
          learned: learned,
          total: total,
        ));
      }
    }
    if (mounted) setState(() => _lessons = items);
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
        title: Text(tr('학습'), style: TextStyle(color: AppColors.khram)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.khram),
            onPressed: () => openPane(context, (_) => const ChunkSearchScreen()),
          ),
        ],
      ),
      body: Column(
        children: [
          const LaiThaiDivider(height: 10),
          Expanded(
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _LessonRow(
                lesson: lessons[i],
                onReturn: _loadLessons,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LessonState { done, current, open }

class _LessonItem {
  final String id;
  final String title;
  final _LessonState state;
  final EpisodeMeta? meta;
  final int learned;
  final int total;
  final bool isHeader;
  _LessonItem(
    this.id,
    this.title,
    this.state, {
    required this.meta,
    required this.learned,
    required this.total,
  }) : isHeader = false;

  _LessonItem.header(this.title, int count)
      : id = '',
        state = _LessonState.open,
        meta = null,
        learned = 0,
        total = count,
        isHeader = true;
}

class _LessonRow extends StatelessWidget {
  final _LessonItem lesson;
  final VoidCallback onReturn;
  const _LessonRow({required this.lesson, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    if (lesson.isHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 2),
        child: Row(
          children: [
            const GoldEmblem(text: 'บท', size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.khram,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Text(
              trf('{0}편', [lesson.total]),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.kluayMaiDeep,
              ),
            ),
          ],
        ),
      );
    }
    Color bg;
    Color border;
    Color textColor;
    Widget trailing;
    switch (lesson.state) {
      case _LessonState.done:
        bg = AppColors.cream;
        border = AppColors.morakot;
        textColor = AppColors.khram;
        trailing = const Icon(Icons.check_circle, color: AppColors.morakot);
        break;
      case _LessonState.current:
        bg = AppColors.kluayMai;
        border = AppColors.kluayMaiDeep;
        textColor = AppColors.cream;
        trailing = const Icon(Icons.arrow_forward, color: AppColors.cream);
        break;
      case _LessonState.open:
        bg = AppColors.cream;
        border = AppColors.thong.withValues(alpha: 0.6);
        textColor = AppColors.khram;
        trailing = const Icon(Icons.chevron_right,
            color: AppColors.khramLight, size: 20);
        break;
    }
    return InkWell(
      onTap: lesson.meta == null
          ? null
          : () async {
              await openFull(context, (_) => EpisodeScreen(meta: lesson.meta!));
              onReturn();
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: border,
              width: lesson.state == _LessonState.current ? 1.5 : 0.8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                lesson.id,
                style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.75)),
              ),
            ),
            Expanded(
              child: Text(
                lesson.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (lesson.total > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${lesson.learned}/${lesson.total}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            trailing,
          ],
        ),
      ),
    );
  }
}
