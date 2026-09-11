import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/known_words_store.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import '../widgets/vocab_sheet.dart';

/// 단어 플래시카드 — 한→태(기본) / 태→한, 독음 토글, 탭해서 뒤집기, 알아요 = 체크 해제.
class WordFlashcardScreen extends StatefulWidget {
  final String title;
  final List<VocabEntry> words;
  final bool koFirst;
  const WordFlashcardScreen({
    super.key,
    required this.title,
    required this.words,
    this.koFirst = true,
  });

  @override
  State<WordFlashcardScreen> createState() => _WordFlashcardScreenState();
}

class _WordFlashcardScreenState extends State<WordFlashcardScreen> {
  late bool _koFirst = widget.koFirst;
  int _idx = 0;
  bool _flipped = false;

  VocabEntry get _cur => widget.words[_idx];

  void _go(int delta) {
    final n = widget.words.length;
    setState(() {
      _idx = (_idx + delta).clamp(0, n - 1);
      _flipped = false;
    });
  }

  Future<void> _markKnown() async {
    await KnownWordsStore.setKnown(_cur.th, true);
    if (!mounted) return;
    if (_idx < widget.words.length - 1) {
      _go(1);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _cur;
    final showTh = _koFirst ? _flipped : !_flipped;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            const Text(
              '단어 플래시카드',
              style: TextStyle(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          const KoReadingToggleAction(),
          IconButton(
            tooltip: _koFirst ? '한→태 (탭: 태→한)' : '태→한 (탭: 한→태)',
            onPressed: () => setState(() {
              _koFirst = !_koFirst;
              _flipped = false;
            }),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.kluayMai),
                borderRadius: BorderRadius.circular(6),
                color: AppColors.kluayMai.withValues(alpha: 0.08),
              ),
              child: Text(
                _koFirst ? '한→태' : '태→한',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.kluayMaiDeep,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${_idx + 1}/${widget.words.length}',
                style: const TextStyle(
                  color: AppColors.kluayMaiDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const LaiThaiDivider(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GestureDetector(
                onTap: () => setState(() => _flipped = !_flipped),
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v < -200) _go(1);
                  if (v > 200) _go(-1);
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: showTh ? AppColors.kluayMai : AppColors.thong,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showTh) ...[
                        Text(
                          e.th,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AppColors.khram,
                            height: 1.4,
                            fontFamilyFallback: AppTheme.fontFallback,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (e.reading.isNotEmpty)
                          KoReadingText(
                            e.reading,
                            th: e.th,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.kluayMaiDeep,
                            ),
                          ),
                        if (_koFirst || _flipped) ...[
                          const SizedBox(height: 14),
                          Text(
                            e.ko,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.khramLight,
                            ),
                          ),
                        ] else
                          const Padding(
                            padding: EdgeInsets.only(top: 14),
                            child: Text(
                              '탭해서 뜻 보기',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.khramLight,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        IconButton(
                          iconSize: 34,
                          color: AppColors.kluayMai,
                          icon: const Icon(Icons.volume_up),
                          onPressed: () =>
                              TtsService.instance.speak(e.speakable),
                        ),
                        RootChips(th: e.th, fontSize: 12, showLabel: true),
                      ] else ...[
                        Text(
                          e.ko,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppColors.khram,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          '탭해서 뒤집기',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.khramLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Row(
              children: [
                _NavBtn(label: '← 이전', enabled: _idx > 0, onTap: () => _go(-1)),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.morakot,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _markKnown,
                    child: const Text(
                      '알아요 ✓ (체크 해제)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _NavBtn(
                  label: '다음 →',
                  enabled: _idx < widget.words.length - 1,
                  onTap: () => _go(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(),
        side: BorderSide(
          color: enabled ? AppColors.thongDeep : AppColors.khramLight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      onPressed: enabled ? onTap : null,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}
