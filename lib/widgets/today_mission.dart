import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'thai_decor.dart';

/// Today's Mission 카드 — 현재 진행 중인 레슨 표시 (쩨디 실루엣 + progress).
class TodayMissionCard extends StatelessWidget {
  final String level;
  final String lessonTitle;
  final String lessonSubtitle;
  final int progress;
  final int total;
  final VoidCallback? onTap;
  /// 카드 아래 큰 시작 버튼 문구(없으면 버튼 없음) — Grok UXUI 시안 02.
  final String? cta;

  const TodayMissionCard({
    super.key,
    required this.level,
    required this.lessonTitle,
    required this.lessonSubtitle,
    required this.progress,
    required this.total,
    this.onTap,
    this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: AppColors.todayCard,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.thongBright.withValues(alpha: 0.6), width: 1),
        ),
        child: Stack(
          children: [
            // 쩨디(불탑) 실루엣 (오른쪽 하단)
            const Positioned(
              right: 0,
              bottom: 0,
              child: ChediSilhouette(size: 96, color: Color(0x40A85A3A)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          level,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.khram,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const GoldEmblem(text: 'วันนี้', size: 24),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lessonTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.khram,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lessonSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.khramLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$progress / $total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kluayMaiDeep,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: total > 0 ? progress / total : 0,
                          child: Container(
                            height: 8,
                            color: AppColors.kluayMaiDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cta != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.kluayMaiDeep,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: onTap,
                        icon: const Icon(Icons.star_rounded, size: 20),
                        label: Text(cta!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔥 streak counter — 헤더용 작은 칩
class StreakChip extends StatelessWidget {
  final int days;
  const StreakChip({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.kluayMaiDeep,
        border: Border.all(color: AppColors.thongBright, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: const TextStyle(
              color: AppColors.thongBright,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
