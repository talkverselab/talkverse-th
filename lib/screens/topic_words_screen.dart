import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/emoji_service.dart';
import '../services/known_words_store.dart';
import '../services/ko_reading.dart';
import '../services/root_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import '../widgets/vocab_sheet.dart';
import 'thai_roots_screen.dart';
import 'word_flashcard_screen.dart';

/// 한 주제의 단어 타일(3열) — 그림·태국어(루트 밑줄)·독음·뜻·체크박스.
/// 체크된 단어만 플래시카드로 연습. 한→태 / 태→한 전환, 독음 표시 토글.
class TopicWordsScreen extends StatefulWidget {
  final VocabTopic topic;

  /// 지정하면 주제 필터 대신 이 목록을 그대로 쓴다(중요 단어 절벽 단계 등).
  final List<VocabEntry>? entries;

  /// 그림 배정에 쓸 주제 풀 id (entries 지정 시).
  final String emojiTopic;
  const TopicWordsScreen({
    super.key,
    required this.topic,
    this.entries,
    this.emojiTopic = 'core',
  });

  @override
  State<TopicWordsScreen> createState() => _TopicWordsScreenState();
}

class _TopicWordsScreenState extends State<TopicWordsScreen> {
  String? _part; // null = 전체
  bool _koFirst = true; // 한→태 기본
  late List<VocabEntry> _all;
  final Map<String, String> _emoji = {};

  @override
  void initState() {
    super.initState();
    _all =
        widget.entries ??
        VocabService.instance.entries
            .where((e) => e.topic == widget.topic.id)
            .toList();
    _assignEmoji();
  }

  void _assignEmoji() {
    final list = _visible;
    final emojis = EmojiService.instance.assign(
      list.map((e) => e.ko).toList(),
      topic: widget.entries == null ? widget.topic.id : widget.emojiTopic,
    );
    _emoji.clear();
    for (var i = 0; i < list.length; i++) {
      _emoji[list[i].id] = emojis[i];
    }
  }

  List<VocabEntry> get _visible =>
      _part == null ? _all : _all.where((e) => e.part == _part).toList();

  List<VocabEntry> get _checked =>
      _visible.where((e) => KnownWordsStore.isChecked(e.th)).toList();

  void _practice() {
    final words = _checked;
    if (words.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('체크된 단어가 없어요')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordFlashcardScreen(
          title: _part ?? widget.topic.name,
          words: words,
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
        title: ValueListenableBuilder<int>(
          valueListenable: KnownWordsStore.version,
          builder: (context, _, _) {
            final known = _all
                .where((e) => KnownWordsStore.isKnown(e.th))
                .length;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${t.emoji} ${t.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_all.length}단어 · 아는 단어 $known',
                  style: const TextStyle(fontSize: 10, letterSpacing: 2),
                ),
              ],
            );
          },
        ),
        actions: [
          const KoReadingToggleAction(),
          IconButton(
            tooltip: _koFirst ? '한→태 (탭: 태→한)' : '태→한 (탭: 한→태)',
            onPressed: () => setState(() => _koFirst = !_koFirst),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.kluayMai),
                borderRadius: BorderRadius.circular(6),
                color: AppColors.kluayMai.withValues(alpha: 0.08),
              ),
              child: Text(
                _koFirst ? '한→태' : '태→한',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.kluayMai,
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
            child: const Text(
              '아는 단어의 체크는 없애주세요 — 체크된 단어만 플래시카드로 연습합니다',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.thongDeep,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: ValueListenableBuilder<int>(
              valueListenable: KnownWordsStore.version,
              builder: (context, _, _) => SizedBox(
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
                    '플래시카드 연습 · ${_checked.length}개',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
                    _PartChip(
                      label: '전체 ${_all.length}',
                      selected: _part == null,
                      onTap: () => setState(() {
                        _part = null;
                        _assignEmoji();
                      }),
                    ),
                    for (final p in t.parts)
                      _PartChip(
                        label: p,
                        selected: _part == p,
                        onTap: () => setState(() {
                          _part = p;
                          _assignEmoji();
                        }),
                      ),
                  ],
                ),
              ),
            ),
          const LaiThaiDivider(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      '단어가 없어요',
                      style: TextStyle(color: AppColors.khramLight),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _WordTile(
                      entry: list[i],
                      emoji: _emoji[list[i].id] ?? '🔸',
                      koFirst: _koFirst,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PartChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PartChip({
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

/// 단어 타일 — 그림 · (한→태: 뜻 크게 / 태→한: 태국어 크게) · 체크박스 · 재생.
class _WordTile extends StatelessWidget {
  final VocabEntry entry;
  final String emoji;
  final bool koFirst;
  const _WordTile({
    required this.entry,
    required this.emoji,
    required this.koFirst,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return ValueListenableBuilder<int>(
      valueListenable: KnownWordsStore.version,
      builder: (context, _, _) {
        final checked = KnownWordsStore.isChecked(e.th);
        return InkWell(
          onTap: () => showVocabSheet(context, e),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 4, 6),
            decoration: BoxDecoration(
              color: checked
                  ? AppColors.cream
                  : AppColors.creamDeep.withValues(alpha: 0.6),
              border: Border.all(
                color: checked
                    ? AppColors.thong
                    : AppColors.thong.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => TtsService.instance.speak(e.speakable),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.volume_up,
                          size: 16,
                          color: AppColors.kluayMai,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: Checkbox(
                        value: checked,
                        activeColor: AppColors.kluayMai,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (_) => KnownWordsStore.toggle(e.th),
                      ),
                    ),
                  ],
                ),
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: koFirst
                        ? [
                            _koText(e, big: true),
                            const SizedBox(height: 3),
                            _RootUnderlinedThai(th: e.th, fontSize: 15),
                            _reading(e, 11),
                          ]
                        : [
                            _RootUnderlinedThai(th: e.th, fontSize: 19),
                            _reading(e, 11.5),
                            const SizedBox(height: 2),
                            _koText(e, big: false),
                          ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _koText(VocabEntry e, {required bool big}) => Text(
    e.ko,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: big ? 14 : 11.5,
      fontWeight: big ? FontWeight.w900 : FontWeight.w600,
      color: AppColors.khram,
    ),
  );

  Widget _reading(VocabEntry e, double size) => e.reading.isEmpty
      ? const SizedBox.shrink()
      : KoReadingText(
          e.reading,
          th: e.th,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: AppColors.thongDeep,
            fontStyle: FontStyle.italic,
          ),
        );
}

/// 태국어 표제어 — 루트가 들어 있으면 그 부분에 밑줄, 탭하면 루트 메뉴로.
class _RootUnderlinedThai extends StatelessWidget {
  final String th;
  final double fontSize;
  const _RootUnderlinedThai({required this.th, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final word = th.split('/').first.trim();
    final roots = RootService.instance.isLoaded
        ? RootService.instance.rootsOf(word)
        : const <RootInfo>[];
    final self = RootService.instance.isLoaded
        ? RootService.instance.lookup(word)
        : null;
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: AppColors.khram,
      height: 1.25,
      fontFamilyFallback: AppTheme.fontFallback,
    );
    if (roots.isEmpty && self == null) {
      return Text(
        word,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: base,
      );
    }
    // 가장 긴 루트 하나만 밑줄 (겹침 방지)
    final root = self ?? roots.first;
    final idx = word.indexOf(root.th);
    final underline = TextStyle(
      decoration: TextDecoration.underline,
      decorationColor: AppColors.morakot,
      decorationThickness: 2.5,
      color: AppColors.morakot,
    );
    void open() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThaiRootsScreen(focusRoot: root.th, fromWord: word),
      ),
    );
    return GestureDetector(
      onTap: open,
      child: Text.rich(
        TextSpan(
          style: base,
          children: idx < 0
              ? [TextSpan(text: word, style: underline)]
              : [
                  TextSpan(text: word.substring(0, idx)),
                  TextSpan(text: root.th, style: underline),
                  TextSpan(text: word.substring(idx + root.th.length)),
                ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
