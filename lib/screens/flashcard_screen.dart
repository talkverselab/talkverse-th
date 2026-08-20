import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/thai_decor.dart';

/// 복습 카드 — 태국 자음 44자 플래시카드 (TTS 발음 포함).
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<_Card> _cards = [];
  bool _loading = true;
  int _index = 0;

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
    final cards = <_Card>[];
    for (final c in consonants) {
      final m = c as Map<String, dynamic>;
      cards.add(_Card(
        char: m['char'] as String? ?? '',
        acrophonic: m['acrophonic'] as String? ?? '',
        roman: m['roman'] as String? ?? '',
        meaning: m['meaning'] as String? ?? '',
        cls: m['cls'] as String? ?? '',
        ko: m['ko'] as String? ?? '',
      ));
    }
    cards.shuffle();
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _loading = false;
    });
  }

  void _answer(int weight) {
    if (_index < _cards.length - 1) {
      setState(() => _index++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 복습 세션 완료!'),
          backgroundColor: AppColors.morakot,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('복습 카드',
                style: TextStyle(
                    color: AppColors.khram,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            SizedBox(height: 2),
            Text('พยัญชนะ ๔๔',
                style: TextStyle(
                    color: AppColors.khramLight,
                    fontSize: 10,
                    letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
      ),
      body: _loading || _cards.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final card = _cards[_index];
    final total = _cards.length;
    final clsColor = consonantClassColor(card.cls);
    final clsLabel = switch (card.cls) {
      'high' => '고자음 สูง',
      'mid' => '중자음 กลาง',
      'low' => '저자음 ต่ำ',
      _ => card.cls,
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_index + 1} / $total',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.khramLight, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.creamDeep,
                        border: Border.all(
                            color: AppColors.thong.withValues(alpha: 0.4)),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (_index + 1) / total,
                      child: Container(height: 6, color: AppColors.kluayMai),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.thong, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.khram.withValues(alpha: 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      InkWell(
                        onTap: () =>
                            TtsService.instance.speak(card.acrophonic),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Text(
                            card.char,
                            style: const TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.w900,
                              color: AppColors.kluayMai,
                              height: 1.2,
                              fontFamilyFallback: AppTheme.fontFallback,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.volume_up,
                            size: 20,
                            color:
                                AppColors.kluayMai.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${card.acrophonic} · ${card.meaning}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.khram,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${card.roman} · ${card.ko}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.khramLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: clsColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: clsColor),
                    ),
                    child: Text(
                      clsLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: clsColor,
                        letterSpacing: 1.5,
                        fontFamilyFallback: AppTheme.fontFallback,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const SilkDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SrsButton(
                icon: Icons.close,
                label: '몰라요',
                color: const Color(0xFFE53935),
                onTap: () => _answer(0),
              ),
              _SrsButton(
                icon: Icons.refresh,
                label: '보통이에요',
                color: AppColors.thong,
                onTap: () => _answer(1),
              ),
              _SrsButton(
                icon: Icons.check,
                label: '알아요',
                color: AppColors.morakot,
                onTap: () => _answer(2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card {
  final String char;
  final String acrophonic;
  final String roman;
  final String meaning;
  final String cls;
  final String ko;
  _Card({
    required this.char,
    required this.acrophonic,
    required this.roman,
    required this.meaning,
    required this.cls,
    required this.ko,
  });
}

class _SrsButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SrsButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.cream, size: 32),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.khram,
          ),
        ),
      ],
    );
  }
}
