import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/thai_phonetics.dart';
import '../services/tts_service.dart';

/// 글자 탭 → 발음 상세 시트(일본어앱 kana_sound_sheet.dart 기준, 2026-11-08).
/// 열리면 1초 뒤 자동 재생 · 다시 듣기 · IPA · 조음 위치(그림) · 모음 위치(태국어 vs 한국어) · 한국어 화자 비교.
/// 조음 그림은 임시(출시 전 Grok 그림으로 교체) — 출처 표기는 두지 않는다(사용자 지시 2026-11-08).
Future<void> showThaiSoundSheet(
  BuildContext context, {
  required String glyph,
  required String speak,
  required Color color,
  ThaiSound? sound,
  ThaiTone? tone,
  String subtitle = '',
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _Sheet(glyph: glyph, speak: speak, color: color, sound: sound, tone: tone, subtitle: subtitle),
  );
}

class _Sheet extends StatefulWidget {
  final String glyph, speak, subtitle;
  final Color color;
  final ThaiSound? sound;
  final ThaiTone? tone;
  const _Sheet({required this.glyph, required this.speak, required this.color, this.sound, this.tone, this.subtitle = ''});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  Timer? _auto;
  bool _chart = false;

  @override
  void initState() {
    super.initState();
    _auto = Timer(const Duration(seconds: 1), _play); // 1초 뒤 자동 재생
  }

  void _play() => TtsService.instance.speak(widget.speak);

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.sound, t = widget.tone, color = widget.color;
    final ipa = t != null
        ? '${t.ipa}  ${t.contour.join()}'
        : p == null
            ? ''
            : (p.say.isEmpty && p.ipaFinal.isNotEmpty ? '[${p.ipa}] · ${tr('받침')} [${p.ipaFinal}]' : '[${p.ipa}]');
    final roman = t != null ? t.ko : p == null ? '' : (p.romanFinal.isNotEmpty && p.romanFinal != p.roman ? '${p.roman} / -${p.romanFinal}' : p.roman);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.thong, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(widget.glyph, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: AppColors.onFill(color))),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (widget.subtitle.isNotEmpty) Text(widget.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.khramLight)),
                  if (roman.isNotEmpty) Text(roman, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                  if (ipa.isNotEmpty) Text('IPA $ipa', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.khram)),
                ]),
              ),
              IconButton(iconSize: 46, color: color, tooltip: tr('다시 듣기'), icon: const Icon(Icons.play_circle_fill), onPressed: _play),
            ]),
            const SizedBox(height: 18),
            if (t != null) ...[
              _Box(title: tr('🎵 음높이'), color: color, child: _ToneCurve(contour: t.contour, color: color)),
              const SizedBox(height: 12),
              _section(tr('🗣 이렇게 낸다'), '${t.how}\n${tr('성조 부호')}: ${t.mark}', color),
              const SizedBox(height: 12),
              _section(tr('🇰🇷 한국어와 비교'), t.kor, color),
            ] else if (p != null) ...[
              _section(tr('👄 소리나는 곳 · 입모양'), p.place, color),
              if (p.pos != null) ...[
                const SizedBox(height: 12),
                _Box(title: tr('📍 모음 위치 — 태국어 vs 한국어'), color: color, child: _VowelChart(pos: p.pos!, color: color)),
              ],
              if (p.say.isEmpty) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => setState(() => _chart = !_chart),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Icon(_chart ? Icons.expand_less : Icons.expand_more, size: 18, color: color),
                      Text(tr('자음 조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                    ]),
                  ),
                ),
                if (_chart) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(color: Colors.white, padding: const EdgeInsets.all(8), child: Image.asset('assets/images/ipa/places_of_articulation.png', fit: BoxFit.contain)),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              _section(tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [p.korSim, p.korDiff]), color),
              if (p.finalNote.isNotEmpty) ...[
                const SizedBox(height: 12),
                _section(tr('🔚 받침으로 올 때'), p.finalNote, color),
              ],
              if (p.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                _section(tr('📝 참고'), p.note, color),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body, Color color) => _Box(
        title: title,
        color: color,
        child: Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.khram)),
      );
}

class _Box extends StatelessWidget {
  final String title;
  final Color color;
  final Widget child;
  const _Box({required this.title, required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.creamDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 8),
          child,
        ]),
      );
}

/// 모음 사다리꼴 — 이 모음(굵은 점) · 태국어 기본 모음 9(작은 점) · 한국어 모음(파란 점).
class _VowelChart extends StatelessWidget {
  final List<double> pos;
  final Color color;
  const _VowelChart({required this.pos, required this.color});

  @override
  Widget build(BuildContext context) {
    final ph = ThaiPhonetics.instance;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AspectRatio(
        aspectRatio: 1.5,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: CustomPaint(painter: _VowelPainter(pos, color, ph.thaiVowelPos, ph.korVowels)),
        ),
      ),
      Row(children: [
        _dot(color, tr('이 모음')),
        const SizedBox(width: 12),
        _dot(AppColors.khramLight, tr('태국어')),
        const SizedBox(width: 12),
        _dot(AppColors.thai, tr('한국어')),
      ]),
      const SizedBox(height: 4),
      Text(tr('왼쪽 = 혀 앞 · 오른쪽 = 혀 뒤 · 위 = 입 작게 · 아래 = 입 크게'), style: const TextStyle(fontSize: 10.5, color: AppColors.khramLight)),
    ]);
  }

  Widget _dot(Color c, String label) => Row(children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
      ]);
}

class _VowelPainter extends CustomPainter {
  final List<double> pos;
  final Color color;
  final Map<String, List<double>> thai;
  final List<(String, double, double)> kor;
  _VowelPainter(this.pos, this.color, this.thai, this.kor);

  Offset _m(double x, double y, Size s) {
    final left = 0.36 * s.width * y; // 낮은 모음일수록 앞 경계가 안으로
    return Offset(left + (s.width - left) * x, y * s.height);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final line = Paint()
      ..color = AppColors.thong
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..moveTo(_m(0, 0, s).dx, 0)..lineTo(s.width, 0)..lineTo(s.width, s.height)..lineTo(_m(0, 1, s).dx, s.height)..close(), line);
    for (final y in [1 / 3, 2 / 3]) {
      canvas.drawLine(_m(0, y, s), _m(1, y, s), line..color = AppColors.thong.withValues(alpha: 0.6));
    }
    void label(String t, Offset o, Color c, {double size = 11, bool bold = false}) {
      final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(color: c, fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, o + Offset(6, -tp.height / 2));
    }
    for (final k in kor) {
      final o = _m(k.$2, k.$3, s);
      canvas.drawCircle(o, 4, Paint()..color = AppColors.thai.withValues(alpha: 0.8));
      label(k.$1, o + const Offset(0, 10), AppColors.thai, size: 10);
    }
    thai.forEach((k, v) {
      final o = _m(v[0], v[1], s);
      canvas.drawCircle(o, 3, Paint()..color = AppColors.khramLight);
      label(k, o, AppColors.khramLight, size: 10);
    });
    final me = _m(pos[0], pos[1], s);
    canvas.drawCircle(me, 8, Paint()..color = color);
    canvas.drawCircle(me, 8, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _VowelPainter old) => old.pos != pos;
}

/// 성조 음높이 곡선(5단계).
class _ToneCurve extends StatelessWidget {
  final List<int> contour;
  final Color color;
  const _ToneCurve({required this.contour, required this.color});

  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 2.4, child: CustomPaint(painter: _CurvePainter(contour, color)));
}

class _CurvePainter extends CustomPainter {
  final List<int> c;
  final Color color;
  _CurvePainter(this.c, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final grid = Paint()
      ..color = AppColors.thong
      ..strokeWidth = 1;
    for (var i = 1; i <= 5; i++) {
      final y = s.height - (i - 1) / 4 * s.height;
      canvas.drawLine(Offset(0, y), Offset(s.width, y), grid);
    }
    final pts = [for (var i = 0; i < c.length; i++) Offset(s.width * (0.08 + 0.84 * i / (c.length - 1)), s.height - (c[i] - 1) / 4 * s.height)];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      path.cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) => old.c != c;
}
