import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/purchase.dart';
import '../services/custom_script_service.dart';
import '../services/dialogue_service.dart';
import '../data/entitlement.dart';
import '../services/learner_prefs.dart';
import '../widgets/thai_decor.dart';
import 'dialogue_screen.dart';

/// 「맞춤 회화 만들기」 — 2026-11-02. 도메인(주제) · 상황 · 레벨을 고르면 그 사람만의 편 1개를 서버가 만든다(비동기, 몇 분~).
/// 위: 「내 맞춤 회화」 서랍(만드는 중·완성·실패) / 아래: 입력 3단계 + 만들기. 첫 1편 무료.
/// 계약·흐름: `docs/CUSTOM_SCRIPT_API.md`.
class CustomScriptScreen extends StatefulWidget {
  const CustomScriptScreen({super.key});
  @override
  State<CustomScriptScreen> createState() => _CustomScriptScreenState();
}

class _CustomScriptScreenState extends State<CustomScriptScreen> {
  final _svc = CustomScriptService.instance;
  final _situation = TextEditingController();
  final _name = TextEditingController();
  String _domain = 'life';
  String _level = 'R1';
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    DialogueService.instance.ensureLoaded();
    _svc.ensureLoaded().then((_) async {
      _level = ['R0', 'R1'].contains(DialogueService.instance.level) ? DialogueService.instance.level : 'R1';
      if (_name.text.isEmpty) _name.text = LearnerPrefs.name.value;
      if (mounted) setState(() => _loading = false);
      await _refresh();
      _poll = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _situation.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!_svc.items.any((e) => e.isWorking)) return;
    final changed = await _svc.refresh();
    if (changed && mounted) setState(() {});
  }

  Future<void> _create() async {
    final sit = _situation.text.trim();
    if (sit.isEmpty) {
      _snack(tr('상황을 한 줄 적어 주세요'), AppColors.kluayMaiDeep);
      return;
    }
    setState(() => _sending = true);
    final r = await _svc.create(domain: _domain, situation: sit, level: _level, name: _name.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.item != null) {
      _situation.clear();
      _snack(tr('접수됐어요. 몇 분 뒤 「내 맞춤 회화」에 들어와요'), AppColors.morakot);
      setState(() {});
      return;
    }
    switch (r.error) {
      case 'paid_required':
        if (Entitlement.premium) {
          _snack(tr('이용권은 있지만 서버가 확인하지 못했어요. 로그인 상태를 확인해 주세요'), AppColors.kluayMaiDeep);
        } else {
          _snack(tr('첫 1편은 무료예요. 다음 편부터는 이용권이 필요해요'), AppColors.kluayMaiDeep);
          Entitlement.showPaywall(context);
        }
      case 'monthly_limit':
        _snack(trf('이번 달 맞춤 회화를 모두 만들었어요({0}편). 다음 달 1일(한국 시간)에 다시 만들 수 있어요', [_svc.lastLimit ?? 5]), AppColors.kluayMaiDeep);
      case 'daily_limit':
        _snack(tr('맞춤 회화는 하루 1편까지예요. 내일(한국 시간) 다시 만들어 주세요'), AppColors.kluayMaiDeep);
      case 'offline':
        _snack(tr('지금은 만들 수 없어요. 잠시 뒤 다시 시도해 주세요'), AppColors.kluayMaiDeep);
      default:
        _snack('${tr('오류')}: ${r.error}', AppColors.kluayMaiDeep);
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final form = _Form(
      domain: _domain,
      level: _level,
      situation: _situation,
      name: _name,
      sending: _sending,
      onDomain: (d) => setState(() => _domain = d),
      onLevel: (l) => setState(() => _level = l),
      onSuggest: (s) => setState(() => _situation.text = s),
      onCreate: _create,
    );
    final drawer = _Drawer(items: _svc.items, onRefresh: () async {
      await _svc.refresh();
      if (mounted) setState(() {});
    }, onRemove: (id) async {
      await _svc.remove(id);
      if (mounted) setState(() {});
    });
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(tr('맞춤 회화 만들기'), style: const TextStyle(color: AppColors.khram, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.kluayMaiDeep))
          : wide && MediaQuery.sizeOf(context).width >= 1000
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 6, child: ListView(padding: EdgeInsets.fromLTRB(16, 8, 8, 24 + bottomInset(context)), children: [form])),
                  Expanded(flex: 5, child: ListView(padding: EdgeInsets.fromLTRB(8, 8, 16, 24 + bottomInset(context)), children: [drawer])),
                ])
              : ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)),
                  children: [if (_svc.items.isNotEmpty) ...[drawer, const SizedBox(height: 16)], form],
                ),
    );
  }
}

class _Form extends StatelessWidget {
  final String domain, level;
  final TextEditingController situation, name;
  final bool sending;
  final ValueChanged<String> onDomain, onLevel, onSuggest;
  final VoidCallback onCreate;
  const _Form({
    required this.domain,
    required this.level,
    required this.situation,
    required this.name,
    required this.sending,
    required this.onDomain,
    required this.onLevel,
    required this.onSuggest,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final sugg = CustomScriptService.suggestions[domain] ?? const <String>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.creamDeep, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.thong)),
        child: Row(children: [
          const Text('✨', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tr('주제·상황·레벨을 고르면 나만의 회화 1편을 만들어 드려요. 완성까지 몇 분 걸리고, 첫 1편은 무료예요.'),
                style: const TextStyle(fontSize: 12.5, color: AppColors.khram, height: 1.45)),
          ),
        ]),
      ),
      _step(1, tr('어느 주제?')),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final isl in DialogueService.islands)
            ChoiceChip(
              label: Text('${DialogueService.islandEmoji[isl]} ${tr(DialogueService.islandKo[isl]!)}'),
              selected: domain == isl,
              onSelected: (_) => onDomain(isl),
              selectedColor: AppColors.kluayMaiDeep.withValues(alpha: 0.14),
              labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: domain == isl ? AppColors.sunsetDeep : AppColors.khram),
              side: BorderSide(color: domain == isl ? AppColors.kluayMaiDeep : AppColors.thong),
            ),
        ],
      ),
      _step(2, tr('어떤 상황?')),
      TextField(
        controller: situation,
        maxLength: 120,
        maxLines: 2,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.khram),
        decoration: InputDecoration(
          hintText: tr('예: 방콕 호텔에 늦게 도착해서 체크인'),
          hintStyle: const TextStyle(color: AppColors.khramLight, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.thong)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.thong)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kluayMaiDeep, width: 1.5)),
        ),
      ),
      if (sugg.isNotEmpty) ...[
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in sugg)
              ActionChip(
                label: Text(tr(s), style: const TextStyle(fontSize: 11.5, color: AppColors.thai, fontWeight: FontWeight.w700)),
                onPressed: () => onSuggest(tr(s)),
                side: BorderSide(color: AppColors.thai.withValues(alpha: 0.4)),
                backgroundColor: AppColors.thai.withValues(alpha: 0.06),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
      _step(3, tr('레벨')),
      SegmentedButton<String>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
        segments: [for (final lv in CustomScriptService.levels) ButtonSegment(value: lv, label: Text(tr(DialogueService.levelKo[lv]!)))],
        selected: {level},
        onSelectionChanged: (s) => onLevel(s.first),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: name,
        maxLength: 20,
        style: const TextStyle(fontSize: 14, color: AppColors.khram),
        decoration: InputDecoration(
          labelText: tr('내 이름(선택) — 회화 속 「나」로 나와요'),
          labelStyle: const TextStyle(fontSize: 12, color: AppColors.khramLight),
          isDense: true,
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.thong)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.thong)),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: sending ? null : onCreate,
          style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: const StadiumBorder()),
          icon: sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
          label: Text(sending ? tr('보내는 중…') : tr('나만의 회화 만들기'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ),
      const SizedBox(height: 6),
      Center(child: Text(_usage(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.khramLight, height: 1.4))),
    ]);
  }

  /// 한도 안내(2026-11-09): 무료 평생 1편 / 이용권 한 달 5편 / 종합 이용권 한 달 10편 · 하루 1편(한국 시간).
  String _usage() {
    final svc = CustomScriptService.instance;
    if (!Entitlement.premium) return tr('무료 1편 · 이용권이 있으면 한 달 5편(하루 1편) · 완성되면 「내 맞춤 회화」에');
    final cap = svc.lastLimit ?? (Purchase.owned.value.keys.any((k) => k.startsWith('all_')) ? 10 : 5);
    return trf('이번 달 {0}/{1}편 · 하루 1편 · 완성되면 「내 맞춤 회화」에', [svc.usedThisMonth().clamp(0, cap), cap]);
  }

  Widget _step(int n, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.khram, shape: BoxShape.circle),
            child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.khram)),
        ]),
      );
}

class _Drawer extends StatelessWidget {
  final List<CustomScriptItem> items;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String id) onRemove;
  const _Drawer({required this.items, required this.onRefresh, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(tr('내 맞춤 회화'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.khram)),
        const SizedBox(width: 6),
        Text('${items.length}', style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
        const Spacer(),
        if (items.any((e) => e.isWorking))
          TextButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh, size: 16), label: Text(tr('새로고침'), style: const TextStyle(fontSize: 12))),
      ]),
      const SizedBox(height: 6),
      if (items.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.thong)),
          child: Text(tr('아직 없어요. 아래에서 첫 편을 만들어 보세요.'), style: const TextStyle(fontSize: 12.5, color: AppColors.khramLight)),
        ),
      for (final it in items) _Row(item: it, onRemove: () => onRemove(it.id)),
    ]);
  }
}

class _Row extends StatelessWidget {
  final CustomScriptItem item;
  final VoidCallback onRemove;
  const _Row({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final d = item.dialogue;
    final emoji = d?.emoji ?? DialogueService.islandEmoji[item.domain] ?? '💬';
    final title = d?.title ?? item.situation;
    final (label, color) = switch (item.status) {
      'ready' => (tr('완성'), AppColors.morakot),
      'failed' => (tr('실패'), AppColors.kluayMaiDeep),
      'writing' => (tr('쓰는 중'), AppColors.thai),
      _ => (tr('대기 중'), AppColors.kluayMaiDeep),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.thong), boxShadow: _kCardShadow),
      child: ListTile(
        onTap: item.isReady ? () => openFull(context, (_) => DialogueScreen(dialogue: d!)) : null,
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.khram)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(children: [
            _pill(label, color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${tr(DialogueService.levelKo[item.level] ?? item.level)} · ${tr(DialogueService.islandKo[item.domain] ?? item.domain)}'
                '${d != null ? ' · ${trf('{0}턴', [d.turns.length])}' : ''}'
                '${item.status == 'failed' && item.error != null ? ' · ${item.error}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.khramLight),
              ),
            ),
          ]),
        ),
        trailing: item.isReady
            ? const Icon(Icons.chevron_right, color: AppColors.khramLight)
            : item.isWorking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.thai))
                : IconButton(tooltip: tr('닫기'), icon: const Icon(Icons.close, size: 18, color: AppColors.khramLight), onPressed: onRemove),
      ),
    );
  }

  Widget _pill(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c)),
      );
}

/// 맞춤 회화 메뉴를 보일지 — 워커(launchd)를 켜는 것은 사용자 결정 대기(HANDOFF). 켜면 true 로.
const bool kCustomScriptLive = false;

/// 주제별 회화 홈 상단 진입 카드.
class CustomScriptEntryCard extends StatelessWidget {
  const CustomScriptEntryCard({super.key});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => openPane(context, (_) => const CustomScriptScreen()),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.kluayMaiDeep, AppColors.kluayMai], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _kCardShadow,
          ),
          child: Row(children: [
            const Text('✨', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('맞춤 회화 만들기'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(tr('주제·상황·레벨을 고르면 나만의 1편 · 첫 편 무료'), style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ]),
        ),
      );
}

/// 홈 상단에 둘 장식용 구분선(톤 유지).
class CustomScriptDivider extends StatelessWidget {
  const CustomScriptDivider({super.key});
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: SilkDivider(height: 2));
}

const List<BoxShadow> _kCardShadow = [BoxShadow(color: Color(0x1A5A3E28), blurRadius: 5, offset: Offset(0, 2), spreadRadius: -1)];
