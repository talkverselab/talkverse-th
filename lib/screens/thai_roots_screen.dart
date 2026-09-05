import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/root_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import '../widgets/vocab_sheet.dart';

/// 루트 단어 탐색 — zh 의 발음부(声旁) 화면에 대응.
/// 카드를 탭하면 그 루트를 공유하는 파생어 가족 시트가 열린다.
class ThaiRootsScreen extends StatefulWidget {
  /// [focusRoot]가 있으면 진입 시 해당 루트 가족 시트를 자동으로 연다.
  /// [fromWord]는 어떤 단어에서 이동해 왔는지 (가족에서 하이라이트).
  final String? focusRoot;
  final String? fromWord;
  const ThaiRootsScreen({super.key, this.focusRoot, this.fromWord});

  @override
  State<ThaiRootsScreen> createState() => _ThaiRootsScreenState();
}

class _ThaiRootsScreenState extends State<ThaiRootsScreen> {
  bool _loading = true;
  List<RootInfo> _roots = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await RootService.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _roots = RootService.instance.roots;
      _loading = false;
    });
    final focus = widget.focusRoot;
    if (focus != null) {
      final root = RootService.instance.lookup(focus);
      if (root != null) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _openFamily(root, highlight: widget.fromWord ?? ''));
      }
    }
  }

  List<RootInfo> get _filtered {
    if (_query.trim().isEmpty) return _roots;
    final q = _query.trim();
    return _roots
        .where((r) =>
            r.th.contains(q) || r.reading.contains(q) || r.ko.contains(q))
        .toList();
  }

  Future<void> _openFamily(RootInfo root, {String highlight = ''}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        builder: (context, controller) => RootFamilySheet(
          family: RootService.instance.familyOf(root),
          highlight: highlight,
          controller: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _roots.fold<int>(
        0, (s, r) => s + RootService.instance.familyOf(r).count);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('루트 단어'),
            Text('핵심 형태소 → 파생어 가족',
                style: TextStyle(fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.khram,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                    decoration: InputDecoration(
                      hintText: 'น้ำ · 남 · 물',
                      hintStyle: const TextStyle(
                          color: AppColors.khramLight, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.kluayMai),
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const GoldEmblem(text: 'ราก', size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '루트 ${_roots.length}개 · 파생어 $total개',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.khram,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      const Text('탭 → 파생어 가족',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.khramLight)),
                    ],
                  ),
                ),
                const LaiThaiDivider(height: 8),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.9,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final r = _filtered[i];
                      return _RootCard(
                        root: r,
                        count: RootService.instance.familyOf(r).count,
                        onTap: () => _openFamily(r),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _RootCard extends StatelessWidget {
  final RootInfo root;
  final int count;
  final VoidCallback onTap;
  const _RootCard(
      {required this.root, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.thong.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              GoldEmblem(text: root.th, size: 48, color: AppColors.kluayMai),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      root.reading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.khram,
                      ),
                    ),
                    Text(
                      root.ko,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.khramLight),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.thong.withValues(alpha: 0.18),
                        border: Border.all(color: AppColors.thong),
                      ),
                      child: Text(
                        '파생 $count개',
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.khram,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.khramLight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// 루트 가족 시트 — 루트 헤더 + 파생어 목록 (확실/후보).
class RootFamilySheet extends StatelessWidget {
  final RootFamily family;
  final String highlight;
  final ScrollController? controller;
  const RootFamilySheet({
    super.key,
    required this.family,
    this.highlight = '',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final root = family.root;
    final selfEntry = VocabService.instance.lookup(root.th);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GoldEmblem(text: root.th, size: 64, color: AppColors.kluayMai),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${root.th}  ${root.reading}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.khram,
                        fontFamilyFallback: AppTheme.fontFallback,
                      ),
                    ),
                    Text(
                      root.ko,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kluayMaiDeep,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up,
                    color: AppColors.kluayMai, size: 28),
                onPressed: () => TtsService.instance.speak(root.th),
              ),
              if (selfEntry != null)
                IconButton(
                  tooltip: '단어 상세',
                  icon: const Icon(Icons.info_outline,
                      color: AppColors.khramLight),
                  onPressed: () => showVocabSheet(context, selfEntry),
                ),
            ],
          ),
        ),
        if (root.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              root.note,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.khramLight,
                fontFamilyFallback: AppTheme.fontFallback,
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: LaiThaiDivider(height: 10),
        ),
        _SectionLabel('파생어 ${family.strong.length}개'),
        for (final e in family.strong)
          VocabRow(
            entry: e,
            highlightRoot: root.th,
            dense: true,
          ),
        if (family.weak.isNotEmpty) ...[
          _SectionLabel('후보 ${family.weak.length}개 · 철자만 포함'),
          for (final e in family.weak)
            VocabRow(entry: e, highlightRoot: root.th, dense: true),
        ],
        if (family.count == 0)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('아직 단어장에 파생어가 없어요.',
                style: TextStyle(color: AppColors.khramLight)),
          ),
        if (highlight.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text(
              '← $highlight 에서 이동',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.khramLight,
                fontFamilyFallback: AppTheme.fontFallback,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.creamDeep,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.khramLight,
            letterSpacing: 1.5,
          ),
        ),
      );
}
