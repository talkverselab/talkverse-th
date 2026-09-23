import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/memo_toggle.dart';
import '../widgets/thai_decor.dart';

/// 초급 문법 코스의 한 과 — `assets/data/grammar/lessons.json` 의 lesson 하나.
/// 카드 = 문법 형태(예: ได้ + 동사) · 독음 · 이름 · 설명 · 예문(태국어 · 독음 · 뜻, 탭하면 읽어 줌).
class GrammarLesson {
  final String id;
  final String emoji;
  final String title;
  final String sub;
  final String intro;
  final List<GrammarItem> items;
  GrammarLesson({
    required this.id,
    required this.emoji,
    required this.title,
    required this.sub,
    required this.intro,
    required this.items,
  });

  factory GrammarLesson.fromJson(Map<String, dynamic> m) => GrammarLesson(
        id: m['id'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '',
        title: m['title'] as String? ?? '',
        sub: m['sub'] as String? ?? '',
        intro: m['intro'] as String? ?? '',
        items: ((m['items'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => GrammarItem.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class GrammarItem {
  final String form;
  final String roman;
  final String nameKo;
  final String desc;
  final List<({String th, String roman, String ko})> examples;
  GrammarItem({
    required this.form,
    required this.roman,
    required this.nameKo,
    required this.desc,
    required this.examples,
  });

  factory GrammarItem.fromJson(Map<String, dynamic> m) => GrammarItem(
        form: m['form'] as String? ?? '',
        roman: m['roman'] as String? ?? '',
        nameKo: m['nameKo'] as String? ?? '',
        desc: m['desc'] as String? ?? '',
        examples: ((m['examples'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => (
                  th: e['th'] as String? ?? '',
                  roman: e['roman'] as String? ?? '',
                  ko: e['ko'] as String? ?? '',
                ))
            .toList(),
      );

  /// 카드 머리의 엠블럼에 넣을 짧은 태국어 — 형태에서 첫 태국어 낱말만.
  String get emblem {
    final m = RegExp('[฀-๿]+').firstMatch(form);
    if (m == null) return '文';
    final w = m.group(0)!;
    return w.length > 4 ? w.substring(0, 4) : w;
  }

  /// 예문에서 강조할 조각 — 형태 안의 태국어 낱말들.
  List<String> get highlights =>
      RegExp('[฀-๿]+').allMatches(form).map((m) => m.group(0)!).where((w) => w.length >= 2).toList();
}

class GrammarTopicScreen extends StatelessWidget {
  final GrammarLesson lesson;
  final int index;
  const GrammarTopicScreen({super.key, required this.lesson, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${lesson.emoji} ${lesson.title}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(lesson.sub,
                style: const TextStyle(fontSize: 10, letterSpacing: 0.5, fontFamilyFallback: AppTheme.fontFallback)),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.creamDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.thong.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.kluayMaiDeep)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(lesson.intro,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.khram)),
                ),
              ],
            ),
          ),
          const LaiThaiDivider(height: 14),
          for (var i = 0; i < lesson.items.length; i++) ...[
            _ItemCard(item: lesson.items[i], lessonId: lesson.id, idx: i),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ItemCard extends StatefulWidget {
  final GrammarItem item;
  final String lessonId;
  final int idx;
  const _ItemCard({required this.item, required this.lessonId, required this.idx});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    const accent = Color(0xFFAD1457);
    return ThaiCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GoldEmblem(text: item.emblem, size: 44, color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.form,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.khram,
                                fontFamilyFallback: AppTheme.fontFallback)),
                        const SizedBox(height: 2),
                        Text(item.nameKo,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: accent)),
                        if (item.roman.isNotEmpty)
                          Text(item.roman, style: const TextStyle(fontSize: 11, color: AppColors.khramLight)),
                      ],
                    ),
                  ),
                  if (item.highlights.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 20, color: AppColors.kluayMai),
                      onPressed: () => TtsService.instance.speak(item.highlights.first),
                    ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.khramLight),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.thong),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.desc,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.khram, height: 1.5, fontFamilyFallback: AppTheme.fontFallback)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < item.examples.length; i++) ...[
                    _ExampleRow(
                      th: item.examples[i].th,
                      roman: item.examples[i].roman,
                      ko: item.examples[i].ko,
                      highlights: item.highlights,
                    ),
                    MemoToggle(
                      patternId: 'gram_${widget.lessonId}_${widget.idx}',
                      idx: i,
                      sentence: item.examples[i].th,
                    ),
                    if (i < item.examples.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final String th;
  final String roman;
  final String ko;
  final List<String> highlights;
  const _ExampleRow({required this.th, required this.roman, required this.ko, required this.highlights});

  /// 형태에 든 낱말이 예문에 있으면 그 부분만 진하게.
  List<TextSpan> _spans() {
    final spans = <TextSpan>[];
    var pos = 0;
    while (pos < th.length) {
      int best = -1;
      String bestWord = '';
      for (final w in highlights) {
        final i = th.indexOf(w, pos);
        if (i >= 0 && (best < 0 || i < best || (i == best && w.length > bestWord.length))) {
          best = i;
          bestWord = w;
        }
      }
      if (best < 0) {
        spans.add(TextSpan(text: th.substring(pos)));
        break;
      }
      if (best > pos) spans.add(TextSpan(text: th.substring(pos, best)));
      spans.add(TextSpan(
          text: bestWord,
          style: const TextStyle(color: AppColors.kluayMaiDeep, fontWeight: FontWeight.w900)));
      pos = best + bestWord.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TtsService.instance.speak(th),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.creamDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.thong.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: RichText(text: TextSpan(style: _thStyle, children: _spans()))),
                const Icon(Icons.volume_up, size: 14, color: AppColors.khramLight),
              ],
            ),
            if (roman.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(roman, style: const TextStyle(fontSize: 11.5, color: AppColors.kluayMaiDeep)),
            ],
            const SizedBox(height: 2),
            Text(ko, style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
          ],
        ),
      ),
    );
  }

  static const _thStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.khram,
    height: 1.5,
    fontFamilyFallback: AppTheme.fontFallback,
  );
}

/// 화면 문구 사전용 — tr() 키를 한곳에.
String grammarTopicTitle() => tr('초급 문법 코스');
