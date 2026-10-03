import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import '../core/l10n.dart';
import '../core/platform.dart';

/// 추가 교육 단어 — 태국 교육부 기초 단어(ป.1~3) 중 우리 단어장에 없는 단어.
/// 회화 빈도가 낮아 본 과정에서는 가르치지 않는다(알고 있지만 일부러 뺌). 참고용 목록.
/// 출처 목록에 주제 분류가 없어 학년으로만 나눈다.
class ExtraEduWordsScreen extends StatefulWidget {
  const ExtraEduWordsScreen({super.key});

  @override
  State<ExtraEduWordsScreen> createState() => _ExtraEduWordsScreenState();
}

class _ExtraEduWordsScreenState extends State<ExtraEduWordsScreen> {
  static const _grades = ['ป.1', 'ป.2', 'ป.3'];
  bool _loading = true;
  List<VocabEntry> _words = [];
  String _grade = 'ALL';
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await VocabService.instance.ensureLoaded();
    _words = VocabService.instance.extraEduEntries;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<VocabEntry> get _list {
    Iterable<VocabEntry> pool =
        _grade == 'ALL' ? _words : _words.where((w) => w.theme == _grade);
    final q = _query.trim();
    if (q.isNotEmpty) {
      pool = pool.where((w) =>
          w.th.contains(q) ||
          w.ko.contains(q) ||
          w.reading.replaceAll(' ', '').contains(q.replaceAll(' ', '')));
    }
    return pool.toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _loading ? <VocabEntry>[] : _list;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('추가 교육 단어'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text(trf('교육부 기초 단어 · 단어장에 없는 {0}단어', [_words.length]),
                style: TextStyle(fontSize: 10, letterSpacing: 2)),
          ],
        ),
        actions: const [KoReadingToggleAction()],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.khram,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                    decoration: InputDecoration(
                      hintText: tr('태국어 · 뜻 · 독음'),
                      hintStyle: const TextStyle(
                          color: AppColors.khramLight, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.kluayMai),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _ctrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.creamDeep,
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppColors.thong),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: AppColors.kluayMai, width: 1.5),
                      ),
                    ),
                  ),
                ),
                Container(
                  color: AppColors.creamDeep,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _Chip(
                          label: trf('전체 {0}', [_words.length]),
                          selected: _grade == 'ALL',
                          onTap: () => setState(() => _grade = 'ALL'),
                        ),
                        for (final g in _grades)
                          _Chip(
                            label:
                                '$g ${_words.where((w) => w.theme == g).length}',
                            selected: _grade == g,
                            onTap: () => setState(() => _grade = g),
                          ),
                      ],
                    ),
                  ),
                ),
                const LaiThaiDivider(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                        14, 8, 14, 32 + bottomInset(context)),
                    itemCount: list.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(2, 2, 2, 10),
                          child: Text(
                            tr('태국 교육부가 초등 1~3학년에 제시한 기초 단어 중, 우리 단어장에 없는 단어만 모았어요. 영화·드라마 회화에는 거의 나오지 않아(절벽 R1~R4 안에 드는 것은 거친 말 몇 개뿐) 본 과정에서는 일부러 가르치지 않습니다. 알아 두고 싶을 때 참고하세요.'),
                            style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.khramLight),
                          ),
                        );
                      }
                      return _WordRow(word: list[i - 1]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final VocabEntry word;
  const _WordRow({required this.word});

  @override
  Widget build(BuildContext context) {
    final w = word;
    return InkWell(
      onTap: () => TtsService.instance.speak(w.th),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border(
            bottom: BorderSide(color: AppColors.thong.withValues(alpha: 0.3)),
            left: const BorderSide(color: AppColors.thong),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          w.th,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: AppColors.khram,
                            fontFamilyFallback: AppTheme.fontFallback,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        w.theme,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.khramLight,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                    ],
                  ),
                  KoReadingText(
                    w.reading,
                    th: w.th,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.kluayMaiDeep,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    w.ko,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.khramLight,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, color: AppColors.kluayMai),
              onPressed: () => TtsService.instance.speak(w.th),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.kluayMai : AppColors.cream,
            border: Border.all(
                color: AppColors.kluayMai, width: selected ? 1.5 : 0.8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.khram,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
        ),
      ),
    );
  }
}
