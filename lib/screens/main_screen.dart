import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../main.dart';
import '../widgets/thai_decor.dart';
import '../widgets/today_mission.dart';
import 'alphabet_screen.dart';
import 'chunk_search_screen.dart';
import 'consonant_class_screen.dart';
import 'conversation_screen.dart';
import 'episode_screen.dart';
import 'flashcard_screen.dart';
import 'grammar_lesson_screen.dart';
import 'keyboard_practice_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'script_quiz_screen.dart';
import 'tones_screen.dart';
import 'word_freq_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    LearnScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _tabs = [
    NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: '홈'),
    NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: '학습'),
    NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: '진행'),
    NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F0), Color(0xFFFFF8EE)],
          ),
        ),
        child: SafeArea(
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
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.kluayMai,
                                  fontFamilyFallback: AppTheme.fontFallback,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('🙏', style: TextStyle(fontSize: 22)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '한국 학습자, 오늘도 방콕 한 걸음',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.khramLight,
                              fontWeight: FontWeight.w500,
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
                const Text(
                  '오늘의 학습',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.khram,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const _TodayMission(),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    GoldEmblem(text: 'เมนู', size: 22),
                    SizedBox(width: 8),
                    Text(
                      '메인 메뉴',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.khram,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MenuGrid(),
                const SizedBox(height: 28),
                const SilkDivider(),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    '태국어유니버스 · 2026',
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
      lessonSubtitle: '민호 & ฟ้า 스토리 ${meta.emoji}',
      progress: _learned,
      total: _total,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EpisodeScreen(meta: meta)),
        );
        _load();
      },
    );
  }
}

class _MenuGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
          label: '회화',
          sub: 'Dialogue',
          emblem: 'คุย',
          color: AppColors.kluayMai,
          builder: (_) => const ConversationScreen()),
      _MenuItem(
          label: '문자 44',
          sub: 'อักษรไทย',
          emblem: 'ก',
          color: const Color(0xFFC62828),
          builder: (_) => const AlphabetScreen()),
      _MenuItem(
          label: '자음 3분류',
          sub: '고·중·저',
          emblem: 'สูง',
          color: AppColors.morakot,
          builder: (_) => const ConsonantClassScreen()),
      _MenuItem(
          label: '성조 5',
          sub: 'วรรณยุกต์',
          emblem: 'เสียง',
          color: const Color(0xFF1565C0),
          builder: (_) => const TonesScreen()),
      _MenuItem(
          label: '어말조사',
          sub: 'คำลงท้าย',
          emblem: 'นะ',
          color: const Color(0xFFAD1457),
          builder: (_) => const GrammarLessonScreen()),
      _MenuItem(
          label: '단어',
          sub: 'Top 1000',
          emblem: 'คำ',
          color: AppColors.thongDeep,
          builder: (_) => const WordFreqScreen()),
      _MenuItem(
          label: '문자 퀴즈',
          sub: '4지선다',
          emblem: '?',
          color: const Color(0xFF6A1B9A),
          builder: (_) => const ScriptQuizScreen()),
      _MenuItem(
          label: '키보드연습',
          sub: 'Kedmanee',
          emblem: 'พิมพ์',
          color: const Color(0xFF00897B),
          builder: (_) => const KeyboardPracticeScreen()),
      _MenuItem(
          label: '복습',
          sub: 'Flashcard',
          emblem: 'ทวน',
          color: AppColors.thong,
          builder: (_) => const FlashcardScreen()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
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
          Navigator.push(context, MaterialPageRoute(builder: item.builder)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.thong.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.khram.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(1, 2),
            ),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.khram,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.sub,
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
          state = _LessonState.locked;
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
        title: const Text('학습', style: TextStyle(color: AppColors.khram)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.khram),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChunkSearchScreen()),
            ),
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

enum _LessonState { done, current, locked }

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
        state = _LessonState.locked,
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
              '${lesson.total}편',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.kluayMai,
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
      case _LessonState.locked:
        bg = AppColors.creamDeep;
        border = AppColors.thong.withValues(alpha: 0.3);
        textColor = AppColors.khramLight;
        trailing =
            const Icon(Icons.lock, color: AppColors.khramLight, size: 18);
        break;
    }
    return InkWell(
      onTap: lesson.state == _LessonState.locked || lesson.meta == null
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EpisodeScreen(meta: lesson.meta!)),
              );
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
