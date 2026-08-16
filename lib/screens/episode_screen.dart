import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/chunk_index_service.dart';
import '../services/tts_service.dart';
import '../widgets/selectable_thai.dart';
import '../widgets/thai_decor.dart';
import 'sentence_flashcard_screen.dart';

/// 에피소드/다이얼로그 메타 (Learn 탭·회화 허브·홈 공용).
class EpisodeMeta {
  final String level; // 'L1' | 'L2' | 'L3'
  final String id;
  final String title;
  final String emoji;
  const EpisodeMeta(this.level, this.id, this.title, this.emoji);
}

/// L1~L3 JSON에서 에피소드 목록을 1회 로드해 공유.
class EpisodeCatalog {
  EpisodeCatalog._();
  static final EpisodeCatalog instance = EpisodeCatalog._();

  final Map<String, List<EpisodeMeta>> _byLevel = {};
  bool _loaded = false;

  static const Map<String, String> levelLabels = {
    'L1': 'L1 스토리 — 방콕 첫걸음',
    'L2': 'L2 카오스 챗 — 드라마 실전',
    'L3': 'L3 내러티브',
  };

  List<EpisodeMeta> forLevel(String level) => _byLevel[level] ?? const [];
  List<EpisodeMeta> get all =>
      ['L1', 'L2', 'L3'].expand(forLevel).toList(growable: false);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    for (final level in ['L1', 'L2', 'L3']) {
      try {
        final raw = await rootBundle.loadString(
          'assets/data/dialogues/$level.json',
        );
        final data = json.decode(raw) as Map<String, dynamic>;
        final units =
            (data['episodes'] as List?) ?? (data['dialogues'] as List?) ?? [];
        _byLevel[level] = [
          for (final e in units.whereType<Map>())
            if ((e['turns'] as List?)?.isNotEmpty ?? false)
              EpisodeMeta(
                level,
                e['id'] as String,
                e['title'] as String? ?? e['id'] as String,
                e['emoji'] as String? ?? '💬',
              ),
        ];
      } catch (_) {
        _byLevel[level] = const [];
      }
    }
    _loaded = true;
  }
}

/// 에피소드 학습 화면 — 채팅 버블 + 청크 탭 + 턴별 학습 체크.
class EpisodeScreen extends StatefulWidget {
  final EpisodeMeta meta;
  const EpisodeScreen({super.key, required this.meta});

  @override
  State<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends State<EpisodeScreen> {
  List<TurnRow> _turns = [];
  final Map<int, bool> _learned = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ChunkIndexService.instance.ensureLoaded();
    final turns =
        await (appDb.select(appDb.turns)
              ..where(
                (t) =>
                    t.level.equals(widget.meta.level) &
                    t.episodeId.equals(widget.meta.id),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.num)]))
            .get();
    final progress = await appDb.select(appDb.userProgress).get();
    final progressMap = {for (final p in progress) p.turnId: p.learned};
    if (!mounted) return;
    setState(() {
      _turns = turns;
      _learned.addAll({
        for (final t in turns) t.id: progressMap[t.id] ?? false,
      });
      _loading = false;
    });
  }

  Future<void> _toggleLearned(TurnRow turn) async {
    final now = !(_learned[turn.id] ?? false);
    setState(() => _learned[turn.id] = now);
    await appDb
        .into(appDb.userProgress)
        .insertOnConflictUpdate(
          UserProgressCompanion(
            turnId: Value(turn.id),
            learned: Value(now),
            lastReviewed: Value(DateTime.now()),
          ),
        );
  }

  int get _learnedCount => _learned.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${meta.emoji} ${meta.title}',
              style: const TextStyle(
                color: AppColors.khram,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${meta.level} · 민호 & ฟ้า',
              style: const TextStyle(
                color: AppColors.khramLight,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '이 에피소드 플래시카드',
            icon: const Icon(Icons.style, color: AppColors.kluayMai),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SentenceFlashcardScreen(meta: widget.meta),
                ),
              );
              _load();
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '$_learnedCount/${_turns.length}',
                style: const TextStyle(
                  color: AppColors.kluayMai,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai),
            )
          : Column(
              children: [
                const LaiThaiDivider(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                    itemCount: _turns.length,
                    itemBuilder: (context, i) {
                      final t = _turns[i];
                      return _EpisodeBubble(
                        turn: t,
                        learned: _learned[t.id] ?? false,
                        onLearnedTap: () => _toggleLearned(t),
                        onCardTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SentenceFlashcardScreen(
                                meta: widget.meta,
                                initialIndex: i,
                              ),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _EpisodeBubble extends StatelessWidget {
  final TurnRow turn;
  final bool learned;
  final VoidCallback onLearnedTap;
  final VoidCallback? onCardTap;

  const _EpisodeBubble({
    required this.turn,
    required this.learned,
    required this.onLearnedTap,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final isA = turn.speaker == 'A';
    final bubbleColor = isA ? AppColors.kluayMai : AppColors.thong;
    final bubbleText = isA ? AppColors.cream : AppColors.khram;
    final th = turn.th;

    final bubble = GestureDetector(
      onTap: onCardTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isA ? 4 : 14),
            bottomRight: Radius.circular(isA ? 14 : 4),
          ),
          border: Border.all(
            color: learned ? AppColors.morakot : AppColors.thongDeep,
            width: learned ? 1.6 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableThaiText(
                    text: th,
                    tokens: ChunkIndexService.instance.tokensFor(th),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: bubbleText,
                      height: 1.4,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => TtsService.instance.speakAs(
                    th,
                    gender: isA ? 'male' : 'female',
                  ),
                  child: Icon(
                    Icons.volume_up,
                    size: 16,
                    color: bubbleText.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            if (turn.roman != null) ...[
              const SizedBox(height: 3),
              Text(
                turn.roman!,
                style: TextStyle(
                  fontSize: 11,
                  color: bubbleText.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (turn.ko != null) ...[
              const SizedBox(height: 4),
              Container(height: 0.5, color: bubbleText.withValues(alpha: 0.3)),
              const SizedBox(height: 4),
              Text(
                turn.ko!,
                style: TextStyle(
                  fontSize: 12,
                  color: bubbleText.withValues(alpha: 0.95),
                ),
              ),
            ],
            if (turn.note != null && turn.note!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: isA ? 0.18 : 0.55),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: bubbleText.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '💡 ${turn.note}',
                  style: TextStyle(
                    fontSize: 10,
                    color: bubbleText.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final avatar = Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: bubbleColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            isA ? 'M' : 'ฟ',
            style: const TextStyle(
              color: AppColors.cream,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onLearnedTap,
          child: Icon(
            learned ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: learned ? AppColors.morakot : AppColors.khramLight,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isA
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: isA
            ? [avatar, const SizedBox(width: 6), Flexible(child: bubble)]
            : [Flexible(child: bubble), const SizedBox(width: 6), avatar],
      ),
    );
  }
}
