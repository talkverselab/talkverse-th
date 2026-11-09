import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/cliff_service.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/word_art_thumb.dart';
import '../core/embed_env.dart';

/// 절벽 단어 — 회화 빈도 1~2,000위를 절벽구간(R1~R5)별 **20어 단원**으로, 단어는 **네모 타일**로 보여 준다(사용자 지시 2026-11-07, 모든 언어앱 공통).
/// 위 버튼 「절벽구간 단어만 / 회화 단어 포함」 — 포함이면 회화 전 편에 나오지만 2,000위 밖인 단어가 「회화」 구간으로 뒤에 붙는다.
/// 빈도표와 회화 단어 목록은 assets/data/wordsets/th_cliff_words.json 에 따로 두고 화면에서만 합친다(tools/vocab_pipeline/build_cliff_words.py).
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

const int kUnit = 20;

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<WordEntry> _words = [];
  List<WordEntry> _conv = [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';

  static Map<String, _Region> get _regions => {
    'ALL': _Region(tr('전체'), AppColors.khram),
    for (final r in CliffService.regions) r: _Region(CliffService.rangeLabel(r), CliffService.colorOf(r)),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final j = json.decode(await tvBundle.loadString('assets/data/wordsets/th_cliff_words.json')) as Map<String, dynamic>;
    WordEntry read(Map<String, dynamic> m, int rank, String region) =>
        WordEntry(rank: rank, word: m['w'] as String, reading: (m['rd'] as String?) ?? '', ko: (m['ko'] as String?) ?? '', region: region);
    final words = [
      for (final m in (j['words'] as List).cast<Map<String, dynamic>>()) read(m, m['r'] as int, m['g'] as String),
    ];
    var n = 0;
    final conv = [
      for (final m in (j['conv'] as List).cast<Map<String, dynamic>>()) read(m, ++n, 'C'),
    ];
    if (!mounted) return;
    setState(() {
      _words = words;
      _conv = conv;
      _loading = false;
    });
  }

  List<WordEntry> get _pool => _withConv ? [..._words, ..._conv] : _words;

  void _setMode(bool withConv) => setState(() {
        _withConv = withConv;
        if (!withConv && _filter == 'C') _filter = 'ALL';
      });

  @override
  Widget build(BuildContext context) {
    final pool = _pool;
    final filtered = _filter == 'ALL' ? pool : pool.where((w) => w.region == _filter).toList();
    final units = <List<WordEntry>>[
      for (var i = 0; i < filtered.length; i += kUnit) filtered.sublist(i, (i + kUnit).clamp(0, filtered.length)),
    ];
    final regions = _regions;
    final chips = regions.entries.where((e) => e.key != 'C' || _withConv).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        actions: const [KoReadingToggleAction()],
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('절벽 단어'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(trf('회화 빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['2,000', kUnit]), style: const TextStyle(fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.kluayMai))
          : Column(
              children: [
                Container(
                  color: AppColors.creamDeep,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _ModeButton(label: tr('절벽구간 단어만'), selected: !_withConv, onTap: () => _setMode(false)),
                          const SizedBox(width: 8),
                          _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => _setMode(true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final e in chips)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _filter = e.key),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _filter == e.key ? e.value.color : AppColors.cream,
                                      border: Border.all(color: e.value.color, width: _filter == e.key ? 1.5 : 0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(e.value.label,
                                        style: TextStyle(
                                            color: _filter == e.key ? AppColors.onFill(e.value.color) : e.value.color,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                    itemCount: units.length,
                    itemBuilder: (context, i) => _UnitBlock(index: i + 1, words: units[i], regions: regions),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.khram : AppColors.cream,
              border: Border.all(color: selected ? AppColors.khram : AppColors.thong),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.cream : AppColors.khram, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class _UnitBlock extends StatelessWidget {
  final int index;
  final List<WordEntry> words;
  final Map<String, _Region> regions;
  const _UnitBlock({required this.index, required this.words, required this.regions});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final last = words.last;
    final region = regions[first.region];
    final range = first.region == 'C' ? trf('회화 {0}-{1}', [first.rank, last.rank]) : '#${first.rank}-${last.rank}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
            child: Row(
              children: [
                Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.khram, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Text(range, style: const TextStyle(color: AppColors.khramLight, fontSize: 11)),
                const Spacer(),
                if (region != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: region.color, borderRadius: BorderRadius.circular(3)),
                    child: Text(first.region == 'C' ? tr('회화') : first.region,
                        style: TextStyle(color: AppColors.onFill(region.color), fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, c) {
              final cols = (c.maxWidth / 112).floor().clamp(3, 8); // 두 화면 오른쪽 칸에서도 칸 폭 기준
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6),
                itemCount: words.length,
                itemBuilder: (context, i) => _WordTile(w: words[i], color: region?.color ?? AppColors.khram),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 네모 타일 — 순위·읽기 · 그림(있으면) · 단어 · 뜻 한 줄. 탭하면 발음.
class _WordTile extends StatelessWidget {
  final WordEntry w;
  final Color color;
  const _WordTile({required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TtsService.instance.speak(w.word),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.thong),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, c) {
            final art = (c.maxHeight * 0.38).clamp(24.0, 72.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(w.region == 'C' ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: KoReadingText(w.reading, th: w.word, textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, color: AppColors.khramLight)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                WordArtThumb(word: w.word, size: art),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(w.word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.khram)),
                ),
                if (w.ko.isNotEmpty)
                  Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.khramLight)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WordEntry {
  final int rank;
  final String word;
  final String reading;
  final String ko;
  final String region; // R1~R5 · C(회화 단어)
  const WordEntry({required this.rank, required this.word, required this.reading, required this.ko, required this.region});
}

class _Region {
  final String label;
  final Color color;
  const _Region(this.label, this.color);
}
