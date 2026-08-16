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

  const TodayMissionCard({
    super.key,
    required this.level,
    required this.lessonTitle,
    required this.lessonSubtitle,
    required this.progress,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.kluayMaiDeep, AppColors.kluayMai],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.thong, width: 1.5),
        ),
        child: Stack(
          children: [
            // 쩨디(불탑) 실루엣 (오른쪽 하단)
            const Positioned(
              right: 0,
              bottom: 0,
              child: ChediSilhouette(size: 96),
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
                          color: AppColors.thongBright,
                          border:
                              Border.all(color: AppColors.thongDeep, width: 0.6),
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
                      fontWeight: FontWeight.w900,
                      color: AppColors.cream,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lessonSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.cream.withValues(alpha: 0.85),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$progress / $total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.thongBright,
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
                            color: AppColors.cream.withValues(alpha: 0.25),
                            border:
                                Border.all(color: AppColors.thong, width: 0.6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: total > 0 ? progress / total : 0,
                          child: Container(
                            height: 8,
                            color: AppColors.thongBright,
                          ),
                        ),
                      ],
                    ),
                  ),
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
