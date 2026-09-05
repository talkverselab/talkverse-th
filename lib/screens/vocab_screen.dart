import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/memorized_store.dart';
import '../services/root_service.dart';
import '../services/vocab_service.dart';
import '../widgets/thai_decor.dart';
import '../widgets/vocab_sheet.dart';
import 'thai_roots_screen.dart';

enum _Source { all, capture, book }

/// 통합 단어장 — 회화집 단어장(캡처, 가나다순) + 나혼자 30일.
class VocabScreen extends StatefulWidget {
  final int? initialDay;
  const VocabScreen({super.key, this.initialDay});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  bool _loading = true;
  _Source _source = _Source.all;
  int? _day;
  String _query = '';
  bool _onlyUnmemorized = false;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    MemorizedStore.load();
    if (widget.initialDay != null) {
      _source = _Source.book;
      _day = widget.initialDay;
    }
    _load();
  }

  Future<void> _load() async {
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

  List<VocabEntry> get _list {
    final svc = VocabService.instance;
    Iterable<VocabEntry> pool = switch (_source) {
      _Source.all => svc.entries,
      _Source.capture => svc.captureEntries,
      _Source.book => _day == null ? svc.bookEntries : svc.byDay(_day!),
    };
    var out = svc.search(_query, within: pool);
    if (_onlyUnmemorized) {
      out = out.where((e) => !MemorizedStore.contains(e.th)).toList();
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final svc = VocabService.instance;
    final list = _loading ? const <VocabEntry>[] : _list;
    final days = svc.themes.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('단어장'),
        actions: [
          IconButton(
            tooltip: '루트 단어',
            icon: const Icon(Icons.account_tree_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ThaiRootsScreen())),
          ),
        ],
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
                      hintText: '태국어 · 한글 독음 · 뜻',
                      hintStyle: const TextStyle(
                          color: AppColors.khramLight, fontSize: 14),
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
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _Chip(
                          label: '전체 ${svc.count}',
                          selected: _source == _Source.all,
                          onTap: () => setState(() {
                            _source = _Source.all;
                            _day = null;
                          }),
                        ),
                        _Chip(
                          label: '회화집 ${svc.captureEntries.length}',
                          selected: _source == _Source.capture,
                          onTap: () => setState(() {
                            _source = _Source.capture;
                            _day = null;
                          }),
                        ),
                        _Chip(
                          label: '나혼자 30일 ${svc.bookEntries.length}',
                          selected: _source == _Source.book,
                          onTap: () => setState(() {
                            _source = _Source.book;
                          }),
                        ),
                        _Chip(
                          label: '안 외운 것만',
                          selected: _onlyUnmemorized,
                          color: AppColors.morakot,
                          onTap: () => setState(
                              () => _onlyUnmemorized = !_onlyUnmemorized),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_source == _Source.book)
                  Container(
                    color: AppColors.creamDeep,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _Chip(
                            label: '전체',
                            selected: _day == null,
                            color: AppColors.thongDeep,
                            small: true,
                            onTap: () => setState(() => _day = null),
                          ),
                          for (final d in days)
                            _Chip(
                              label: '$d일 ${svc.themes[d]}',
                              selected: _day == d,
                              color: AppColors.thongDeep,
                              small: true,
                              onTap: () => setState(() => _day = d),
                            ),
                        ],
                      ),
                    ),
                  ),
                const LaiThaiDivider(),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text('검색 결과가 없어요',
                              style: TextStyle(color: AppColors.khramLight)))
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, _) => Container(
                              height: 0.5,
                              color: AppColors.thong.withValues(alpha: 0.3)),
                          itemBuilder: (context, i) =>
                              VocabRow(entry: list[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final bool small;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.kluayMai,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: small ? 10 : 14, vertical: small ? 4 : 6),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.cream,
            border: Border.all(color: color, width: selected ? 1.5 : 0.8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.cream : color,
              fontWeight: FontWeight.w700,
              fontSize: small ? 11 : 12,
            ),
          ),
        ),
      ),
    );
  }
}
