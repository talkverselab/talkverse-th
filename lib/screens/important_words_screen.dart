import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/known_words_store.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import 'topic_words_screen.dart';
import 'word_flashcard_screen.dart';

/// 중요 단어 — 회화 빈도 절벽 구간별 5단계. 단계를 고르면 단어 타일 화면.
class ImportantWordsScreen extends StatelessWidget {
  const ImportantWordsScreen({super.key});

  /// 절벽 구간: (단계, 순위 범위 라벨, 설명)
  static const stages = <(int, String, String)>[
    (1, '1 ~ 100위', '회화의 절반 이상을 차지하는 핵심 중의 핵심'),
    (2, '101 ~ 250위', '이 구간까지 알면 일상 회화 대부분이 들려요'),
    (3, '251 ~ 500위', '자막·드라마 대사의 뼈대가 되는 단어'),
    (4, '501 ~ 750위', '상황별 회화를 넓혀 주는 단어'),
    (5, '751 ~ 1000위', '절벽 아래 — 알면 표현이 풍부해지는 단어'),
  ];

  static List<VocabEntry> entriesOf(int level) =>
      VocabService.instance.entries.where((e) => e.level == level).toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));

  static List<VocabEntry> get all =>
      VocabService.instance.entries.where((e) => e.level > 0).toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));

  void _open(BuildContext context, int level) {
    final list = level == 0 ? all : entriesOf(level);
    final name = level == 0 ? '중요 단어 전체' : '중요 단어 $level단계';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicWordsScreen(
          topic: VocabTopic('level$level', name, '⭐', list.length, const []),
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
              '회화 빈도 절벽 구간 · $total단어',
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
                  '1단계부터 차례로 익히면 가장 적은 단어로 가장 많이 알아듣습니다.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.khramLight,
                    height: 1.4,
                  ),
                ),
              ),
              const LaiThaiDivider(height: 8),
              for (final (level, range, desc) in stages)
                _StageCard(
                  level: level,
                  range: range,
                  desc: desc,
                  entries: entriesOf(level),
                  onTap: () => _open(context, level),
                ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.khram,
                  side: const BorderSide(color: AppColors.kluayMai),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _open(context, 0),
                icon: const Icon(Icons.list),
                label: Text(
                  '전체 1~5단계 한눈에 · $total단어',
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
  final int level;
  final String range;
  final String desc;
  final List<VocabEntry> entries;
  final VoidCallback onTap;
  const _StageCard({
    required this.level,
    required this.range,
    required this.desc,
    required this.entries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final known = entries.where((e) => KnownWordsStore.isKnown(e.th)).length;
    final stars = '★' * (6 - level) + '☆' * (level - 1);
    final progress = entries.isEmpty ? 0.0 : known / entries.length;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.cream,
            border: Border.all(
              color: AppColors.kluayMai.withValues(alpha: 0.7),
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
                  color: AppColors.kluayMai.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.kluayMai, width: 1.2),
                ),
                child: Text(
                  '$level',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.kluayMaiDeep,
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
                          '$level단계',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.khram,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          stars,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.thongDeep,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          range,
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
                      desc,
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
