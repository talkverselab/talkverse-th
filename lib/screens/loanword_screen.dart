import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/thai_decor.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/embed_env.dart';
import '../core/pane.dart';
import 'loanword_quiz_screen.dart';

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
  final int st; // 1=핵심 · 2=중급까지 · 3=전체(일본어앱 110 과 같은 3단계, 2026-11-19)
  const _Word({
    required this.th,
    required this.reading,
    required this.en,
    required this.ko,
    required this.group,
    required this.note,
    required this.exception,
    this.st = 3,
  });
}

class _LoanwordScreenState extends State<LoanwordScreen> {
  bool _loading = true;
  List<_Group> _groups = [];
  List<_Word> _words = [];
  String _group = 'ALL';
  int _stage = 1; // 1단계(핵심) 디폴트
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await tvBundle
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
            st: (w['st'] as num?)?.toInt() ?? 3,
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
    Iterable<_Word> pool = (_group == 'ALL' ? _words : _words.where((w) => w.group == _group))
        .where((w) => w.st <= _stage);
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
    final list = _loading ? <_Word>[] : _list;
    final cur = _current;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('영어 유래 단어'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text(tr('คำทับศัพท์ · 음차 규칙 8줄기'),
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
                      hintText: tr('태국어 · 영어 · 뜻 · 독음'),
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
                Container(
                  color: AppColors.creamDeep,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final st in const [1, 2, 3])
                          _Chip(
                            label: st == 1
                                ? trf('1단계 핵심 {0}', [_words.where((w) => w.st <= 1).length])
                                : st == 2
                                    ? trf('2단계 중급까지 {0}', [_words.where((w) => w.st <= 2).length])
                                    : trf('3단계 전체 {0}', [_words.length]),
                            selected: _stage == st,
                            onTap: () => setState(() => _stage = st),
                          ),
                        _Chip(
                          key: const ValueKey('loanword-quiz'),
                          label: tr('📝 퀴즈 복습'),
                          selected: false,
                          color: const Color(0xFFC62828),
                          onTap: () => openFull(
                            context,
                            (_) => LoanwordQuizScreen(words: [
                              for (final w in _words)
                                if (w.st <= _stage) LQWord(w.th, w.en, w.ko, w.reading),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const LaiThaiDivider(height: 8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(14, 8, 14, 32 + bottomInset(context)),
                    children: [
                      if (cur != null) _RuleCard(group: cur),
                      if (cur == null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(2, 2, 2, 10),
                          child: Text(
                            tr('영어 단어가 태국어로 들어올 때 소리가 바뀌는 규칙 8가지예요. 줄기를 고르면 규칙과 단어가 보여요.'),
                            style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.khramLight),
                          ),
                        ),
                      if (list.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(tr('단어가 없어요'),
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

/// 영어 → 태국어 대응표(자음·모음). 같은 영어 글자는 첫 행에만 쓴다.
class _MapTable extends StatelessWidget {
  final List<List<String>> rows;
  final Color color;
  const _MapTable({required this.rows, required this.color});

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
      columnWidths: {
        0: FixedColumnWidth(26),
        1: FlexColumnWidth(1.25),
        2: FixedColumnWidth(62),
        3: FixedColumnWidth(46),
        4: FlexColumnWidth(2.2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: line,
        top: line,
        bottom: line,
      ),
      children: [
        TableRow(children: [
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('', style: head)),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text(tr('영어 소리'), style: head)),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text(tr('태국어'), style: head)),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text(tr('한글'), style: head)),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text(tr('예'), style: head)),
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
              trf('예) {0}', [group.examples]),
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
            _MapTable(rows: group.table, color: color),
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
                          child: Text(tr('예외'),
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
    super.key,
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
