import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../screens/thai_roots_screen.dart';
import '../services/memorized_store.dart';
import '../services/root_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import 'thai_decor.dart';

/// 단어에 들어있는 루트 단어 칩 — 탭하면 루트 가족 화면으로.
class RootChips extends StatelessWidget {
  final String th;
  final double fontSize;
  final bool showLabel;
  const RootChips({
    super.key,
    required this.th,
    this.fontSize = 11,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final roots = RootService.instance.rootsOf(th);
    final self = RootService.instance.lookup(th.trim());
    if (roots.isEmpty && self == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showLabel)
          const Text(
            '루트',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.khramLight,
              letterSpacing: 1.5,
            ),
          ),
        if (self != null)
          _RootChip(root: self, fontSize: fontSize, isSelf: true, fromWord: th),
        for (final r in roots)
          _RootChip(root: r, fontSize: fontSize, fromWord: th),
      ],
    );
  }
}

class _RootChip extends StatelessWidget {
  final RootInfo root;
  final double fontSize;
  final bool isSelf;
  final String fromWord;
  const _RootChip({
    required this.root,
    required this.fontSize,
    required this.fromWord,
    this.isSelf = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelf ? AppColors.kluayMai : AppColors.thongDeep;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ThaiRootsScreen(focusRoot: root.th, fromWord: fromWord),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelf ? 0.14 : 0.08),
          border: Border.all(color: color.withValues(alpha: 0.7), width: 0.8),
        ),
        child: Text(
          isSelf
              ? '★ ${root.th} ${root.reading} · ${root.ko}'
              : '${root.th} ${root.reading} · ${root.ko}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamilyFallback: AppTheme.fontFallback,
          ),
        ),
      ),
    );
  }
}

/// 단어 상세 하단 시트.
Future<void> showVocabSheet(BuildContext context, VocabEntry entry) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cream,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        child: VocabDetail(entry: entry),
      ),
    ),
  );
}

class VocabDetail extends StatelessWidget {
  final VocabEntry entry;
  const VocabDetail({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.th,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.khram,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                      if (e.reading.isNotEmpty)
                        Text(
                          e.reading,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kluayMaiDeep,
                          ),
                        ),
                    ],
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: MemorizedStore.version,
                  builder: (context, _, _) {
                    final on = MemorizedStore.contains(e.th);
                    return IconButton(
                      tooltip: on ? '외움 해제' : '외웠어요',
                      onPressed: () => MemorizedStore.toggle(e.th),
                      icon: Icon(
                        on ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: on
                            ? AppColors.kluayMai
                            : AppColors.khramLight.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up,
                      color: AppColors.kluayMai, size: 28),
                  onPressed: () => TtsService.instance.speak(e.speakable),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              e.ko,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.khram,
              ),
            ),
            const SizedBox(height: 10),
            RootChips(th: e.th, fontSize: 12, showLabel: true),
            const SizedBox(height: 12),
            const LaiThaiDivider(height: 10),
            const SizedBox(height: 8),
            Text(
              [
                if (e.level > 0) e.levelLabel,
                if (e.sourceLabel.isNotEmpty) e.sourceLabel,
                if (e.uncertain) '판독 불확실',
              ].join('  ·  '),
              style: const TextStyle(fontSize: 11, color: AppColors.khramLight),
            ),
          ],
        ),
      ),
    );
  }
}

/// 단어 목록 행 (단어장·루트 가족 공용).
class VocabRow extends StatelessWidget {
  final VocabEntry entry;
  final String? highlightRoot;
  final bool dense;
  const VocabRow({
    super.key,
    required this.entry,
    this.highlightRoot,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return InkWell(
      onTap: () => showVocabSheet(context, e),
      child: Container(
        color: AppColors.cream,
        padding: EdgeInsets.symmetric(
            horizontal: 14, vertical: dense ? 7 : 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedThai(
                    text: e.th,
                    highlight: highlightRoot,
                    fontSize: dense ? 18 : 20,
                  ),
                  Text(
                    e.reading.isNotEmpty ? '${e.reading}  ·  ${e.ko}' : e.ko,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.khram,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (e.level > 0)
                    Text(
                      e.levelStars,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.thongDeep),
                    ),
                  if (highlightRoot != null)
                    _PieceLine(word: e.variants.first, root: highlightRoot!),
                  if (!dense) ...[
                    const SizedBox(height: 4),
                    RootChips(th: e.th, fontSize: 10),
                  ],
                ],
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: MemorizedStore.version,
              builder: (context, _, _) {
                final on = MemorizedStore.contains(e.th);
                return IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: on ? '외움 해제' : '외웠어요',
                  onPressed: () => MemorizedStore.toggle(e.th),
                  icon: Icon(
                    on ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: on
                        ? AppColors.kluayMai
                        : AppColors.khramLight.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.volume_up,
                  size: 18, color: AppColors.kluayMai),
              onPressed: () => TtsService.instance.speak(e.speakable),
            ),
          ],
        ),
      ),
    );
  }
}

/// 루트 + 나머지 조각의 뜻: "น้ำ(물) + แข็ง(딱딱하다)".
class _PieceLine extends StatelessWidget {
  final String word;
  final String root;
  const _PieceLine({required this.word, required this.root});

  @override
  Widget build(BuildContext context) {
    final pieces = RootService.instance.breakdown(word, root);
    if (pieces.length < 2) return const SizedBox.shrink();
    final text = pieces
        .map((p) => p.ko == null || p.ko!.isEmpty ? p.th : '${p.th}(${p.ko})')
        .join(' + ');
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.thongDeep,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.fontFallback,
        ),
      ),
    );
  }
}

class _HighlightedThai extends StatelessWidget {
  final String text;
  final String? highlight;
  final double fontSize;
  const _HighlightedThai({
    required this.text,
    required this.fontSize,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: AppColors.khram,
      fontFamilyFallback: AppTheme.fontFallback,
    );
    final h = highlight;
    if (h == null || h.isEmpty || !text.contains(h)) {
      return Text(text, style: base);
    }
    final idx = text.indexOf(h);
    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: h,
            style: base.copyWith(
              color: AppColors.kluayMai,
              backgroundColor: AppColors.thongBright.withValues(alpha: 0.35),
            ),
          ),
          TextSpan(text: text.substring(idx + h.length)),
        ],
      ),
    );
  }
}
