import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/emoji_service.dart';
import '../services/known_words_store.dart';
import '../services/root_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import 'important_words_screen.dart';
import 'topic_vocab_screen.dart';
import 'vocab_screen.dart';

/// 단어장 — 주제별 / 중요 단어(절벽 구간별) 두 갈래.
class VocabHubScreen extends StatefulWidget {
  const VocabHubScreen({super.key});

  @override
  State<VocabHubScreen> createState() => _VocabHubScreenState();
}

class _VocabHubScreenState extends State<VocabHubScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await VocabService.instance.ensureLoaded();
    await RootService.instance.ensureLoaded();
    await EmojiService.instance.ensureLoaded();
    await KnownWordsStore.load();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final entries = VocabService.instance.entries;
    final topics = entries
        .map((e) => e.topic)
        .where((t) => t.isNotEmpty)
        .toSet();
    final important = VocabService.instance.standardEntries.length;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '단어장',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              '태국어 · ${entries.length}항목',
              style: const TextStyle(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '전체 검색',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VocabScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const LaiThaiDivider(height: 8),
                const SizedBox(height: 8),
                _HubCard(
                  emoji: '📚',
                  title: '주제별 단어',
                  sub: '${topics.length}주제 · 편별 타일 · 그림·체크박스',
                  desc: '기본·음식·쇼핑·여행·교통… 상황별로 묶어 익혀요.',
                  color: AppColors.kluayMaiDeep,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TopicVocabScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  emoji: '⭐',
                  title: '중요 단어',
                  sub: '중요 1,000단어 + 표준 단어 · 최대 $important단어',
                  desc: '회화 빈도 1000단어 → 교육부 표준 단어 순서로.',
                  color: AppColors.thongDeep,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ImportantWordsScreen(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  const _HubCard({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border.all(color: color.withValues(alpha: 0.75), width: 1.4),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.khram,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.khramLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
