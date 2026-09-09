import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/known_words_store.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import 'topic_words_screen.dart';
import 'word_flashcard_screen.dart';

/// 중요 단어 단계 — 중요 1000단어(절벽 구간은 안에서 칩으로) + 표준(최대).
class ImportantStage {
  final String id;
  final String badge; // 큰 숫자 칸
  final String label;
  final String range;
  final String desc;
  final String stars;
  final List<VocabEntry> Function() entries;
  const ImportantStage({
    required this.id,
    required this.badge,
    required this.label,
    required this.range,
    required this.desc,
    required this.stars,
    required this.entries,
  });
}

/// 중요 단어 — 회화 빈도 절벽 구간별 단계. 단계를 고르면 단어 타일 화면.
class ImportantWordsScreen extends StatelessWidget {
  const ImportantWordsScreen({super.key});

  static List<VocabEntry> _levels(int from, int to) =>
      VocabService.instance.entries
          .where((e) => e.level >= from && e.level <= to)
          .toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));

  /// 빈도 단계 → 편 이름 (중요 1000단어 안의 칩).
  static String tierName(int level) => switch (level) {
    1 || 2 => '1~2단계 · ~250위',
    3 => '3단계 · ~500위',
    4 => '4단계 · ~750위',
    _ => '5단계 · ~1000위',
  };

  static const tierParts = ['1~2단계 · ~250위', '3단계 · ~500위', '4단계 · ~750위', '5단계 · ~1000위'];

  static final stages = <ImportantStage>[
    ImportantStage(
      id: 'top1000',
      badge: '1000',
      label: '중요 1000단어',
      range: '회화 빈도 1 ~ 1000위',
      desc: '영화·드라마 회화에서 가장 자주 쓰는 단어. 안에서 절벽 구간(1~2 / 3 / 4 / 5단계)별로 볼 수 있어요',
      stars: '★★★★★',
      entries: () => _levels(1, 5),
    ),
    ImportantStage(
      id: 'std',
      badge: '표준',
      label: '표준 단어',
      range: '1000위 밖',
      desc: '교육부 기초 단어(ป.1~3) 중 빈도 1000에 없는 단어 — 여기까지가 최대',
      stars: '',
      entries: () =>
          VocabService.instance.standardExtraEntries
            ..sort((a, b) => a.order.compareTo(b.order)),
    ),
  ];

  /// 전체(최대 범위) — 빈도 1000 + 표준.
  static List<VocabEntry> get all => VocabService.instance.standardEntries;

  void _open(BuildContext context, ImportantStage? stage) {
    final list = stage == null ? all : stage.entries();
    final name = stage == null ? '중요 단어 전체' : stage.label;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicWordsScreen(
          topic: VocabTopic(
            stage?.id ?? 'std_all',
            name,
            '⭐',
            list.length,
            stage?.id == 'top1000' ? tierParts : const [],
          ),
          entries: list,
          partOf: stage?.id == 'top1000'
              ? (e) => tierName(e.level)
              : null,
        ),
      ),
    );
  }

  void _practice(BuildContext context) {
    final words = all.where((e) => KnownWordsStore.isChecked(e.th)).toList()
      ..shuffle();
    if (words.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordFlashcardScreen(title: '중요 단어', words: words),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = all.length;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '중요 단어',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              '중요 1000단어 + 표준 단어 · $total단어',
              style: const TextStyle(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: KnownWordsStore.version,
        builder: (context, _, _) {
          final checked = all
              .where((e) => KnownWordsStore.isChecked(e.th))
              .length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kluayMai,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _practice(context),
                  icon: const Icon(Icons.style),
                  label: Text(
                    '플래시카드 연습 · 체크된 단어 $checked개',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '영화·드라마 회화 빈도 순위를 절벽 구간으로 나눴어요. '
                  '중요 1000단어를 먼저 익히고, 표준 단어까지가 이 앱의 최대 범위입니다.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.khramLight,
                    height: 1.4,
                  ),
                ),
              ),
              const LaiThaiDivider(height: 8),
              for (final stage in stages)
                _StageCard(
                  stage: stage,
                  entries: stage.entries(),
                  onTap: () => _open(context, stage),
                ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.khram,
                  side: const BorderSide(color: AppColors.kluayMai),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _open(context, null),
                icon: const Icon(Icons.list),
                label: Text(
                  '전체 한눈에 · $total단어',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final ImportantStage stage;
  final List<VocabEntry> entries;
  final VoidCallback onTap;
  const _StageCard({
    required this.stage,
    required this.entries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final known = entries.where((e) => KnownWordsStore.isKnown(e.th)).length;
    final progress = entries.isEmpty ? 0.0 : known / entries.length;
    final isStd = stage.id == 'std';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.cream,
            border: Border.all(
              color: (isStd ? AppColors.thongDeep : AppColors.kluayMai)
                  .withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isStd ? AppColors.thongDeep : AppColors.kluayMai)
                      .withValues(alpha: 0.12),
                  border: Border.all(
                    color: isStd ? AppColors.thongDeep : AppColors.kluayMai,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  stage.badge,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isStd ? AppColors.thongDeep : AppColors.kluayMaiDeep,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          stage.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.khram,
                          ),
                        ),
                        if (stage.stars.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            stage.stars,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.thongDeep,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          stage.range,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kluayMaiDeep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stage.desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.khramLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: AppColors.creamDeep,
                            color: AppColors.morakot,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entries.length}단어 · 아는 단어 $known',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.khramLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.khramLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
