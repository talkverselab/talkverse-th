import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/thai_phonetics.dart';
import '../widgets/thai_sound_sheet.dart';
import '../core/embed_env.dart';

/// 문자와 발음 — 일본어앱 「50음도와 발음」 기준(사용자 지시 2026-11-08, 모든 언어앱). 배우기 「기초」 첫 줄.
/// 자음 44(묶음: 전체·중·고·저 / 소리별) · 모음 25(단·장·복합) · 성조 5 격자 + 로마자 토글. 글자 탭 = 발음 시트(1초 뒤 자동 재생).
class ThaiSoundChartScreen extends StatefulWidget {
  const ThaiSoundChartScreen({super.key});

  @override
  State<ThaiSoundChartScreen> createState() => _ThaiSoundChartScreenState();
}

class _Cons {
  final String char, name, ko, cls;
  const _Cons(this.char, this.name, this.ko, this.cls);
}

class _Vow {
  final String form, ko, length;
  const _Vow(this.form, this.ko, this.length);
}

class _ThaiSoundChartScreenState extends State<ThaiSoundChartScreen> {
  List<_Cons> _cons = [];
  List<_Vow> _vows = [];
  bool _loading = true;
  bool _roman = false;
  String _part = 'cons'; // cons | vow | tone
  String _group = 'all';

  static const _clsColor = {'mid': AppColors.classMid, 'high': AppColors.classHigh, 'low': AppColors.classLow};
  static const _toneColor = {'mid': AppColors.toneMid, 'low': AppColors.toneLow, 'falling': AppColors.toneFalling, 'high': AppColors.toneHigh, 'rising': AppColors.toneRising};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ThaiPhonetics.instance.ensureLoaded();
    final j = json.decode(await tvBundle.loadString('assets/data/alphabet/th_alphabet.json')) as Map<String, dynamic>;
    final cons = [
      for (final c in (j['consonants'] as List).cast<Map<String, dynamic>>())
        _Cons(c['char'] as String, c['acrophonic'] as String, c['ko'] as String, c['cls'] as String),
    ];
    final vows = [for (final v in (j['vowels'] as List).cast<Map<String, dynamic>>()) _Vow(v['form'] as String, v['ko'] as String, v['length'] as String)];
    if (!mounted) return;
    setState(() {
      _cons = cons;
      _vows = vows;
      _loading = false;
    });
  }

  Map<String, String> get _groups => switch (_part) {
        'cons' => {'all': tr('전체 44'), 'mid': tr('중자음 9'), 'high': tr('고자음 11'), 'low': tr('저자음 24'), 'sound': tr('소리별')},
        'vow' => {'all': tr('전체 25'), 'short': tr('단모음'), 'long': tr('장모음'), 'complex': tr('복합 모음')},
        _ => {'all': tr('성조 5')},
      };

  @override
  Widget build(BuildContext context) {
    final ph = ThaiPhonetics.instance;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('문자와 발음'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('자음 44 · 모음 · 성조 — 탭하면 소리·입모양'), style: const TextStyle(fontSize: 10, letterSpacing: 1)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tr('로마자')),
              selected: _roman,
              onSelected: (v) => setState(() => _roman = v),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.kluayMai))
          : Column(children: [
              Container(
                color: AppColors.creamDeep,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Column(children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'cons', label: Text(tr('자음'))),
                      ButtonSegment(value: 'vow', label: Text(tr('모음'))),
                      ButtonSegment(value: 'tone', label: Text(tr('성조'))),
                    ],
                    selected: {_part},
                    onSelectionChanged: (s) => setState(() {
                      _part = s.first;
                      _group = 'all';
                    }),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    for (final e in _groups.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        visualDensity: VisualDensity.compact,
                        selected: _group == e.key,
                        onSelected: (_) => setState(() => _group = e.key),
                      ),
                  ]),
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(12, 10, 12, 24 + bottomInset(context)),
                  children: switch (_part) {
                    'cons' => _consBody(ph),
                    'vow' => _vowBody(ph),
                    _ => _toneBody(ph),
                  },
                ),
              ),
            ]),
    );
  }

  List<Widget> _consBody(ThaiPhonetics ph) {
    if (_group == 'sound') {
      // 같은 소리끼리(초성 IPA) — 짝이 되는 고·저자음을 한눈에
      final by = <String, List<_Cons>>{};
      for (final c in _cons) {
        by.putIfAbsent(ph.consonants[c.char]?.ipa ?? '?', () => []).add(c);
      }
      return [
        for (final e in by.entries) ...[
          _head('[${e.key}]  ${ph.consonants[e.value.first.char]?.korSim ?? ''}'),
          _grid([for (final c in e.value) _consTile(c, ph)]),
        ],
      ];
    }
    final list = _group == 'all' ? _cons : _cons.where((c) => c.cls == _group).toList();
    return [
      _hint(tr('색 = 자음 등급(중·고·저) — 성조 규칙이 등급마다 다르다. 탭하면 1초 뒤 소리가 난다.')),
      _grid([for (final c in list) _consTile(c, ph)]),
    ];
  }

  Widget _consTile(_Cons c, ThaiPhonetics ph) {
    final p = ph.consonants[c.char];
    final color = _clsColor[c.cls]!;
    return _Tile(
      glyph: c.char,
      sub: _roman ? (p?.roman ?? '') : c.ko,
      color: color,
      onTap: () => showThaiSoundSheet(context, glyph: c.char, speak: c.name, color: color, sound: p, subtitle: c.name),
    );
  }

  List<Widget> _vowBody(ThaiPhonetics ph) {
    bool complex(_Vow v) => ph.vowels[v.form]?.pos == null;
    final list = switch (_group) {
      'short' => _vows.where((v) => v.length == 'short' && !complex(v)).toList(),
      'long' => _vows.where((v) => v.length == 'long' && !complex(v)).toList(),
      'complex' => _vows.where(complex).toList(),
      _ => _vows,
    };
    return [
      _hint(tr('– 자리에 자음이 들어간다. 단모음은 짧게, 장모음은 두 배쯤 길게 — 길이로 뜻이 바뀐다.')),
      _grid([
        for (final v in list)
          _Tile(
            glyph: v.form,
            sub: _roman ? (ph.vowels[v.form]?.roman ?? '') : v.ko,
            color: complex(v) ? AppColors.badges[6] : (v.length == 'long' ? AppColors.kluayMaiDeep : AppColors.kluayMai),
            onTap: () => showThaiSoundSheet(context,
                glyph: v.form, speak: ph.vowels[v.form]?.say ?? v.form.replaceAll('–', 'อ'), color: AppColors.kluayMaiDeep, sound: ph.vowels[v.form],
                subtitle: v.length == 'long' ? tr('장모음') : tr('단모음')),
          ),
      ]),
    ];
  }

  List<Widget> _toneBody(ThaiPhonetics ph) => [
        _hint(tr('같은 「카」도 음높이에 따라 뜻이 다르다. 탭해서 들어 보세요.')),
        _grid([
          for (final t in ph.tones)
            _Tile(
              glyph: t.sample,
              sub: _roman ? t.ipa : '${t.name} · ${t.gloss}',
              color: _toneColor[t.id]!,
              onTap: () => showThaiSoundSheet(context, glyph: t.sample, speak: t.sample, color: _toneColor[t.id]!, tone: t, subtitle: '${t.name} (${t.th}) · ${t.gloss}'),
            ),
        ]),
      ];

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.khram)),
      );

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
        child: Text(t, style: const TextStyle(fontSize: 11.5, color: AppColors.khramLight, height: 1.4)),
      );

  Widget _grid(List<Widget> tiles) => LayoutBuilder(builder: (context, c) {
        final cols = (c.maxWidth / 84).floor().clamp(4, 8);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.9,
          children: tiles,
        );
      });
}

class _Tile extends StatelessWidget {
  final String glyph, sub;
  final Color color;
  final VoidCallback onTap;
  const _Tile({required this.glyph, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.4),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(child: FittedBox(child: Text(glyph, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: color)))),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.khramLight)),
          ]),
        ),
      );
}
