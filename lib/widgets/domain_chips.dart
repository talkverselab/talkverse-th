import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/course_service.dart';

/// 학습 목적(도메인) 고르기 — 알약 모양 칩을 여러 개 고른다 (talkverse-m 의 '무엇을 위해 배우나요?' 화면과 같은 꼴).
class DomainChips extends StatelessWidget {
  final CourseQuestion question;
  final Set<String> selected;
  final void Function(String id) onToggle;
  const DomainChips({super.key, required this.question, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final o in question.options)
          _Chip(
            label: o.label,
            sub: o.sub,
            emoji: o.emoji,
            selected: selected.contains(o.id),
            onTap: () => onToggle(o.id),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? sub;
  final String? emoji;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, this.sub, this.emoji, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.kluayMaiDeep;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: selected ? accent : AppColors.thong, width: selected ? 1.5 : 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(Icons.check_rounded, size: 15, color: accent),
              )
            else if (emoji != null)
              Padding(padding: const EdgeInsets.only(right: 6), child: Text(emoji!, style: const TextStyle(fontSize: 15))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: selected ? accent : AppColors.khram)),
                if (sub != null)
                  Text(sub!, style: const TextStyle(fontSize: 10.5, color: AppColors.khramLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 고른 도메인을 작은 칩으로 보여 주기(코스 화면 머리·프로필).
class DomainSummary extends StatelessWidget {
  final CourseQuestion question;
  final Iterable<String> ids;
  const DomainSummary({super.key, required this.question, required this.ids});

  @override
  Widget build(BuildContext context) {
    final byId = {for (final o in question.options) o.id: o};
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final id in ids)
          if (byId[id] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.kluayMaiDeep.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.kluayMaiDeep, width: 1),
              ),
              child: Text('${byId[id]!.emoji ?? ''} ${byId[id]!.label}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.kluayMaiDeep)),
            ),
      ],
    );
  }
}
