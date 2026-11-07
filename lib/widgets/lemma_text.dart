import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/vocab_service.dart';
import 'vocab_sheet.dart';

/// 회화 문장 — 레마(내용어) 자리를 눌러 단어창을 연다(사용자 지시 2026-11-07, 모든 언어앱 공통).
/// 단어장에 있는 레마에만 점선 밑줄을 긋는다. 레마를 문장에서 못 찾으면 그 자리는 글자 그대로 둔다.
/// 어조사 감정 이모지(`turn.emoji`)는 줄 끝에 붙여 보여 준다(2026-11-07).
class LemmaText extends StatefulWidget {
  final DialogueTurn turn;
  final String text; // 이름 자리를 채운 문장
  final TextStyle style;
  const LemmaText({super.key, required this.turn, required this.text, required this.style});

  @override
  State<LemmaText> createState() => _LemmaTextState();
}

class _LemmaTextState extends State<LemmaText> {
  final _taps = <TapGestureRecognizer>[];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    VocabService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  void _clear() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final tail = widget.turn.emoji == null ? '' : ' ${widget.turn.emoji}';
    if (!_ready || widget.turn.lemmas.isEmpty) return Text('$text$tail', style: widget.style);
    _clear();
    final spans = <InlineSpan>[];
    var at = 0;
    for (final l in widget.turn.lemmas) {
      final i = text.indexOf(l.surface, at);
      if (l.surface.isEmpty || i < 0) continue;
      final e = VocabService.instance.byLemma(l.base);
      if (e == null) continue;
      if (i > at) spans.add(TextSpan(text: text.substring(at, i)));
      final tap = TapGestureRecognizer()..onTap = () => showVocabSheet(context, e);
      _taps.add(tap);
      spans.add(TextSpan(
        text: l.surface,
        recognizer: tap,
        style: TextStyle(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: AppColors.kluayMai.withValues(alpha: 0.8),
        ),
      ));
      at = i + l.surface.length;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    if (tail.isNotEmpty) spans.add(TextSpan(text: tail));
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
