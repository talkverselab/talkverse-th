import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/memorized_store.dart';
import '../services/phrasebook_service.dart';
import '../services/root_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import '../widgets/vocab_sheet.dart';

/// 여행 회화집 — 캡처한 회화집 본문(12~153쪽)을 섹션·주제별로.
/// 문장 카드(탭=TTS, 길게=상세), 단어 표(탭=단어장 시트), TIP.
class PhrasebookScreen extends StatefulWidget {
  final String? initialSection;
  const PhrasebookScreen({super.key, this.initialSection});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  bool _loading = true;
  String _section = 'basic';
  String _query = '';
  final _ctrl = TextEditingController();
  final Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    MemorizedStore.load();
    if (widget.initialSection != null) _section = widget.initialSection!;
    _load();
  }

  Future<void> _load() async {
    await PhrasebookService.instance.ensureLoaded();
    await VocabService.instance.ensureLoaded();
    await RootService.instance.ensureLoaded();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = PhrasebookService.instance;
    final searching = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('여행 회화집',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('คู่มือท่องเที่ยว',
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.khram,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                    decoration: InputDecoration(
                      hintText: '문장·단어 검색 (태국어 · 독음 · 뜻 · 영어)',
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
                if (!searching)
                  Container(
                    color: AppColors.creamDeep,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: svc.sections.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, i) {
                          final s = svc.sections[i];
                          final selected = s.id == _section;
                          return GestureDetector(
                            onTap: () => setState(() => _section = s.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.kluayMai
                                    : AppColors.cream,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.kluayMaiDeep
                                      : AppColors.thong.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                '${s.emoji} ${s.name}',
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.cream
                                      : AppColors.khram,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const LaiThaiDivider(height: 8),
                Expanded(
                  child: searching ? _buildSearch(svc) : _buildSection(svc),
                ),
              ],
            ),
    );
  }

  Widget _buildSearch(PhrasebookService svc) {
    final hits = svc.search(_query);
    if (hits.isEmpty) {
      return const Center(
        child: Text('검색 결과 없음',
            style: TextStyle(color: AppColors.khramLight)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      itemCount: hits.length,
      itemBuilder: (context, i) {
        final h = hits[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: h.group.isWord
              ? _WordRow(row: h.row, page: h.group.page, showPage: true)
              : _PhraseCard(
                  row: h.row,
                  page: h.group.page,
                  context_: '${h.topic.title} · p.${h.group.page}',
                ),
        );
      },
    );
  }

  Widget _buildSection(PhrasebookService svc) {
    final topics = svc.bySection(_section);
    final sec = svc.sections.firstWhere((s) => s.id == _section,
        orElse: () => svc.sections.first);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
          child: Row(
            children: [
              GoldEmblem(text: sec.emoji, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sec.name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.khram)),
                    Text(
                      '주제 ${topics.length} · 문장 ${svc.phraseCount(_section)} · 단어 ${svc.wordCount(_section)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.khramLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final t in topics) _topicBlock(t),
      ],
    );
  }

  Widget _topicBlock(PbTopic t) {
    final collapsed = _collapsed.contains(t.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.thong.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (collapsed) {
                _collapsed.remove(t.id);
              } else {
                _collapsed.add(t.id);
              }
            }),
            child: Container(
              color: AppColors.creamDeep,
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title.isEmpty ? '(제목 없음)' : t.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.khram),
                        ),
                        Text(
                          'p.${t.page}  ·  문장 ${t.phraseCount} · 단어 ${t.wordCount}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.khramLight),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    collapsed ? Icons.expand_more : Icons.expand_less,
                    color: AppColors.khramLight,
                  ),
                ],
              ),
            ),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (t.intro.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(t.intro,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: AppColors.khramLight)),
                    ),
                  for (final g in t.groups) _groupBlock(g),
                  for (final n in t.notes) _NoteBox(note: n),
                  if (t.captions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        t.captions.join('\n'),
                        style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.45,
                            color: AppColors.khramLight,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _groupBlock(PbGroup g) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (g.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    color: g.isWord ? AppColors.morakot : AppColors.kluayMai,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      g.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: g.isWord
                            ? AppColors.morakot
                            : AppColors.kluayMaiDeep,
                        fontFamilyFallback: AppTheme.fontFallback,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (g.isWord)
            for (final r in g.rows) _WordRow(row: r, page: g.page)
          else
            for (final r in g.rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PhraseCard(row: r, page: g.page),
              ),
        ],
      ),
    );
  }
}

/// 문장 카드 — 탭: TTS, 길게: 상세(루트·영어·외움).
class _PhraseCard extends StatelessWidget {
  final PbRow row;
  final int page;
  final String? context_;
  const _PhraseCard({required this.row, required this.page, this.context_});

  @override
  Widget build(BuildContext context) {
    final r = row;
    return ValueListenableBuilder<int>(
      valueListenable: MemorizedStore.version,
      builder: (context, _, _) {
        final memorized = MemorizedStore.contains(r.th);
        return InkWell(
          onTap: r.template ? null : () => TtsService.instance.speak(r.speakable),
          onLongPress: () => _showPhraseSheet(context, r, page),
          child: Container(
            padding: EdgeInsets.fromLTRB(r.reply ? 22 : 12, 10, 8, 10),
            decoration: BoxDecoration(
              color: r.reply
                  ? AppColors.creamDeep.withValues(alpha: 0.55)
                  : AppColors.cream,
              border: Border(
                left: BorderSide(
                  color: memorized
                      ? AppColors.kluayMai
                      : (r.reply ? AppColors.thong : AppColors.thongDeep),
                  width: r.reply ? 2 : 3,
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
                      if (context_ != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(context_!,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.khramLight)),
                        ),
                      Text(
                        (r.reply ? '↳ ' : '') + r.ko,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.khramLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.th,
                        style: TextStyle(
                          fontSize: r.reply ? 18 : 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.khram,
                          height: 1.35,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                      if (r.reading.isNotEmpty)
                        KoReadingText(
                          r.reading,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.kluayMai,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (r.en.isNotEmpty)
                        Text(
                          r.en,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.khramLight),
                        ),
                    ],
                  ),
                ),
                if (!r.template)
                  Icon(Icons.volume_up,
                      size: 20,
                      color: memorized
                          ? AppColors.kluayMai
                          : AppColors.kluayMai.withValues(alpha: 0.7)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 단어 행 — 단어장에 있으면 시트, 없으면 TTS.
class _WordRow extends StatelessWidget {
  final PbRow row;
  final int page;
  final bool showPage;
  const _WordRow(
      {required this.row, required this.page, this.showPage = false});

  @override
  Widget build(BuildContext context) {
    final r = row;
    final entry = VocabService.instance.lookup(r.th.split('/').first);
    return InkWell(
      onTap: () {
        if (entry != null) {
          showVocabSheet(context, entry);
        } else if (!r.template) {
          TtsService.instance.speak(r.speakable);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.thong.withValues(alpha: 0.25)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                r.ko + (showPage ? '  p.$page' : ''),
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.khramLight),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.th,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.khram,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                  if (r.reading.isNotEmpty)
                    KoReadingText(
                      r.reading,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.kluayMai,
                          fontWeight: FontWeight.w700),
                    ),
                  if (RootService.instance.isLoaded)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: RootChips(th: r.th.split('/').first.trim(),
                          fontSize: 10),
                    ),
                ],
              ),
            ),
            if (entry != null)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.khramLight),
          ],
        ),
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final PbNote note;
  const _NoteBox({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.thongBright.withValues(alpha: 0.14),
        border: Border(left: BorderSide(color: AppColors.thong, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.title.isNotEmpty)
            Text(note.title,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.thongDeep,
                    fontFamilyFallback: AppTheme.fontFallback)),
          Text(note.body,
              style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.khram,
                  fontFamilyFallback: AppTheme.fontFallback)),
        ],
      ),
    );
  }
}

Future<void> _showPhraseSheet(BuildContext context, PbRow r, int page) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cream,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ValueListenableBuilder<int>(
          valueListenable: MemorizedStore.version,
          builder: (context, _, _) {
            final memorized = MemorizedStore.contains(r.th);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.th,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.khram,
                          height: 1.35,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: memorized ? '외움 해제' : '외웠어요',
                      onPressed: () => MemorizedStore.toggle(r.th),
                      icon: Icon(
                        memorized
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: memorized
                            ? AppColors.kluayMai
                            : AppColors.khramLight,
                      ),
                    ),
                    if (!r.template)
                      IconButton(
                        tooltip: '듣기',
                        onPressed: () =>
                            TtsService.instance.speak(r.speakable),
                        icon: const Icon(Icons.volume_up,
                            color: AppColors.kluayMai),
                      ),
                  ],
                ),
                if (r.reading.isNotEmpty)
                  KoReadingText(
                    r.reading,
                    style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.kluayMai,
                        fontWeight: FontWeight.w800),
                  ),
                const SizedBox(height: 8),
                Text(r.ko,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.khram)),
                if (r.en.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(r.en,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.khramLight)),
                  ),
                const SizedBox(height: 12),
                if (RootService.instance.isLoaded)
                  RootChips(th: r.th, showLabel: true, fontSize: 12),
                const SizedBox(height: 12),
                Text(
                  '회화집 본문 p.$page${r.ref.isNotEmpty ? ' · 참고 ${r.ref}' : ''}${r.uncertain ? ' · 판독 불확실' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.khramLight),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
