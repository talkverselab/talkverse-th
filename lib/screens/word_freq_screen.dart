import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/thai_decor.dart';

/// 단어 빈도 1000 — Netflix 원어 코퍼스 (R1~R4 티어).
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<WordEntry> _words = [];
  bool _loading = true;
  String _filter = 'ALL';

  static const Map<String, _Tier> _tiers = {
    'ALL': _Tier('전체', AppColors.khram),
    'R1': _Tier('R1 · 코어', AppColors.kluayMai),
    'R2': _Tier('R2 · 확장', AppColors.kluayMaiLight),
    'R3': _Tier('R3 · 중급', AppColors.thong),
    'R4': _Tier('R4 · 고급', AppColors.morakot),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw =
        await rootBundle.loadString('assets/data/wordsets/th_top1000.csv');
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    final entries = <WordEntry>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;
      entries.add(WordEntry(
        rank: int.tryParse('${row[0]}') ?? 0,
        word: '${row[1]}',
        freq: double.tryParse('${row[2]}') ?? 0,
        tier: '${row[3]}',
        domain: '${row[4]}',
      ));
    }
    if (!mounted) return;
    setState(() {
      _words = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'ALL'
        ? _words
        : _words.where((w) => w.tier == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('단어 빈도 1000')),
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
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _tiers.entries.map((e) {
                        final selected = _filter == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    selected ? e.value.color : AppColors.cream,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: e.value.color,
                                  width: selected ? 1.5 : 0.8,
                                ),
                              ),
                              child: Text(
                                e.value.label,
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.cream
                                      : e.value.color,
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
                const LaiThaiDivider(),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Container(
                        height: 0.5,
                        color: AppColors.thong.withValues(alpha: 0.3)),
                    itemBuilder: (context, i) {
                      final w = filtered[i];
                      final tier = _tiers[w.tier];
                      return Container(
                        color: AppColors.cream,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                '#${w.rank}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.khramLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.word,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.khram,
                                      fontFamilyFallback:
                                          AppTheme.fontFallback,
                                    ),
                                  ),
                                  Text(
                                    '빈도 ${w.freq.toStringAsFixed(0)} · ${w.domain}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.khramLight),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up,
                                  size: 18, color: AppColors.kluayMai),
                              onPressed: () =>
                                  TtsService.instance.speak(w.word),
                            ),
                            if (tier != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tier.color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  w.tier,
                                  style: const TextStyle(
                                    color: AppColors.cream,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class WordEntry {
  final int rank;
  final String word;
  final double freq;
  final String tier;
  final String domain;
  WordEntry({
    required this.rank,
    required this.word,
    required this.freq,
    required this.tier,
    required this.domain,
  });
}

class _Tier {
  final String label;
  final Color color;
  const _Tier(this.label, this.color);
}
