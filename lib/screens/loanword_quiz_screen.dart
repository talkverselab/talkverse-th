import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/episode_play_pane.dart' show thStyle;

/// 영어 유래 단어 퀴즈 복습(일본어앱 110 「외국어 단어 퀴즈」와 같은 꼴, 2026-11-19).
/// 두 꼴 — 표기(바르게 쓴 태국어 고르기)와 뜻 고르기, 보기 1~4, 10문제. 틀린 단어는 다음 복습에 먼저.
/// 표기 문제의 틀린 보기는 음차에서 자주 틀리는 꼴로 만든다: 성조 부호를 빼거나 바꾸기, 묵음 부호 ์ 빼기,
/// 소리가 같은 자음 바꾸기(ส↔ซ, ต↔ท, ร↔ล, ค↔ข, ป↔พ, บ↔ป).
const int kLoanwordQuizSize = 10;
const String _kWrong = 'loanword_quiz_wrong';

class LQWord {
  final String th, en, ko, reading;
  const LQWord(this.th, this.en, this.ko, [this.reading = '']);
}

const _tones = ['่', '้', '๊', '๋']; // ่ ้ ๊ ๋
const _karan = '์'; // ์
const _pairs = {'ส': 'ซ', 'ซ': 'ส', 'ต': 'ท', 'ท': 'ต', 'ร': 'ล', 'ล': 'ร', 'ค': 'ข', 'ข': 'ค', 'ป': 'พ', 'พ': 'ป', 'บ': 'ป'};

bool _isThaiConsonant(String c) => c.isNotEmpty && c.codeUnitAt(0) >= 0x0E01 && c.codeUnitAt(0) <= 0x0E2E;

/// 규칙을 어긴 꼴들(실제 단어와 겹치는 것은 뺀다).
List<String> loanwordMisspellings(String th, Set<String> real) {
  final c = th.split('');
  final out = <String>{};
  for (var i = 0; i < c.length; i++) {
    final ch = c[i];
    if (_tones.contains(ch)) {
      out.add(([...c]..removeAt(i)).join());
      for (final t in _tones) {
        if (t != ch) out.add(([...c]..[i] = t).join());
      }
      continue;
    }
    if (ch == _karan) {
      out.add(([...c]..removeAt(i)).join());
      continue;
    }
    final s = _pairs[ch];
    if (s != null) out.add(([...c]..[i] = s).join());
  }
  // 성조 부호가 없는 단어: 첫 자음 뒤에 ่ / ้ 를 넣은 꼴
  if (!c.any(_tones.contains)) {
    final k = c.indexWhere(_isThaiConsonant);
    if (k >= 0) {
      for (final t in _tones.take(2)) {
        out.add(([...c]..insert(k + 1, t)).join());
      }
    }
  }
  return out.where((s) => s != th && s.isNotEmpty && !real.contains(s)).toList();
}

class _Q {
  final LQWord w;
  final bool spelling; // true = 표기, false = 뜻
  final List<String> options;
  const _Q(this.w, this.spelling, this.options);
  String get answer => spelling ? w.th : w.ko;
}

class LoanwordQuizScreen extends StatefulWidget {
  final List<LQWord> words;
  final int? seed;
  const LoanwordQuizScreen({super.key, required this.words, this.seed});
  @override
  State<LoanwordQuizScreen> createState() => _LoanwordQuizScreenState();
}

class _LoanwordQuizScreenState extends State<LoanwordQuizScreen> {
  late final _rnd = Random(widget.seed);
  List<_Q>? _qs;
  int _i = 0;
  String? _picked;
  int _right = 0;
  final List<LQWord> _missed = [];

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    Set<String> wrong = {};
    try {
      final p = await SharedPreferences.getInstance();
      wrong = (p.getStringList(_kWrong) ?? const []).toSet();
    } catch (_) {}
    final uniq = <String, LQWord>{for (final w in widget.words) w.th: w}.values.toList()..shuffle(_rnd);
    uniq.sort((a, b) => (wrong.contains(b.th) ? 1 : 0) - (wrong.contains(a.th) ? 1 : 0));
    final picked = uniq.take(kLoanwordQuizSize).toList()..shuffle(_rnd);
    final real = {for (final w in widget.words) w.th};
    final qs = <_Q>[];
    for (var k = 0; k < picked.length; k++) {
      final w = picked[k];
      final miss = (loanwordMisspellings(w.th, real)..shuffle(_rnd)).take(3).toList();
      if (k.isEven && miss.length == 3) {
        qs.add(_Q(w, true, [w.th, ...miss]..shuffle(_rnd)));
      } else {
        final others = ({for (final o in uniq) if (o.ko != w.ko) o.ko}.toList()..shuffle(_rnd)).take(3);
        qs.add(_Q(w, false, [w.ko, ...others]..shuffle(_rnd)));
      }
    }
    if (mounted) setState(() => _qs = qs);
  }

  Future<void> _record(String th, bool ok) async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = (p.getStringList(_kWrong) ?? const []).toSet();
      ok ? s.remove(th) : s.add(th);
      await p.setStringList(_kWrong, s.toList());
    } catch (_) {}
  }

  void _again() => setState(() {
        _qs = null;
        _i = 0;
        _picked = null;
        _right = 0;
        _missed.clear();
        _build();
      });

  @override
  Widget build(BuildContext context) {
    final qs = _qs;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(tr('퀴즈 복습'))),
      body: qs == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.kluayMai))
          : _i >= qs.length
              ? _summary(qs.length)
              : _question(qs[_i], qs.length),
    );
  }

  Widget _summary(int n) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(trf('{0}문제 중 {1}개 맞힘', [n, _right]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.khram)),
            if (_missed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr('틀린 단어 — 다음 복습에 먼저 나와요'), style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
              const SizedBox(height: 6),
              for (final w in _missed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${w.th}  ${w.en.isEmpty ? '' : '${w.en} · '}${w.ko}', textAlign: TextAlign.center, style: thStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(key: const ValueKey('lq-again'), onPressed: _again, child: Text(tr('한 번 더'))),
              const SizedBox(width: 10),
              FilledButton(onPressed: () => Navigator.of(context).maybePop(), style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep), child: Text(tr('나가기'))),
            ]),
          ]),
        ),
      );

  Widget _question(_Q q, int n) {
    final w = q.w;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${tr(q.spelling ? '표기' : '뜻')} · ${_i + 1} / $n', style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
        const SizedBox(height: 14),
        Text(
          q.spelling ? (w.en.isEmpty ? w.ko : '${w.en} · ${w.ko}') : w.th,
          key: const ValueKey('lq-stem'),
          style: q.spelling
              ? const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.khram)
              : thStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(tr(q.spelling ? '태국어로 바르게 쓴 것을 고르세요.' : '뜻으로 맞는 것을 고르세요.'), style: const TextStyle(fontSize: 14, color: AppColors.khram)),
        if (_picked != null && !q.spelling && w.en.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(w.en, style: const TextStyle(fontSize: 13, color: AppColors.kluayMaiDeep, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('lq-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _picked == null ? null : (q.options[k] == q.answer ? const Color(0x3336A35B) : (q.options[k] == _picked ? const Color(0x33D83A3A) : null)),
                side: BorderSide(color: _picked != null && q.options[k] == q.answer ? AppColors.morakot : AppColors.thong, width: 1.4),
              ),
              onPressed: _picked != null
                  ? null
                  : () {
                      final ok = q.options[k] == q.answer;
                      TtsService.instance.speak(w.th);
                      _record(w.th, ok);
                      setState(() {
                        _picked = q.options[k];
                        ok ? _right++ : _missed.add(w);
                      });
                    },
              child: Row(children: [
                SizedBox(width: 26, child: Text('${k + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.khramLight))),
                Expanded(child: Text(q.options[k], style: q.spelling ? thStyle(fontSize: 22) : const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.khram))),
              ]),
            ),
          ),
        if (_picked != null)
          FilledButton(
            key: const ValueKey('lq-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep, minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
            child: Text(tr('다음 →')),
          ),
      ]),
    );
  }
}
