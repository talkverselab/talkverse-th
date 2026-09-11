import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/thai_decor.dart';

/// 영어 유래 단어 — 영어가 태국어로 음차되는 8가지 줄기와 최다 사용 200단어.
/// 줄기 칩 → 규칙 설명 카드 → 단어 목록(재생 버튼, 예외 표시).
class LoanwordScreen extends StatefulWidget {
  const LoanwordScreen({super.key});

  @override
  State<LoanwordScreen> createState() => _LoanwordScreenState();
}

class _Group {
  final String id;
  final String name;
  final String emoji;
  final String rule;
  final String examples;

  /// 대응표 행: [영어, 소리, 태국어 표기, 한글, 예]. 모음 그룹에만 있다.
  final List<List<String>> table;
  const _Group(this.id, this.name, this.emoji, this.rule, this.examples,
      [this.table = const []]);
}

class _Word {
  final String th;
  final String reading;
  final String en;
  final String ko;
  final String group;
  final String note;
  final bool exception;
  const _Word({
    required this.th,
    required this.reading,
    required this.en,
    required this.ko,
    required this.group,
    required this.note,
    required this.exception,
  });
}

class _LoanwordScreenState extends State<LoanwordScreen> {
  bool _loading = true;
  List<_Group> _groups = [];
  List<_Word> _words = [];
  String _group = 'ALL';
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/wordsets/th_loanwords.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      _groups = [
        for (final g in (data['groups'] as List? ?? []).whereType<Map>())
          _Group(
            '${g['id'] ?? ''}',
            '${g['name'] ?? ''}',
            '${g['emoji'] ?? '🔤'}',
            '${g['rule'] ?? ''}',
            '${g['examples'] ?? ''}',
            [
              for (final row in (g['table'] as List? ?? []).whereType<List>())
                [for (final c in row) '$c'],
            ],
          ),
      ];
      _words = [
        for (final w in (data['words'] as List? ?? []).whereType<Map>())
          _Word(
            th: '${w['th'] ?? ''}',
            reading: '${w['reading'] ?? ''}',
            en: '${w['en'] ?? ''}',
            ko: '${w['ko'] ?? ''}',
            group: '${w['group'] ?? ''}',
            note: '${w['note'] ?? ''}',
            exception: w['exception'] == true,
          ),
      ];
    } catch (_) {
      // 에셋 없이도 동작
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<_Word> get _list {
    Iterable<_Word> pool =
        _group == 'ALL' ? _words : _words.where((w) => w.group == _group);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      pool = pool.where((w) =>
          w.th.contains(q) ||
          w.en.toLowerCase().contains(q) ||
          w.ko.contains(q) ||
          w.reading.replaceAll(' ', '').contains(q.replaceAll(' ', '')));
    }
    return pool.toList();
  }

  _Group? get _current =>
      _group == 'ALL' ? null : _groups.firstWhere((g) => g.id == _group);

  @override
  Widget build(BuildContext context) {
    final list = _loading ? const <_Word>[] : _list;
    final cur = _current;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('영어 유래 단어',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('คำทับศัพท์ · 음차 규칙 8줄기',
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
                      hintText: '태국어 · 영어 · 뜻 · 독음',
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
                          label: '전체 ${_words.length}',
                          selected: _group == 'ALL',
                          onTap: () => setState(() => _group = 'ALL'),
                        ),
                        for (final g in _groups)
                          _Chip(
                            label:
                                '${g.emoji} ${g.name} ${_words.where((w) => w.group == g.id).length}',
                            selected: _group == g.id,
                            color: g.id == 'exception'
                                ? const Color(0xFFC62828)
                                : AppColors.kluayMai,
                            onTap: () => setState(() => _group = g.id),
                          ),
                      ],
                    ),
                  ),
                ),
                const LaiThaiDivider(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
                    children: [
                      if (cur != null) _RuleCard(group: cur),
                      if (cur == null)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(2, 2, 2, 10),
                          child: Text(
                            '영어 단어가 태국어에 들어올 때 소리가 바뀌는 규칙을 8가지 줄기로 나눴어요. 줄기를 고르면 규칙 설명과 해당 단어가 보입니다. 규칙에서 벗어나는 단어는 "예외"로 표시했습니다.',
                            style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.khramLight),
                          ),
                        ),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('단어가 없어요',
                                style:
                                    TextStyle(color: AppColors.khramLight)),
                          ),
                        ),
                      for (final w in list) _WordRow(word: w),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// 영어 모음 → 태국어 모음 대응표. 같은 영어 모음은 첫 행에만 글자를 쓴다.
class _VowelTable extends StatelessWidget {
  final List<List<String>> rows;
  final Color color;
  const _VowelTable({required this.rows, required this.color});

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      color: AppColors.khramLight,
      letterSpacing: 1,
    );
    const cell = TextStyle(
      fontSize: 12.5,
      height: 1.35,
      color: AppColors.khram,
      fontFamilyFallback: AppTheme.fontFallback,
    );
    final thStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w900,
      color: color,
      fontFamilyFallback: AppTheme.fontFallback,
    );
    const koStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w900,
      color: AppColors.thongDeep,
    );

    final line = BorderSide(color: AppColors.thong.withValues(alpha: 0.5));
    String prev = '';
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(26),
        1: FlexColumnWidth(1.25),
        2: FixedColumnWidth(58),
        3: FixedColumnWidth(36),
        4: FlexColumnWidth(2.2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: line,
        top: line,
        bottom: line,
      ),
      children: [
        const TableRow(children: [
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('', style: head)),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('영어 소리', style: head)),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('태국어', style: head)),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('한글', style: head)),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('예', style: head)),
        ]),
        for (final r in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(
                  r[0] == prev ? '' : (prev = r[0]),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 7, 6, 7),
                child: Text(r[1], style: cell),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(r[2], style: thStyle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(r[3], style: koStyle),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 7, 0, 7),
                child: Text(r[4], style: cell),
              ),
            ],
          ),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  final _Group group;
  const _RuleCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final isEx = group.id == 'exception';
    final color = isEx ? const Color(0xFFC62828) : AppColors.kluayMaiDeep;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GoldEmblem(text: group.emoji, size: 36, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.name,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            group.rule,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.khram,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
          if (group.examples.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '예) ${group.examples}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamilyFallback: AppTheme.fontFallback,
              ),
            ),
          ],
          if (group.table.isNotEmpty) ...[
            const SizedBox(height: 10),
            _VowelTable(rows: group.table, color: color),
          ],
        ],
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final _Word word;
  const _WordRow({required this.word});

  @override
  Widget build(BuildContext context) {
    final w = word;
    final exColor = const Color(0xFFC62828);
    return InkWell(
      onTap: () => TtsService.instance.speak(w.th),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border(
            bottom: BorderSide(color: AppColors.thong.withValues(alpha: 0.3)),
            left: BorderSide(
              color: w.exception ? exColor : AppColors.thong,
              width: w.exception ? 3 : 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                        w.en,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.morakot,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (w.exception) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          color: exColor,
                          child: const Text('예외',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ),
                      ],
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
                    w.note.isEmpty ? w.ko : '${w.ko}  ·  ${w.note}',
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
  final Color color;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.kluayMai,
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
            color: selected ? color : AppColors.cream,
            border: Border.all(color: color, width: selected ? 1.5 : 0.8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.khram,
            ),
          ),
        ),
      ),
    );
  }
}
