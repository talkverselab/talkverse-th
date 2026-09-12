import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/known_words_store.dart';
import '../services/ko_reading.dart';
import '../services/root_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import '../widgets/vocab_sheet.dart';
import 'word_flashcard_screen.dart';
import '../core/l10n.dart';

/// 표현학습 — 단어장에서 분리한 문장·표현을 주제별로. 주제 타일 → 표현 카드 목록.
class ExpressionsScreen extends StatefulWidget {
  const ExpressionsScreen({super.key});

  @override
  State<ExpressionsScreen> createState() => _ExpressionsScreenState();
}

class _ExpressionsScreenState extends State<ExpressionsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await VocabService.instance.ensureLoaded();
    await RootService.instance.ensureLoaded();
    await KnownWordsStore.load();
    if (mounted) setState(() => _loading = false);
  }

  void _practiceAll() {
    final items =
        VocabService.instance.expressions
            .where((e) => KnownWordsStore.isChecked(e.th))
            .toList()
          ..shuffle();
    if (items.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordFlashcardScreen(title: tr('전체 표현'), words: items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = VocabService.instance;
    final topics = _loading ? const <VocabTopic>[] : svc.expressionTopics;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('표현학습'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              trf('주제별 문장·표현 · {0}개', [svc.expressions.length]),
              style: const TextStyle(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
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
                  child: SizedBox(
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
                        tr('플래시카드 연습 · 체크된 표현'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.45,
                        ),
                    itemCount: topics.length,
                    itemBuilder: (context, i) {
                      final t = topics[i];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _TopicExpressionsScreen(topic: t),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            border: Border.all(
                              color: AppColors.morakot.withValues(alpha: 0.8),
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
                                trf('{0}편 · {1}표현', [t.parts.length, t.count]),
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

/// 한 주제의 표현 카드 목록 — 편 칩 · 카드(태국어·독음·뜻·재생·체크) · 플래시카드.
class _TopicExpressionsScreen extends StatefulWidget {
  final VocabTopic topic;
  const _TopicExpressionsScreen({required this.topic});

  @override
  State<_TopicExpressionsScreen> createState() =>
      _TopicExpressionsScreenState();
}

class _TopicExpressionsScreenState extends State<_TopicExpressionsScreen> {
  String? _part;
  bool _koFirst = true;
  late final List<VocabEntry> _all = VocabService.instance.expressions
      .where((e) => e.topic == widget.topic.id)
      .toList();

  List<VocabEntry> get _visible =>
      _part == null ? _all : _all.where((e) => e.part == _part).toList();

  void _practice() {
    final items = _visible
        .where((e) => KnownWordsStore.isChecked(e.th))
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('체크된 표현이 없어요'))));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordFlashcardScreen(
          title: _part ?? widget.topic.name,
          words: items,
          koFirst: _koFirst,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.topic;
    final list = _visible;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${t.emoji} ${t.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              trf('표현 {0}개', [_all.length]),
              style: const TextStyle(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          const KoReadingToggleAction(),
          IconButton(
            tooltip: _koFirst ? tr('한→태 (탭: 태→한)') : tr('태→한 (탭: 한→태)'),
            onPressed: () => setState(() => _koFirst = !_koFirst),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.kluayMai),
                borderRadius: BorderRadius.circular(6),
                color: AppColors.kluayMai.withValues(alpha: 0.08),
              ),
              child: Text(
                _koFirst ? tr('한→태') : tr('태→한'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.kluayMaiDeep,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.thongBright.withValues(alpha: 0.18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              tr('아는 표현의 체크는 없애주세요 — 체크된 표현만 플래시카드로 연습합니다'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.thongDeep,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kluayMai,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _practice,
                icon: const Icon(Icons.style),
                label: Text(
                  tr('플래시카드 연습'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          if (t.parts.length > 1)
            Container(
              color: AppColors.creamDeep,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Chip(
                      label: trf('전체 {0}', [_all.length]),
                      selected: _part == null,
                      onTap: () => setState(() => _part = null),
                    ),
                    for (final p in t.parts)
                      _Chip(
                        label: p,
                        selected: _part == p,
                        onTap: () => setState(() => _part = p),
                      ),
                  ],
                ),
              ),
            ),
          const LaiThaiDivider(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _ExprCard(entry: list[i], koFirst: _koFirst),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.thongDeep : AppColors.cream,
            border: Border.all(color: AppColors.thongDeep, width: 0.8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.khram,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExprCard extends StatelessWidget {
  final VocabEntry entry;
  final bool koFirst;
  const _ExprCard({required this.entry, required this.koFirst});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return ValueListenableBuilder<int>(
      valueListenable: KnownWordsStore.version,
      builder: (context, _, _) {
        final checked = KnownWordsStore.isChecked(e.th);
        final thText = Text(
          e.th,
          style: TextStyle(
            fontSize: koFirst ? 17 : 21,
            fontWeight: FontWeight.w900,
            color: AppColors.khram,
            height: 1.35,
            fontFamilyFallback: AppTheme.fontFallback,
          ),
        );
        final koText = Text(
          e.ko,
          style: TextStyle(
            fontSize: koFirst ? 16 : 13.5,
            fontWeight: koFirst ? FontWeight.w900 : FontWeight.w600,
            color: koFirst ? AppColors.khram : AppColors.khramLight,
          ),
        );
        return InkWell(
          onTap: () => TtsService.instance.speak(e.speakable),
          onLongPress: () => showVocabSheet(context, e),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(
              color: checked
                  ? Colors.white
                  : AppColors.creamDeep.withValues(alpha: 0.6),
              border: Border(
                left: BorderSide(
                  color: checked ? AppColors.morakot : AppColors.thong,
                  width: 3,
                ),
                bottom: BorderSide(
                  color: AppColors.thong.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: koFirst
                        ? [
                            koText,
                            const SizedBox(height: 4),
                            thText,
                            _reading(e),
                            RootChips(th: e.th, fontSize: 10),
                          ]
                        : [
                            thText,
                            _reading(e),
                            const SizedBox(height: 4),
                            koText,
                            RootChips(th: e.th, fontSize: 10),
                          ],
                  ),
                ),
                Column(
                  children: [
                    Checkbox(
                      value: checked,
                      activeColor: AppColors.kluayMai,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) => KnownWordsStore.toggle(e.th),
                    ),
                    const Icon(
                      Icons.volume_up,
                      size: 20,
                      color: AppColors.kluayMai,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reading(VocabEntry e) => e.reading.isEmpty
      ? const SizedBox.shrink()
      : KoReadingText(
          e.reading,
          th: e.th,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.kluayMaiDeep,
          ),
        );
}
