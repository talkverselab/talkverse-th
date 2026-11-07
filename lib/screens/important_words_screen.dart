import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/known_words_store.dart';
import '../services/cliff_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import 'topic_words_screen.dart';
import 'word_flashcard_screen.dart';
import '../core/l10n.dart';
import '../core/platform.dart';

/// 중요 단어 단계 — 중요 1,000단어 + 표준(최대).
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

/// 중요 단어 — 회화 빈도 **절벽구간(R1~R5)** 단계 + 표준(절벽 밖). 단계를 고르면 단어 타일 화면.
/// 구간은 `CliffService`(절벽 단어·루트 단어와 같은 기준, 사용자 지시 2026-11-07 "회화 기준 절벽구간으로 함께 구성").
class ImportantWordsScreen extends StatelessWidget {
  const ImportantWordsScreen({super.key});

  static List<VocabEntry> _region(String g) =>
      VocabService.instance.entries.where((e) => CliffService.instance.regionOf(e.th) == g).toList()
        ..sort((a, b) => (CliffService.instance.rankOf(a.th) ?? 99999).compareTo(CliffService.instance.rankOf(b.th) ?? 99999));

  static const _stars = {'R1': '★★★★★', 'R2': '★★★★', 'R3': '★★★', 'R4': '★★', 'R5': '★'};
  static const _pct = {'R1': '55%', 'R2': '60%', 'R3': '70%', 'R4': '80%', 'R5': '92%'};

  static List<ImportantStage> get stages => <ImportantStage>[
    for (var i = 1; i <= 5; i++)
      ImportantStage(
        id: 'R$i',
        badge: 'R$i',
        label: trf('절벽 R{0}', [i]),
        range: CliffService.rangeLabel('R$i').substring(5),
        desc: trf('회화 대사의 누적 {0}까지 덮는 구간', [_pct['R$i']!]),
        stars: _stars['R$i']!,
        entries: () => _region('R$i'),
      ),
    ImportantStage(
      id: 'std',
      badge: tr('표준'),
      label: tr('표준 단어'),
      range: tr('2,000위 밖'),
      desc: tr('교육부 기초 단어(ป.1~3) 중 절벽구간에 없는 단어 — 여기까지가 최대'),
      stars: '',
      entries: () =>
          VocabService.instance.standardEntries.where((e) => CliffService.instance.regionOf(e.th) == null || CliffService.instance.regionOf(e.th) == 'C').toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
    ),
  ];

  /// 전체(최대 범위) — 빈도 + 표준.
  static List<VocabEntry> get all => VocabService.instance.standardEntries;

  void _open(BuildContext context, ImportantStage? stage) {
    final list = stage == null ? all : stage.entries();
    final name = stage == null ? tr('중요 단어 전체') : stage.label;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicWordsScreen(
          topic: VocabTopic(
            stage?.id ?? 'std_all',
            name,
            '⭐',
            list.length,
            const [],
          ),
          entries: list,

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
        builder: (_) => WordFlashcardScreen(title: tr('중요 단어'), words: words),
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
            Text(
              tr('중요 단어'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              trf('절벽구간 R1~R5 + 표준 단어 · {0}단어', [total]),
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
            padding: EdgeInsets.fromLTRB(16, 10, 16, 24 + bottomInset(context)),
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
                    trf('플래시카드 연습 · 체크된 단어 {0}개', [checked]),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  tr('회화 빈도 절벽구간 R1부터 차례로 익히고, ') +
                  tr('표준 단어까지가 이 앱의 최대 범위입니다.'),
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
                  trf('전체 한눈에 · {0}단어', [total]),
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
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isStd ? AppColors.thongDeep : AppColors.kluayMai)
                      .withValues(alpha: 0.12),
                  border: Border.all(
                    color: isStd ? AppColors.thongDeep : AppColors.kluayMai,
                    width: 1.2,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    stage.badge,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isStd
                          ? AppColors.thongDeep
                          : AppColors.kluayMaiDeep,
                    ),
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
                        Flexible(
                          child: Text(
                            stage.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.khram,
                            ),
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
                      ],
                    ),
                    Text(
                      stage.range,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kluayMaiDeep,
                      ),
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
                        Flexible(
                          child: Text(
                            trf('{0}단어 · 아는 단어 {1}', [entries.length, known]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.khramLight,
                            ),
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
