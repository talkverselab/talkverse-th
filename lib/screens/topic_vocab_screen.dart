import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/emoji_service.dart';
import '../services/known_words_store.dart';
import '../services/root_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import 'topic_words_screen.dart';
import 'vocab_screen.dart';
import 'word_flashcard_screen.dart';
import '../core/l10n.dart';
import '../core/platform.dart';

/// 주제별 단어 — 주제 타일 그리드 + 맨 위 플래시카드 연습 버튼.
class TopicVocabScreen extends StatefulWidget {
  const TopicVocabScreen({super.key});

  @override
  State<TopicVocabScreen> createState() => _TopicVocabScreenState();
}

class _TopicVocabScreenState extends State<TopicVocabScreen> {
  bool _loading = true;
  List<VocabTopic> _topics = [];

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
    try {
      final raw = await rootBundle.loadString(
        'assets/data/vocab/th_topics.json',
      );
      final data = json.decode(raw) as Map<String, dynamic>;
      _topics = [
        for (final t in (data['topics'] as List).whereType<Map>())
          VocabTopic(
            '${t['id']}',
            '${t['name']}',
            '${t['emoji'] ?? '📖'}',
            (t['count'] as num?)?.toInt() ?? 0,
            [
              for (final p in (t['parts'] as List? ?? []).whereType<Map>())
                '${p['name']}',
            ],
          ),
      ];
    } catch (_) {
      _topics = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _practiceAll() {
    final words =
        VocabService.instance.entries
            .where((e) => KnownWordsStore.isChecked(e.th))
            .toList()
          ..shuffle();
    if (words.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordFlashcardScreen(title: tr('전체 단어'), words: words),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = VocabService.instance.count;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('주제별 단어'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              trf('태국어 · {0}항목', [total]),
              style: const TextStyle(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('전체 검색'),
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
          : Column(
              children: [
                const LaiThaiDivider(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: ValueListenableBuilder<int>(
                    valueListenable: KnownWordsStore.version,
                    builder: (context, _, _) {
                      final n = VocabService.instance.entries
                          .where((e) => KnownWordsStore.isChecked(e.th))
                          .length;
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.kluayMai,
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _practiceAll,
                          icon: const Icon(Icons.style),
                          label: Text(
                            trf('플래시카드 연습 · 체크된 단어 {0}개', [n]),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.45,
                        ),
                    itemCount: _topics.length,
                    itemBuilder: (context, i) {
                      final t = _topics[i];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TopicWordsScreen(topic: t),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            border: Border.all(
                              color: AppColors.kluayMai.withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t.emoji,
                                style: const TextStyle(fontSize: 30),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.khram,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trf('{0}편 · {1}단어', [t.parts.length, t.count]),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.khramLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
