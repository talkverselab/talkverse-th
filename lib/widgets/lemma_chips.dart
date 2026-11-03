import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/thai_font.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/vocab_service.dart';
import 'vocab_sheet.dart';

/// 문장의 내용어(레마) 칩 — 단어장에 있는 말은 누르면 단어 시트, 없는 말은 회색(사용자 지시 2026-11-04 "문장 레마별로 단어장이랑 연결",
/// 일본어앱 lemma_chips.dart 이식). 같은 기본형은 한 번만. 단어장에 없는 레마 목록은 uk 세션이 채운다(data/review/write/missing_lemmas.csv).
class LemmaChips extends StatelessWidget {
  final DialogueTurn turn;
  final bool compact;
  const LemmaChips({super.key, required this.turn, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final lemmas = [for (final l in turn.lemmas) if (seen.add(l.base)) l];
    if (lemmas.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<void>(
      key: ValueKey('${turn.num}:${turn.th}'),
      future: VocabService.instance.ensureLoaded(),
      builder: (context, snap) {
        final loaded = snap.connectionState == ConnectionState.done;
        final found = <String, VocabEntry>{};
        if (loaded) {
          for (final l in lemmas) {
            final e = VocabService.instance.byLemma(l.base);
            if (e != null) found[l.base] = e;
          }
        }
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final l in lemmas)
              _Chip(
                label: l.base,
                gloss: found[l.base]?.ko,
                compact: compact,
                onTap: found[l.base] == null ? null : () => showVocabSheet(context, found[l.base]!),
              ),
            if (loaded && found.isEmpty)
              Padding(padding: const EdgeInsets.only(top: 2), child: Text(tr('단어장에 없는 말'), style: const TextStyle(fontSize: 10, color: AppColors.thongDeep))),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? gloss;
  final bool compact;
  final VoidCallback? onTap;
  const _Chip({required this.label, this.gloss, this.compact = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(
          color: on ? AppColors.cream : AppColors.creamDeep,
          border: Border.all(color: on ? AppColors.kluayMai.withValues(alpha: 0.7) : AppColors.thong),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: compact ? 12 : 13.5, fontWeight: FontWeight.w800, color: on ? AppColors.khram : AppColors.thongDeep, fontFamily: ThaiFontPrefs.family, fontFamilyFallback: AppTheme.fontFallback)),
          if (gloss != null && gloss!.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(gloss!.split(RegExp(r'[,;·/]')).first.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.khramLight)),
          ],
        ]),
      ),
    );
  }
}
