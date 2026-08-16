import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/chunk_index_service.dart';
import '../services/thai_dict_service.dart';
import '../services/tts_service.dart';
import 'thai_decor.dart';

/// 태국어 문장을 청크(단어) 단위로 탭할 수 있게 렌더링.
///
/// 사전에 있는 청크(compound)는 탭하면 하단 시트로
/// 빈도 정보·TTS·용례 문장을 보여준다.
class SelectableThaiText extends StatelessWidget {
  final String text;
  final List<Map<String, dynamic>> tokens;
  final TextStyle style;
  final String? highlightText;

  const SelectableThaiText({
    super.key,
    required this.text,
    required this.tokens,
    required this.style,
    this.highlightText,
  });

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return Text(text, style: style);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final t in tokens)
          if (t['compound'] == true)
            _TappableChunk(
              text: t['text'] as String,
              style: style,
              highlighted: highlightText != null &&
                  (t['text'] as String).contains(highlightText!),
            )
          else
            Text(t['text'] as String, style: style),
      ],
    );
  }
}

class _TappableChunk extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool highlighted;
  const _TappableChunk({
    required this.text,
    required this.style,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showChunkSheet(context, text),
      child: Container(
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.thongBright.withValues(alpha: 0.45)
              : null,
          border: Border(
            bottom: BorderSide(
              color: (style.color ?? AppColors.khram).withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
        ),
        child: Text(text, style: style),
      ),
    );
  }
}

/// 청크 상세 하단 시트 — 빈도·TTS·용례.
Future<void> showChunkSheet(BuildContext context, String chunk) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ChunkSheet(chunk: chunk),
  );
}

class _ChunkSheet extends StatelessWidget {
  final String chunk;
  const _ChunkSheet({required this.chunk});

  @override
  Widget build(BuildContext context) {
    final info = ThaiDictService.instance.lookup(chunk);
    final sentences = ChunkIndexService.instance
        .search(chunk)
        .where((h) => h.chunk == chunk)
        .expand((h) => h.sentences)
        .take(4)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    chunk,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.khram,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up,
                      color: AppColors.kluayMai, size: 28),
                  onPressed: () => TtsService.instance.speak(chunk),
                ),
              ],
            ),
            if (info != null) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  _InfoChip('빈도 #${info.rank}', AppColors.kluayMai),
                  _InfoChip(info.tier, AppColors.morakot),
                  if (info.domain.isNotEmpty)
                    _InfoChip(info.domain, AppColors.thongDeep),
                ],
              ),
            ],
            if (sentences.isNotEmpty) ...[
              const SizedBox(height: 14),
              const LaiThaiDivider(height: 10),
              const SizedBox(height: 8),
              const Text(
                '용례',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.khramLight,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              for (final s in sentences)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: InkWell(
                    onTap: () => TtsService.instance.speak(s.th),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.th,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.khram,
                            fontFamilyFallback: AppTheme.fontFallback,
                          ),
                        ),
                        if (s.ko != null)
                          Text(
                            '${s.ko}  ·  ${s.source}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.khramLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
