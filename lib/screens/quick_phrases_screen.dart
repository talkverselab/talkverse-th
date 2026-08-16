import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/thai_decor.dart';

/// 바로 문장 — 태국인이 가장 많이 쓰는 표현 모음.
/// 카테고리 칩 + 큰 카드 + TTS. 여행·일상에서 바로 꺼내 쓰는 코너.
class QuickPhrasesScreen extends StatefulWidget {
  const QuickPhrasesScreen({super.key});

  @override
  State<QuickPhrasesScreen> createState() => _QuickPhrasesScreenState();
}

class _Category {
  final String id;
  final String name;
  final String emoji;
  final List<_Phrase> phrases;
  _Category(this.id, this.name, this.emoji, this.phrases);
}

class _Phrase {
  final String th;
  final String roman;
  final String ko;
  _Phrase(this.th, this.roman, this.ko);
}

class _QuickPhrasesScreenState extends State<QuickPhrasesScreen> {
  List<_Category> _categories = [];
  int _catIdx = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw =
        await rootBundle.loadString('assets/data/phrases/quick_phrases.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final cats = (data['categories'] as List?) ?? [];
    if (!mounted) return;
    setState(() {
      _categories = [
        for (final c in cats.whereType<Map>())
          _Category(
            c['id'] as String? ?? '',
            c['name'] as String? ?? '',
            c['emoji'] as String? ?? '💬',
            [
              for (final p in (c['phrases'] as List? ?? []).whereType<Map>())
                _Phrase(
                  p['th'] as String? ?? '',
                  p['roman'] as String? ?? '',
                  p['ko'] as String? ?? '',
                ),
            ],
          ),
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('바로 문장',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('ประโยคใช้บ่อย',
                style: TextStyle(fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai))
          : Column(
              children: [
                Container(
                  color: AppColors.creamDeep,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final c = _categories[i];
                        final selected = i == _catIdx;
                        return GestureDetector(
                          onTap: () => setState(() => _catIdx = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.kluayMai
                                  : AppColors.cream,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: selected
                                    ? AppColors.kluayMaiDeep
                                    : AppColors.thong.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              '${c.emoji} ${c.name}',
                              style: TextStyle(
                                color: selected
                                    ? AppColors.cream
                                    : AppColors.khram,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const LaiThaiDivider(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: _categories[_catIdx].phrases.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _PhraseCard(phrase: _categories[_catIdx].phrases[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  final _Phrase phrase;
  const _PhraseCard({required this.phrase});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TtsService.instance.speak(phrase.th),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.thong.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.khram.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase.th,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.khram,
                      height: 1.4,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phrase.roman,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.kluayMai,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phrase.ko,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.khramLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.kluayMai.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.kluayMai, width: 0.8),
              ),
              child: const Icon(Icons.volume_up,
                  color: AppColors.kluayMai, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
