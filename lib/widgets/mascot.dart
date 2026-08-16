import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 마스코트 감정.
enum MascotEmotion {
  excited('excited', '신나요'),
  neutral('neutral', '보통이야'),
  worried('worried', '걱정돼'),
  sad('sad', '슬퍼'),
  sleepy('sleepy', '졸려'),
  proud('proud', '뿌듯해');

  final String slug;
  final String label;
  const MascotEmotion(this.slug, this.label);
}

/// 태국 코끼리 마스코트 — 드래그 + 떠다님 + 탭하면 감정 순환.
/// (에셋 없이 CustomPainter 로 그린다)
class ThaiMascot extends StatefulWidget {
  final double size;
  final Offset initialPosition;
  final bool draggable;
  final MascotEmotion emotion;
  final VoidCallback? onTap;
  final bool cycleOnTap;

  const ThaiMascot({
    super.key,
    this.size = 96,
    this.initialPosition = const Offset(0, 0),
    this.draggable = true,
    this.emotion = MascotEmotion.excited,
    this.onTap,
    this.cycleOnTap = true,
  });

  @override
  State<ThaiMascot> createState() => _ThaiMascotState();
}

class _ThaiMascotState extends State<ThaiMascot> with TickerProviderStateMixin {
  late Offset _pos;
  late MascotEmotion _emotion;
  late AnimationController _floatCtrl;
  late AnimationController _tapCtrl;
  late Animation<double> _floatAnim;
  late Animation<double> _tapScale;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _pos = widget.initialPosition;
    _emotion = widget.emotion;

    _floatCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _tapCtrl = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.85, end: 1.18), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.18, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant ThaiMascot old) {
    super.didUpdateWidget(old);
    if (old.emotion != widget.emotion) {
      setState(() => _emotion = widget.emotion);
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapCtrl.forward(from: 0);
    if (widget.cycleOnTap) {
      setState(() {
        final values = MascotEmotion.values;
        final i = values.indexOf(_emotion);
        _emotion = values[(i + 1) % values.length];
      });
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: GestureDetector(
        onTap: _handleTap,
        onPanStart:
            widget.draggable ? (_) => setState(() => _dragging = true) : null,
        onPanUpdate: widget.draggable
            ? (d) => setState(() {
                  _pos = Offset(_pos.dx + d.delta.dx, _pos.dy + d.delta.dy);
                })
            : null,
        onPanEnd: widget.draggable
            ? (_) {
                setState(() => _dragging = false);
                _clampToScreen();
              }
            : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatAnim, _tapScale]),
          builder: (context, child) {
            final dy = _dragging ? 0.0 : _floatAnim.value;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: _tapScale.value,
                child: _ElephantImage(
                  size: widget.size,
                  dragging: _dragging,
                  emotion: _emotion,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _clampToScreen() {
    final mq = MediaQuery.of(context).size;
    final safe = MediaQuery.of(context).padding;
    final w = widget.size;
    final minX = -w * 0.2;
    final maxX = mq.width - w * 0.8;
    final minY = safe.top - w * 0.1;
    final maxY = mq.height - safe.bottom - w * 0.8;
    setState(() {
      _pos = Offset(
        _pos.dx.clamp(minX, maxX),
        _pos.dy.clamp(minY, maxY),
      );
    });
  }
}

class _ElephantImage extends StatelessWidget {
  final double size;
  final bool dragging;
  final MascotEmotion emotion;
  const _ElephantImage({
    required this.size,
    required this.dragging,
    required this.emotion,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.kluayMai.withValues(alpha: dragging ? 0.5 : 0.25),
              blurRadius: dragging ? 18 : 10,
              spreadRadius: dragging ? 3 : 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: CustomPaint(
            key: ValueKey(emotion.slug),
            size: Size(size, size),
            painter: _ElephantPainter(emotion: emotion),
          ),
        ),
      ),
    );
  }
}

/// 창(ช้าง) — 회색빛 라벤더 아기 코끼리 + 골드 머리장식.
class _ElephantPainter extends CustomPainter {
  final MascotEmotion emotion;
  _ElephantPainter({required this.emotion});

  static const _body = Color(0xFFB6A8D4);
  static const _bodyDeep = Color(0xFF8F7FB5);
  static const _earInner = Color(0xFFE9B9D3);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = _body;
    final deep = Paint()..color = _bodyDeep;

    // 귀 (양쪽 큰 원)
    canvas.drawCircle(Offset(w * 0.2, h * 0.42), w * 0.19, deep);
    canvas.drawCircle(Offset(w * 0.8, h * 0.42), w * 0.19, deep);
    canvas.drawCircle(
        Offset(w * 0.21, h * 0.43), w * 0.13, Paint()..color = _earInner);
    canvas.drawCircle(
        Offset(w * 0.79, h * 0.43), w * 0.13, Paint()..color = _earInner);

    // 머리
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.31, body);

    // 코 (아래로 늘어진 트렁크)
    final trunk = Path()
      ..moveTo(w * 0.455, h * 0.6)
      ..quadraticBezierTo(w * 0.44, h * 0.78, w * 0.54, h * 0.84)
      ..quadraticBezierTo(w * 0.62, h * 0.88, w * 0.63, h * 0.8)
      ..quadraticBezierTo(w * 0.56, h * 0.8, w * 0.545, h * 0.72)
      ..quadraticBezierTo(w * 0.54, h * 0.64, w * 0.545, h * 0.6)
      ..close();
    canvas.drawPath(trunk, body);

    // 골드 머리장식 (창 라이 장식)
    final gold = Paint()..color = AppColors.thong;
    final crown = Path()
      ..moveTo(w * 0.35, h * 0.22)
      ..quadraticBezierTo(w * 0.5, h * 0.06, w * 0.65, h * 0.22)
      ..lineTo(w * 0.6, h * 0.26)
      ..quadraticBezierTo(w * 0.5, h * 0.16, w * 0.4, h * 0.26)
      ..close();
    canvas.drawPath(crown, gold);
    canvas.drawCircle(Offset(w * 0.5, h * 0.1), w * 0.035,
        Paint()..color = AppColors.thongBright);

    // 볼터치
    final blush = Paint()..color = AppColors.kluayMaiLight.withValues(alpha: 0.45);
    canvas.drawCircle(Offset(w * 0.32, h * 0.55), w * 0.05, blush);
    canvas.drawCircle(Offset(w * 0.68, h * 0.55), w * 0.05, blush);

    // 눈·입 (감정별)
    final ink = Paint()
      ..color = AppColors.khram
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.khram
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;

    final eyeL = Offset(w * 0.39, h * 0.42);
    final eyeR = Offset(w * 0.61, h * 0.42);

    switch (emotion) {
      case MascotEmotion.excited:
        // 반짝 큰 눈 + 활짝 웃음
        canvas.drawCircle(eyeL, w * 0.045, ink);
        canvas.drawCircle(eyeR, w * 0.045, ink);
        canvas.drawCircle(eyeL.translate(w * 0.015, -h * 0.012), w * 0.015,
            Paint()..color = Colors.white);
        canvas.drawCircle(eyeR.translate(w * 0.015, -h * 0.012), w * 0.015,
            Paint()..color = Colors.white);
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(w * 0.5, h * 0.52), width: w * 0.14, height: h * 0.1),
            0.3, 2.5, false, stroke);
        break;
      case MascotEmotion.neutral:
        canvas.drawCircle(eyeL, w * 0.035, ink);
        canvas.drawCircle(eyeR, w * 0.035, ink);
        canvas.drawLine(Offset(w * 0.45, h * 0.54), Offset(w * 0.55, h * 0.54), stroke);
        break;
      case MascotEmotion.worried:
        canvas.drawCircle(eyeL, w * 0.035, ink);
        canvas.drawCircle(eyeR, w * 0.035, ink);
        canvas.drawLine(Offset(w * 0.33, h * 0.35), Offset(w * 0.43, h * 0.38), stroke);
        canvas.drawLine(Offset(w * 0.67, h * 0.35), Offset(w * 0.57, h * 0.38), stroke);
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(w * 0.5, h * 0.56), width: w * 0.1, height: h * 0.06),
            3.4, 2.5, false, stroke);
        break;
      case MascotEmotion.sad:
        canvas.drawArc(
            Rect.fromCenter(center: eyeL, width: w * 0.07, height: h * 0.06),
            3.14, 3.14, false, stroke);
        canvas.drawArc(
            Rect.fromCenter(center: eyeR, width: w * 0.07, height: h * 0.06),
            3.14, 3.14, false, stroke);
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(w * 0.5, h * 0.57), width: w * 0.12, height: h * 0.07),
            3.4, 2.5, false, stroke);
        canvas.drawCircle(Offset(w * 0.33, h * 0.47), w * 0.018,
            Paint()..color = const Color(0xFF6EC6FF));
        break;
      case MascotEmotion.sleepy:
        canvas.drawLine(Offset(w * 0.35, h * 0.42), Offset(w * 0.43, h * 0.42), stroke);
        canvas.drawLine(Offset(w * 0.57, h * 0.42), Offset(w * 0.65, h * 0.42), stroke);
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(w * 0.5, h * 0.54), width: w * 0.06, height: h * 0.05),
            0, 3.14, false, stroke);
        break;
      case MascotEmotion.proud:
        canvas.drawArc(
            Rect.fromCenter(center: eyeL, width: w * 0.08, height: h * 0.07),
            3.14, -3.14, false, stroke);
        canvas.drawArc(
            Rect.fromCenter(center: eyeR, width: w * 0.08, height: h * 0.07),
            3.14, -3.14, false, stroke);
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(w * 0.5, h * 0.52), width: w * 0.12, height: h * 0.08),
            0.3, 2.5, false, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ElephantPainter old) => old.emotion != emotion;
}
