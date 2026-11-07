import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/cliff_service.dart';
import '../services/root_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import '../widgets/vocab_sheet.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../services/ko_reading.dart';

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
  String _filter = 'ALL'; // 절벽구간 필터(사용자 지시 2026-11-07: 루트도 회화 절벽구간 기준으로)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await RootService.instance.ensureLoaded();
    await CliffService.instance.ensureLoaded();
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
          (_) => _openFamily(root, highlight: widget.fromWord ?? ''),
        );
      }
    }
  }

  /// 루트의 구간 = 루트 낱말 자체의 회화 빈도 구간(2,000위 밖이면 회화).
  static String _regionOf(RootInfo r) => CliffService.instance.regionOf(r.th) ?? 'C';

  List<RootInfo> get _filtered {
    final q = _query.trim();
    return _roots
        .where((r) => _filter == 'ALL' || _regionOf(r) == _filter)
        .where((r) => q.isEmpty || r.th.contains(q) || r.reading.contains(q) || r.ko.contains(q))
        .toList();
  }

  /// 구간별 묶음(R1 → R5 → 회화), 구간 안은 빈도순.
  List<(String, List<RootInfo>)> get _sections {
    final by = <String, List<RootInfo>>{};
    for (final r in _filtered) {
      by.putIfAbsent(_regionOf(r), () => []).add(r);
    }
    final cs = CliffService.instance;
    for (final l in by.values) {
      l.sort((a, b) => (cs.rankOf(a.th) ?? 99999).compareTo(cs.rankOf(b.th) ?? 99999));
    }
    return [for (final g in CliffService.regions) if (by.containsKey(g)) (g, by[g]!)];
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
      0,
      (s, r) => s + RootService.instance.familyOf(r).count,
    );
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('루트 단어')),
            Text(
              tr('핵심 형태소 → 파생어 가족'),
              style: TextStyle(fontSize: 10, letterSpacing: 1),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kluayMai),
            )
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
                      hintText: tr('น้ำ · 남 · 물'),
                      hintStyle: const TextStyle(
                        color: AppColors.khramLight,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.kluayMai,
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
                        borderSide: BorderSide(
                          color: AppColors.kluayMai,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const GoldEmblem(text: 'ราก', size: 22),
                      const SizedBox(width: 8),
                      Text(
                        trf('루트 {0}개 · 파생어 {1}개', [_roots.length, total]),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.khram,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tr('탭 → 파생어 가족'),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.khramLight,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: [
                      for (final g in ['ALL', ...CliffService.regions])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _RegionChip(
                            label: g == 'ALL' ? tr('전체') : CliffService.rangeLabel(g),
                            color: g == 'ALL' ? AppColors.khram : CliffService.colorOf(g),
                            count: g == 'ALL' ? _roots.length : _roots.where((r) => _regionOf(r) == g).length,
                            selected: _filter == g,
                            onTap: () => setState(() => _filter = g),
                          ),
                        ),
                    ],
                  ),
                ),
                const LaiThaiDivider(height: 8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, 24 + bottomInset(context)),
                    children: [
                      for (final (region, roots) in _sections) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
                          child: Row(children: [
                            RegionBadge(region, fontSize: 11),
                            const SizedBox(width: 8),
                            Text(CliffService.rangeLabel(region), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.khram)),
                            const Spacer(),
                            Text(trf('루트 {0}개', [roots.length]), style: const TextStyle(fontSize: 11, color: AppColors.khramLight)),
                          ]),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.9,
                          ),
                          itemCount: roots.length,
                          itemBuilder: (context, i) {
                            final r = roots[i];
                            return _RootCard(
                              root: r,
                              region: region,
                              count: RootService.instance.familyOf(r).count,
                              onTap: () => _openFamily(r),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// 구간 칩 — 전체 / R1~R5 / 회화 (루트 수).
class _RegionChip extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _RegionChip({required this.label, required this.color, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.cream,
            border: Border.all(color: color, width: selected ? 1.5 : 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$label · $count',
              style: TextStyle(color: selected ? AppColors.onFill(color) : color, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      );
}

class _RootCard extends StatelessWidget {
  final RootInfo root;
  final String region;
  final int count;
  final VoidCallback onTap;
  const _RootCard({
    required this.root,
    required this.region,
    required this.count,
    required this.onTap,
  });

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
                    KoReadingText(
                      root.reading,
                      th: root.th,
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
                        fontSize: 11,
                        color: AppColors.khramLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      RegionBadge(region),
                      const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.thong.withValues(alpha: 0.18),
                        border: Border.all(color: AppColors.thong),
                      ),
                      child: Text(
                        trf('파생 {0}개', [count]),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.khram,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ]),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.khramLight,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 루트 가족 시트 — 루트 헤더 + 앞/뒤/가운데 섹션의 타일 그리드 (zh 발음부 스타일). 타일에 분해 공식(방 + 물 ⇒ 화장실).
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
      padding: EdgeInsets.fromLTRB(0, 12, 0, 24 + bottomInset(context)),
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
                icon: const Icon(
                  Icons.volume_up,
                  color: AppColors.kluayMai,
                  size: 28,
                ),
                onPressed: () => TtsService.instance.speak(root.th),
              ),
              if (selfEntry != null)
                IconButton(
                  tooltip: tr('단어 상세'),
                  icon: const Icon(
                    Icons.info_outline,
                    color: AppColors.khramLight,
                  ),
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
        ..._sections(context, root),
        if (family.count == 0)
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              tr('아직 단어장에 파생어가 없어요.'),
              style: TextStyle(color: AppColors.khramLight),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            tr('💡 같은 루트 = 뜻이 이어지는 경향. 앞에 붙으면 "루트+수식", 뒤에 붙으면 "수식+루트"로 읽어 보세요.'),
            style: TextStyle(fontSize: 11.5, color: AppColors.khramLight),
          ),
        ),
        if (highlight.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text(
              trf('← {0} 에서 이동', [highlight]),
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

  List<Widget> _sections(BuildContext context, RootInfo root) {
    final r = root.th;
    final prefix = <VocabEntry>[];
    final suffix = <VocabEntry>[];
    final middle = <VocabEntry>[];
    for (final e in family.strong) {
      final v = e.variants.first.trim();
      if (v.startsWith(r)) {
        prefix.add(e);
      } else if (v.endsWith(r)) {
        suffix.add(e);
      } else {
        middle.add(e);
      }
    }
    return [
      if (prefix.isNotEmpty)
        _FamilySection(
          label: tr('앞에 붙음'),
          sub: '$r + ○○',
          color: AppColors.morakot,
          root: r,
          entries: prefix,
        ),
      if (suffix.isNotEmpty)
        _FamilySection(
          label: tr('뒤에 붙음'),
          sub: '○○ + $r',
          color: AppColors.thongDeep,
          root: r,
          entries: suffix,
        ),
      if (middle.isNotEmpty)
        _FamilySection(
          label: tr('가운데'),
          sub: '○ + $r + ○',
          color: const Color(0xFFC62828),
          root: r,
          entries: middle,
        ),
    ];
  }
}

/// 색상 섹션 — 라벨 + 타일 그리드(3열).
class _FamilySection extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final String root;
  final List<VocabEntry> entries;
  const _FamilySection({
    required this.label,
    required this.sub,
    required this.color,
    required this.root,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: color,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.khramLight,
                    fontFamilyFallback: AppTheme.fontFallback,
                  ),
                ),
              ),
              Text(
                trf('{0}개', [entries.length]),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 12) / 3;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in entries)
                    SizedBox(
                      width: w,
                      child: _WordTile(entry: e, root: root, color: color),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 파생어 타일 — 태국어(루트 강조)·독음·뜻·스피커. 탭하면 단어 상세.
class _WordTile extends StatelessWidget {
  final VocabEntry entry;
  final String root;
  final Color color;
  const _WordTile({
    required this.entry,
    required this.root,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final th = entry.variants.first.trim();
    final idx = th.indexOf(root);
    const base = TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w900,
      color: AppColors.khram,
      fontFamilyFallback: AppTheme.fontFallback,
      height: 1.3,
    );
    return InkWell(
      onTap: () => showVocabSheet(context, entry),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: idx < 0
                      ? Text(th, style: base)
                      : RichText(
                          text: TextSpan(
                            style: base,
                            children: [
                              TextSpan(text: th.substring(0, idx)),
                              TextSpan(
                                text: root,
                                style: TextStyle(color: color),
                              ),
                              TextSpan(text: th.substring(idx + root.length)),
                            ],
                          ),
                        ),
                ),
                GestureDetector(
                  onTap: () => TtsService.instance.speak(entry.speakable),
                  child: Icon(Icons.volume_up, size: 16, color: color),
                ),
              ],
            ),
            if (CliffService.instance.regionOf(entry.th) case final g?) Padding(padding: const EdgeInsets.only(bottom: 2), child: RegionBadge(g, fontSize: 8)),
            if (entry.reading.isNotEmpty)
              KoReadingText(
                entry.reading,
                th: entry.th,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            Text(
              RootService.instance.formula(entry.th, root, entry.ko),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.khram,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
