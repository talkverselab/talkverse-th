import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../core/platform.dart';
import '../services/tts_service.dart';
import '../widgets/thai_decor.dart';

/// Manual for English Users — every Thai sound with the standard (RTGS)
/// romanization next to this app's own English-friendly romanization.
/// Long vowels are rendered with an underline ({..} in the asset).
class EnglishManualScreen extends StatefulWidget {
  const EnglishManualScreen({super.key});

  @override
  State<EnglishManualScreen> createState() => _EnglishManualScreenState();
}

class _EnglishManualScreenState extends State<EnglishManualScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    rootBundle
        .loadString('assets/data/alphabet/th_romanization.json')
        .then((raw) {
          if (!mounted) return;
          setState(() => _data = json.decode(raw) as Map<String, dynamic>);
        })
        .catchError((_) {
          if (mounted) setState(() => _data = const {});
        });
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Manual for English Users',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2),
              Text(
                'THAI SOUNDS · ROMANIZATION',
                style: TextStyle(fontSize: 10, letterSpacing: 2),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.thongBright,
            labelStyle: TextStyle(fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: 'Consonants'),
              Tab(text: 'Vowels'),
              Tab(text: 'Tones'),
            ],
          ),
        ),
        body: d == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.kluayMai),
              )
            : TabBarView(
                children: [
                  _ConsonantTab(data: d),
                  _VowelTab(data: d),
                  _ToneTab(data: d),
                ],
              ),
      ),
    );
  }
}

/// Intro + legend shown at the top of every tab.
class _Intro extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Intro({required this.data});

  @override
  Widget build(BuildContext context) {
    final legend = (data['legend'] as List? ?? []).cast<String>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.thong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why our own romanization?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.kluayMaiDeep,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${data['intro'] ?? ''}',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.khram,
                ),
              ),
              const SizedBox(height: 8),
              for (final l in legend)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '• $l',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.khramLight,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            SizedBox(width: 52),
            Expanded(
              child: Text(
                'STANDARD (RTGS)',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.khramLight,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'OURS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kluayMaiDeep,
                ),
              ),
            ),
            SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Renders "ch{a}ng" with the braced part underlined (long vowel).
class OursText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight weight;
  const OursText(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.color = AppColors.kluayMaiDeep,
    this.weight = FontWeight.w900,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\{([^}]*)\}');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationThickness: 2.2,
          ),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          decorationColor: color,
          fontFamilyFallback: AppTheme.fontFallback,
        ),
        children: spans,
      ),
    );
  }
}

class _ConsonantTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ConsonantTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = (data['consonants'] as List? ?? []).cast<Map>();
    return ListView(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 32 + bottomInset(context)),
      children: [
        _Intro(data: data),
        for (final c in rows) _ConsonantRow(c: c),
      ],
    );
  }
}

class _ConsonantRow extends StatelessWidget {
  final Map c;
  const _ConsonantRow({required this.c});

  Color get _clsColor => switch ('${c['cls']}') {
    'mid' => AppColors.classMid,
    'high' => AppColors.classHigh,
    _ => AppColors.classLow,
  };

  @override
  Widget build(BuildContext context) {
    final ex = '${c['exampleTh'] ?? ''}';
    final note = '${c['note'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: _clsColor, width: 3),
          bottom: BorderSide(color: AppColors.thong.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  '${c['char']}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _clsColor,
                    fontFamilyFallback: AppTheme.fontFallback,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${c['rtgsInitial']}  ·  final ${c['rtgsFinal']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.khramLight,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    OursText('${c['oursInitial']}', fontSize: 18),
                    Text(
                      '  ·  final ${c['oursFinal']}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kluayMaiDeep,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.volume_up,
                  size: 20,
                  color: AppColors.kluayMai,
                ),
                onPressed: () =>
                    TtsService.instance.speak(ex.isEmpty ? '${c['char']}' : ex),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 2),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  ex,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.khram,
                    fontFamilyFallback: AppTheme.fontFallback,
                  ),
                ),
                Text(
                  '${c['exampleRtgs']}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.khramLight,
                  ),
                ),
                const Text('→', style: TextStyle(color: AppColors.khramLight)),
                OursText('${c['exampleOurs']}', fontSize: 14),
                Text(
                  '${c['exampleMeaning']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.khramLight,
                  ),
                ),
              ],
            ),
          ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 2),
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.thongDeep,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VowelTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _VowelTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = (data['vowels'] as List? ?? []).cast<Map>();
    return ListView(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 32 + bottomInset(context)),
      children: [
        _Intro(data: data),
        for (final v in rows) _VowelRow(v: v),
      ],
    );
  }
}

class _VowelRow extends StatelessWidget {
  final Map v;
  const _VowelRow({required this.v});

  @override
  Widget build(BuildContext context) {
    final long = '${v['length']}' == 'long';
    final ex = '${v['exampleTh'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: long ? AppColors.kluayMai : AppColors.morakot,
            width: 3,
          ),
          bottom: BorderSide(color: AppColors.thong.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  '${v['form']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.khram,
                    fontFamilyFallback: AppTheme.fontFallback,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${v['rtgs']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.khramLight,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    OursText('${v['ours']}', fontSize: 18),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      color: (long ? AppColors.kluayMai : AppColors.morakot)
                          .withValues(alpha: 0.12),
                      child: Text(
                        long ? 'long' : 'short',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: long ? AppColors.kluayMai : AppColors.morakot,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.volume_up,
                  size: 20,
                  color: AppColors.kluayMai,
                ),
                onPressed: ex.isEmpty
                    ? null
                    : () => TtsService.instance.speak(ex),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 64, top: 2),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  '${v['hint']}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.thongDeep,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  ex,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.khram,
                    fontFamilyFallback: AppTheme.fontFallback,
                  ),
                ),
                Text(
                  '${v['exampleRtgs']}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.khramLight,
                  ),
                ),
                const Text('→', style: TextStyle(color: AppColors.khramLight)),
                OursText('${v['exampleOurs']}', fontSize: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ToneTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = (data['tones'] as List? ?? []).cast<Map>();
    return ListView(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 32 + bottomInset(context)),
      children: [
        _Intro(data: data),
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Text(
            'Thai has five tones. The standard romanization does not mark them at all; when this app shows tones it puts an accent on the vowel.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.khramLight,
            ),
          ),
        ),
        for (final t in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: const BorderSide(color: AppColors.thongDeep, width: 3),
                bottom: BorderSide(
                  color: AppColors.thong.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    '${t['mark']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.kluayMaiDeep,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t['name']}  ·  ${t['thai']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.khram,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                      Text(
                        'RTGS: ${t['rtgs']}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.khramLight,
                        ),
                      ),
                      OursText(
                        '${t['example']}',
                        fontSize: 13,
                        weight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const LaiThaiDivider(height: 10),
      ],
    );
  }
}
