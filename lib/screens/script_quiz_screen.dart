import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/tts_service.dart';

/// 문자 퀴즈 — 자음 44자 4지선다 (문자 → 이름·뜻 고르기).
class ScriptQuizScreen extends StatefulWidget {
  const ScriptQuizScreen({super.key});

  @override
  State<ScriptQuizScreen> createState() => _ScriptQuizScreenState();
}

class _Letter {
  final String char;
  final String acrophonic;
  final String roman;
  final String meaning;
  final String cls;
  _Letter(this.char, this.acrophonic, this.roman, this.meaning, this.cls);
}

class _ScriptQuizScreenState extends State<ScriptQuizScreen> {
  static const int _rounds = 10;

  List<_Letter> _letters = [];
  bool _loading = true;
  int _round = 0;
  int _correct = 0;
  _Letter? _answer;
  List<_Letter> _options = [];
  int? _picked; // 선택한 옵션 index
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw =
        await rootBundle.loadString('assets/data/alphabet/th_alphabet.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final consonants = (data['consonants'] as List?) ?? [];
    _letters = [
      for (final c in consonants.whereType<Map>())
        _Letter(
          c['char'] as String? ?? '',
          c['acrophonic'] as String? ?? '',
          c['roman'] as String? ?? '',
          c['meaning'] as String? ?? '',
          c['cls'] as String? ?? '',
        ),
    ];
    _nextRound();
    if (mounted) setState(() => _loading = false);
  }

  void _nextRound() {
    if (_letters.length < 4) return;
    final pool = [..._letters]..shuffle(_rng);
    _answer = pool.first;
    _options = (pool.take(4).toList())..shuffle(_rng);
    _picked = null;
  }

  void _pick(int i) {
    if (_picked != null) return;
    setState(() {
      _picked = i;
      if (_options[i] == _answer) _correct++;
    });
    TtsService.instance.speak(_answer!.acrophonic);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_round + 1 >= _rounds) {
        _showResult();
      } else {
        setState(() {
          _round++;
          _nextRound();
        });
      }
    });
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('퀴즈 완료 🎉',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('$_rounds문제 중 $_correct개 정답!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _round = 0;
                _correct = 0;
                _nextRound();
              });
            },
            child: const Text('다시 풀기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.kluayMai),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('문자 퀴즈'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '${_round + 1}/$_rounds',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading || _answer == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final answer = _answer!;
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(height: 6, color: AppColors.creamDeep),
                    FractionallySizedBox(
                      widthFactor: (_round + 1) / _rounds,
                      child:
                          Container(height: 6, color: AppColors.kluayMai),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.thong, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.khram.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    answer.char,
                    style: TextStyle(
                      fontSize: 110,
                      fontWeight: FontWeight.w900,
                      color: consonantClassColor(answer.cls),
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '이 글자의 이름은?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.khramLight,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _OptionTile(
                        letter: _options[i],
                        state: _picked == null
                            ? _OptionState.idle
                            : _options[i] == answer
                                ? _OptionState.correct
                                : i == _picked
                                    ? _OptionState.wrong
                                    : _OptionState.idle,
                        onTap: () => _pick(i),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  final _Letter letter;
  final _OptionState state;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.letter, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, border) = switch (state) {
      _OptionState.correct => (
          AppColors.morakot.withValues(alpha: 0.15),
          AppColors.morakot
        ),
      _OptionState.wrong => (
          const Color(0xFFE53935).withValues(alpha: 0.12),
          const Color(0xFFE53935)
        ),
      _OptionState.idle => (
          AppColors.cream,
          AppColors.thong.withValues(alpha: 0.6)
        ),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${letter.acrophonic} · ${letter.meaning}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.khram,
                  fontFamilyFallback: AppTheme.fontFallback,
                ),
              ),
            ),
            Text(
              letter.roman,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.khramLight,
              ),
            ),
            if (state == _OptionState.correct)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child:
                    Icon(Icons.check_circle, color: AppColors.morakot, size: 20),
              ),
            if (state == _OptionState.wrong)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child:
                    Icon(Icons.cancel, color: Color(0xFFE53935), size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
