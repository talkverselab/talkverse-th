import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 금장 엠블럼 — 사원 금박 느낌의 라운드 배지. 태국 문자 1-4자 표시.
/// (zh 의 SealStamp 대응 — 태국은 인장 대신 금박 장식)
class GoldEmblem extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;

  const GoldEmblem({
    super.key,
    required this.text,
    this.size = 56,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.kluayMai;
    final isOne = text.runes.length == 1;
    final fontSize = isOne ? size * 0.55 : size * 0.3;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.thongBright, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.35),
            blurRadius: 5,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.cream,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.15,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
        ),
      ),
    );
  }
}

/// 실크 패널 — 위·아래 골드 실이 있는 컨테이너 (zh ScrollPanel 대응).
class SilkPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background;

  const SilkPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background = AppColors.cream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border.symmetric(
          horizontal:
              BorderSide(color: AppColors.thong.withValues(alpha: 0.6), width: 3),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// 연꽃 — 작은 장식 (Stack 안 Positioned 권장).
class Lotus extends StatelessWidget {
  final double size;
  final Color color;
  const Lotus({super.key, this.size = 28, this.color = AppColors.kluayMaiLight});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.7),
      painter: _LotusPainter(color: color),
    );
  }
}

class _LotusPainter extends CustomPainter {
  final Color color;
  _LotusPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    // 중앙 꽃잎
    Path petal(double cx, double tilt, double scale) {
      final p = Path();
      p.moveTo(cx, h);
      p.quadraticBezierTo(
          cx - w * 0.14 * scale, h * 0.45, cx + tilt, h * (1 - scale));
      p.quadraticBezierTo(cx + w * 0.14 * scale, h * 0.45, cx, h);
      return p;
    }

    canvas.drawPath(petal(w * 0.5, 0, 1.0), paint);
    canvas.drawPath(
        petal(w * 0.32, -w * 0.10, 0.75), paint..color = color.withValues(alpha: 0.8));
    canvas.drawPath(
        petal(w * 0.68, w * 0.10, 0.75), paint..color = color.withValues(alpha: 0.8));
    canvas.drawPath(
        petal(w * 0.18, -w * 0.14, 0.5), paint..color = color.withValues(alpha: 0.6));
    canvas.drawPath(
        petal(w * 0.82, w * 0.14, 0.5), paint..color = color.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 라이타이 문양 — 끄라녹(불꽃잎) 반복 패턴 배경 (zh CloudPattern 대응).
class LaiThaiPattern extends StatelessWidget {
  final Color color;
  final double opacity;

  const LaiThaiPattern({
    super.key,
    this.color = AppColors.thong,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LaiThaiPainter(color: color.withValues(alpha: opacity)),
      child: const SizedBox.expand(),
    );
  }
}

class _LaiThaiPainter extends CustomPainter {
  final Color color;
  _LaiThaiPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const step = 64.0;
    var row = 0;
    for (var y = -step; y < size.height + step; y += step) {
      final xOffset = row.isOdd ? step / 2 : 0.0;
      for (var x = -step; x < size.width + step; x += step) {
        _drawKranok(canvas, paint, Offset(x + xOffset, y), 20);
      }
      row++;
    }
  }

  /// 끄라녹 — 위로 말려 올라가는 불꽃잎 곡선.
  void _drawKranok(Canvas canvas, Paint paint, Offset base, double r) {
    final path = Path();
    path.moveTo(base.dx - r * 0.7, base.dy + r * 0.5);
    path.quadraticBezierTo(
        base.dx - r * 0.2, base.dy + r * 0.1, base.dx, base.dy - r * 0.6);
    path.quadraticBezierTo(
        base.dx + r * 0.15, base.dy - r * 1.0, base.dx + r * 0.5, base.dy - r * 1.05);
    path.quadraticBezierTo(
        base.dx + r * 0.2, base.dy - r * 0.75, base.dx + r * 0.25, base.dy - r * 0.4);
    path.quadraticBezierTo(
        base.dx + r * 0.35, base.dy + r * 0.15, base.dx + r * 0.8, base.dy + r * 0.4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 라이타이 띠 디바이더 — 사원 처마의 반복 삼각 장식 (zh GreekKeyDivider 대응).
class LaiThaiDivider extends StatelessWidget {
  final double height;
  final Color color;
  const LaiThaiDivider({super.key, this.height = 16, this.color = AppColors.thong});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LaiThaiDividerPainter(color: color),
      ),
    );
  }
}

class _LaiThaiDividerPainter extends CustomPainter {
  final Color color;
  _LaiThaiDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final unit = size.height / 4;
    for (var x = 0.0; x < size.width; x += unit * 4) {
      // 사원 지붕 층층 삼각(쩨디) 문양
      final path = Path()
        ..moveTo(x, size.height - unit)
        ..lineTo(x + unit, size.height - unit)
        ..lineTo(x + unit * 1.5, unit * 1.6)
        ..lineTo(x + unit * 2, size.height - unit)
        ..lineTo(x + unit * 3, size.height - unit);
      canvas.drawPath(path, paint);
      canvas.drawCircle(
          Offset(x + unit * 1.5, unit * 0.9), unit * 0.35, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 실크 분리선 — 그라데이션 라인 (zh BrushDivider 대응).
class SilkDivider extends StatelessWidget {
  final double height;
  final Color color;
  const SilkDivider({super.key, this.height = 3, this.color = AppColors.khram});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.6),
            color,
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0),
          ],
        ),
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}

/// 태국풍 카드 — 마젠타 헤더 + 골드 테두리 (zh ChineseCard 대응).
class ThaiCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? emblemText;
  final VoidCallback? onTap;
  final Color? accent;
  final EdgeInsetsGeometry padding;

  const ThaiCard({
    super.key,
    required this.child,
    this.title,
    this.emblemText,
    this.onTap,
    this.accent,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? AppColors.kluayMai;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.thong.withValues(alpha: 0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.khram.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Container(
                color: a,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    if (emblemText != null) ...[
                      GoldEmblem(text: emblemText!, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(Icons.chevron_right,
                          color: AppColors.cream, size: 18),
                  ],
                ),
              ),
            ],
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// 쩨디(불탑) 실루엣 — 카드 배경 장식용.
class ChediSilhouette extends StatelessWidget {
  final double size;
  final Color color;
  const ChediSilhouette(
      {super.key, this.size = 100, this.color = AppColors.kluayMaiDeep});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.6, size),
      painter: _ChediPainter(color: color),
    );
  }
}

class _ChediPainter extends CustomPainter {
  final Color color;
  _ChediPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // 중앙 쩨디 (종 모양 + 뾰족탑)
    void chedi(double cx, double baseW, double topY) {
      final path = Path()
        ..moveTo(cx - baseW, h)
        ..lineTo(cx - baseW, h * 0.72)
        ..quadraticBezierTo(cx - baseW * 0.9, h * 0.5, cx - baseW * 0.35, h * 0.42)
        ..lineTo(cx - baseW * 0.12, h * 0.40)
        ..lineTo(cx, topY)
        ..lineTo(cx + baseW * 0.12, h * 0.40)
        ..lineTo(cx + baseW * 0.35, h * 0.42)
        ..quadraticBezierTo(cx + baseW * 0.9, h * 0.5, cx + baseW, h * 0.72)
        ..lineTo(cx + baseW, h)
        ..close();
      canvas.drawPath(path, p);
    }

    chedi(w * 0.7, w * 0.16, h * 0.05);
    chedi(w * 0.4, w * 0.11, h * 0.3);
    chedi(w * 0.92, w * 0.10, h * 0.35);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 별 문양 (다르마차크라 느낌의 방사형 포인트).
class ThaiStar extends StatelessWidget {
  final double size;
  final Color color;
  const ThaiStar({super.key, this.size = 16, this.color = AppColors.thong});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ThaiStarPainter(color: color),
    );
  }
}

class _ThaiStarPainter extends CustomPainter {
  final Color color;
  _ThaiStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.shortestSide / 2;
    final inner = outer * 0.42;
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 8;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
