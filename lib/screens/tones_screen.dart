import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/tone.dart';
import '../data/repositories/tone_repository.dart';

class TonesScreen extends StatefulWidget {
  const TonesScreen({super.key});

  @override
  State<TonesScreen> createState() => _TonesScreenState();
}

class _TonesScreenState extends State<TonesScreen> {
  late final Future<ToneData> _future;

  @override
  void initState() {
    super.initState();
    _future = ToneRepository.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBottom,
      appBar: AppBar(
        title: const Text('성조 · วรรณยุกต์',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: FutureBuilder<ToneData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('데이터를 불러오지 못했어요\n${snap.error ?? ''}'));
          }
          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              const _IntroCard(),
              const SizedBox(height: 20),
              const _SectionHeader('5성조 · 최소대립쌍 “카”'),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '같은 “카” 발음도 성조에 따라 뜻이 완전히 달라집니다. 카드를 눌러 들어보세요.',
                  style: TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 12),
              for (final t in data.tones) ...[
                _ToneCard(tone: t),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              const _SectionHeader('성조 부호 · รูปวรรณยุกต์'),
              const SizedBox(height: 10),
              _ToneMarkRow(marks: data.marks),
              const SizedBox(height: 22),
              const _SectionHeader('성조 규칙표 · 자음 분류별'),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '자음 분류 × 음절 종류 × 성조부호 → 성조. 태국어 읽기의 핵심 규칙입니다.',
                  style: TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 12),
              _ToneRuleTable(rules: data.rules),
              const SizedBox(height: 14),
              const _LegendCard(),
            ],
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppTheme.gold, AppTheme.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('태국어는 5성조 언어',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            '평성·저성·하강성·고성·상승성 5개. 성조는 글자에 늘 적혀 있지 않고, '
            '자음 분류(고·중·저)와 모음 길이·받침·성조부호의 조합으로 정해집니다.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.5,
                fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: AppTheme.brand),
        const SizedBox(width: 8),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ToneCard extends StatelessWidget {
  final ThaiTone tone;
  const _ToneCard({required this.tone});

  static const _colors = <String, Color>{
    'mid': Color(0xFF7C8AA0),
    'low': Color(0xFF12B5A5),
    'falling': Color(0xFFE6007E),
    'high': Color(0xFFF7900E),
    'rising': Color(0xFF7B61FF),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[tone.id] ?? AppTheme.brand;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tone.sample} (${tone.nameKo}) — 발음 오디오 준비 중'),
              duration: const Duration(milliseconds: 1000),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 성조 곡선 그래프
              Container(
                width: 64,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: CustomPaint(
                  painter: _ContourPainter(tone.contour, color),
                ),
              ),
              const SizedBox(width: 14),
              // 예시 글자
              SizedBox(
                width: 52,
                child: Column(
                  children: [
                    Text(tone.sample,
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    Text(tone.sampleKo,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${tone.nameKo} ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(tone.thai,
                            style: const TextStyle(
                                color: Colors.black38, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(tone.desc,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54, height: 1.3)),
                    const SizedBox(height: 3),
                    Text('뜻: ${tone.meaning}',
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 성조 음높이 곡선을 그리는 페인터.
class _ContourPainter extends CustomPainter {
  final List<double> contour;
  final Color color;
  const _ContourPainter(this.contour, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // 가이드 라인 (상/중/하)
    final guide = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }

    if (contour.isEmpty) return;
    final path = Path();
    for (var i = 0; i < contour.length; i++) {
      final x = contour.length == 1
          ? size.width / 2
          : size.width * i / (contour.length - 1);
      final y = size.height * (1 - contour[i]); // 1=고음 → 위쪽
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, line);

    // 시작·끝 점
    final dot = Paint()..color = color;
    final lastX = size.width;
    final lastY = size.height * (1 - contour.last);
    canvas.drawCircle(Offset(lastX, lastY), 3, dot);
  }

  @override
  bool shouldRepaint(_ContourPainter old) =>
      old.contour != contour || old.color != color;
}

class _ToneMarkRow extends StatelessWidget {
  final List<ToneMark> marks;
  const _ToneMarkRow({required this.marks});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final m in marks)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(m.display,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brand)),
              ),
              title: Text('${m.thai}  (${m.roman})',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(m.ko),
            ),
          ),
      ],
    );
  }
}

class _ToneRuleTable extends StatelessWidget {
  final List<ToneRule> rules;
  const _ToneRuleTable({required this.rules});

  static const _classColors = <String, Color>{
    'mid': AppTheme.classMid,
    'high': AppTheme.classHigh,
    'low': AppTheme.classLow,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
              AppTheme.indigo.withValues(alpha: 0.06)),
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.black87),
          dataTextStyle: const TextStyle(fontSize: 12.5, color: Colors.black87),
          columnSpacing: 18,
          horizontalMargin: 14,
          columns: const [
            DataColumn(label: Text('자음 분류')),
            DataColumn(label: Text('평음절\n(무표)')),
            DataColumn(label: Text('사음절\n단모음')),
            DataColumn(label: Text('사음절\n장모음')),
            DataColumn(label: Text('ไม้เอก\n◌่')),
            DataColumn(label: Text('ไม้โท\n◌้')),
          ],
          rows: [
            for (final r in rules)
              DataRow(cells: [
                DataCell(Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _classColors[r.cls],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(r.clsKo,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                )),
                DataCell(_ToneTag(r.live)),
                DataCell(_ToneTag(r.deadShort)),
                DataCell(_ToneTag(r.deadLong)),
                DataCell(_ToneTag(r.mai1)),
                DataCell(_ToneTag(r.mai2)),
              ]),
          ],
        ),
      ),
    );
  }
}

class _ToneTag extends StatelessWidget {
  final String tone;
  const _ToneTag(this.tone);

  static const _colors = <String, Color>{
    '평성': Color(0xFF7C8AA0),
    '저성': Color(0xFF12B5A5),
    '하강성': Color(0xFFE6007E),
    '고성': Color(0xFFF7900E),
    '상승성': Color(0xFF7B61FF),
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[tone] ?? Colors.black54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(tone,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('용어',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          SizedBox(height: 8),
          Text('• 평음절(생음절): 장모음으로 끝나거나 ㅇ·ㄴ·ㅁ·이·오 받침으로 끝나는 음절',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.5)),
          Text('• 사음절: 단모음으로 끝나거나 ㄱ·ㄷ·ㅂ 받침으로 끝나는 음절',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.5)),
          Text('• 저자음 단독으로는 5성조를 다 못 만들어, ห·อ 선도자음으로 보완합니다.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.5)),
        ],
      ),
    );
  }
}
