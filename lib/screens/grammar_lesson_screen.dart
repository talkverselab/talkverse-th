import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/memo_toggle.dart';
import '../widgets/thai_decor.dart';

/// 어말조사(คำลงท้าย) 레슨 — 태국어 말맛의 핵심.
/// Netflix 원어 코퍼스에서 추출한 실제 예문 기반.
class GrammarLessonScreen extends StatefulWidget {
  const GrammarLessonScreen({super.key});

  @override
  State<GrammarLessonScreen> createState() => _GrammarLessonScreenState();
}

class _GrammarLessonScreenState extends State<GrammarLessonScreen> {
  List<_SfpItem> _items = [];
  bool _loading = true;
  String _filter = 'ALL';

  static const Map<String, (String, Color)> _registers = {
    'ALL': ('전체', AppColors.khram),
    'polite': ('공손', AppColors.morakot),
    'neutral': ('중립', AppColors.thongDeep),
    'casual': ('구어', AppColors.kluayMai),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/grammar/sfp.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? [];
    if (!mounted) return;
    setState(() {
      _items = items
          .whereType<Map>()
          .map((m) => _SfpItem(
                sfp: m['sfp'] as String? ?? '',
                roman: m['roman'] as String? ?? '',
                nameKo: m['nameKo'] as String? ?? '',
                desc: m['desc'] as String? ?? '',
                register: m['register'] as String? ?? 'neutral',
                examples: ((m['examples'] as List?) ?? [])
                    .whereType<Map>()
                    .map((e) => (
                          th: e['th'] as String? ?? '',
                          ko: e['ko'] as String? ?? '',
                        ))
                    .toList(),
              ))
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'ALL'
        ? _items
        : _items.where((i) => i.register == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('어말조사',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('คำลงท้าย',
                style: TextStyle(fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai))
          : Column(
              children: [
                Container(
                  color: AppColors.creamDeep,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _registers.entries.map((e) {
                        final selected = _filter == e.key;
                        final (label, color) = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? color : AppColors.cream,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                    color: color,
                                    width: selected ? 1.5 : 0.8),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color:
                                      selected ? AppColors.cream : color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const LaiThaiDivider(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _SfpCard(item: filtered[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SfpItem {
  final String sfp;
  final String roman;
  final String nameKo;
  final String desc;
  final String register;
  final List<({String th, String ko})> examples;
  _SfpItem({
    required this.sfp,
    required this.roman,
    required this.nameKo,
    required this.desc,
    required this.register,
    required this.examples,
  });
}

class _SfpCard extends StatefulWidget {
  final _SfpItem item;
  const _SfpCard({required this.item});

  @override
  State<_SfpCard> createState() => _SfpCardState();
}

class _SfpCardState extends State<_SfpCard> {
  bool _expanded = false;

  Color get _registerColor => switch (widget.item.register) {
        'polite' => AppColors.morakot,
        'casual' => AppColors.kluayMai,
        _ => AppColors.thongDeep,
      };

  String get _registerLabel => switch (widget.item.register) {
        'polite' => '공손',
        'casual' => '구어',
        _ => '중립',
      };

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return ThaiCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GoldEmblem(text: item.sfp, size: 44, color: _registerColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.nameKo,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.khram,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                    _registerColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _registerColor, width: 0.7),
                              ),
                              child: Text(
                                _registerLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _registerColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.roman,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.khramLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up,
                        size: 20, color: AppColors.kluayMai),
                    onPressed: () => TtsService.instance.speak(item.sfp),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.khramLight,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.thong),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.khram,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < item.examples.length; i++) ...[
                    _ExampleRow(
                      th: item.examples[i].th,
                      ko: item.examples[i].ko,
                      sfp: item.sfp,
                    ),
                    MemoToggle(
                      patternId: 'sfp_${item.sfp}',
                      idx: i,
                      sentence: item.examples[i].th,
                    ),
                    if (i < item.examples.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final String th;
  final String ko;
  final String sfp;
  const _ExampleRow({required this.th, required this.ko, required this.sfp});

  @override
  Widget build(BuildContext context) {
    // 어말조사 부분을 강조 표시
    final idx = th.lastIndexOf(sfp);
    return InkWell(
      onTap: () => TtsService.instance.speak(th),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.creamDeep,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.thong.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: idx < 0
                      ? Text(th, style: _thStyle)
                      : RichText(
                          text: TextSpan(
                            style: _thStyle,
                            children: [
                              TextSpan(text: th.substring(0, idx)),
                              TextSpan(
                                text: th.substring(idx, idx + sfp.length),
                                style: const TextStyle(
                                  color: AppColors.kluayMai,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                  text: th.substring(idx + sfp.length)),
                            ],
                          ),
                        ),
                ),
                const Icon(Icons.volume_up,
                    size: 14, color: AppColors.khramLight),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              ko,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.khramLight),
            ),
          ],
        ),
      ),
    );
  }

  static const _thStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.khram,
    height: 1.5,
    fontFamilyFallback: AppTheme.fontFallback,
  );
}
