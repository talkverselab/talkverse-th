import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:talkverse_pitch/talkverse_pitch.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/dialogue_audio.dart';
import '../services/ko_reading.dart';
import '../services/pitch_coach.dart';
import '../services/tone_recorder.dart';
import '../services/tone_service.dart';
import '../services/tts_service.dart';
import 'tones_screen.dart';

/// 성조연습(2026-11-25, 중국어앱 b46bba1 을 태국어 5성에 맞게 옮김 — 기준 ~/talkverse/TONE_DRILL_PORT.md).
/// - 메뉴 = 성조 조합 5 × 5 = 25칸. 조합마다 2음절 낱말 12개 = 묶음 3개(낱말 4 + 문장 1).
/// - 묶음 안: 낱말 2개 → 3개 → 4개 → 문장. 말하고 나면 바로 다음 낱말.
/// - 점수는 참고용 — 빨강·「틀렸어요」·「다시」 없음. 진도는 연습한 날(낱말마다 하루 한 번, 5일이면 완료).
/// - 낱말은 성조 이름을 판정하지 않는다(모듈의 낱말 판정은 중국어 전용). 목표 모양과 얼마나 닮았는지만 보인다.
/// - 태국어는 이어 말할 때 성조가 바뀌는 규칙(중국어 3성 변조 같은 것)이 없어 그 안내는 없다. 자료에는 소리 나는 성조를 적는다.
class ToneDrillHubScreen extends StatefulWidget {
  const ToneDrillHubScreen({super.key});

  @override
  State<ToneDrillHubScreen> createState() => _ToneDrillHubScreenState();
}

String toneName(String t) => ToneService.toneNameKo[t] ?? t;

/// 'mid-low' → 「평성 + 저성」.
String comboName(String cell) => cell.split('-').map(toneName).join(' + ');

class _ToneDrillHubScreenState extends State<ToneDrillHubScreen> {
  ToneDrillData? _d;
  final Map<String, int> _days = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final d = await PitchCoach.instance.data();
    for (final c in d.combos) {
      for (final w in c.words) {
        _days[w.th] = await PitchCoach.instance.days(w.th);
      }
    }
    if (mounted) setState(() => _d = d);
  }

  Future<void> _open(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(tr('성조연습'))),
      body: d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)), children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.creamDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.thong)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('낱말 2개 → 3개 → 4개 → 문장'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram)),
                  const SizedBox(height: 6),
                  Text(
                    tr('성조 조합을 골라 2음절 낱말을 따라 말해요. 처음엔 2개만 번갈아 나오고, 몇 번 말하면 하나씩 늘어나요. 마지막엔 문장이에요.\n곡선과 점수는 참고용이에요. 낱말마다 하루 한 번씩, 5일 동안 말해 보면 완료예요.\n성조는 글자에 쓰인 부호가 아니라 실제로 소리 나는 성조예요.\n녹음은 이 기기 안에서만 분석해요.'),
                    style: const TextStyle(color: AppColors.khramLight, fontSize: 12, height: 1.5),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 20, backgroundColor: AppColors.kluayMaiLight, child: const Icon(Icons.school_outlined, color: AppColors.kluayMaiDeep)),
                title: Text(tr('준비: 성조 5개 듣기'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.khram)),
                subtitle: Text(tr('평성·저성·하성·고성·상성을 한 음절로 익히기'), style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(const TonesScreen()),
              ),
              const Divider(height: 16),
              for (final c in d.combos) _comboTile(c),
            ]),
    );
  }

  Widget _comboTile(DrillCombo c) {
    final ws = c.words;
    final done = ws.where((w) => (_days[w.th] ?? 0) >= PitchCoach.daysToFinish).length;
    final all = done == ws.length;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(colors: [toneColor(c.tones[0]).withValues(alpha: 0.45), toneColor(c.tones[1]).withValues(alpha: 0.45)]),
          border: Border.all(color: all ? AppColors.morakot : AppColors.thong, width: all ? 2 : 1),
        ),
        child: all ? const Icon(Icons.check, color: AppColors.morakot) : null,
      ),
      title: Text(comboName(c.cell), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram)),
      subtitle: Text('${ws.take(3).map((w) => w.th).join(' · ')} …  ${trf('완료 {0}/{1}', [done, ws.length])}', style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(ToneComboScreen(combo: c)),
    );
  }
}

/// 조합 하나: 아직 완료 안 된 낱말이 있는 첫 묶음부터 바로 시작.
class ToneComboScreen extends StatefulWidget {
  const ToneComboScreen({super.key, required this.combo});
  final DrillCombo combo;

  @override
  State<ToneComboScreen> createState() => _ToneComboScreenState();
}

class _ToneComboScreenState extends State<ToneComboScreen> {
  int? _i;

  @override
  void initState() {
    super.initState();
    () async {
      final rs = widget.combo.rounds;
      var i = 0;
      for (; i < rs.length; i++) {
        var open = false;
        for (final w in rs[i].words) {
          if (await PitchCoach.instance.days(w.th) < PitchCoach.daysToFinish) open = true;
        }
        if (open) break;
      }
      if (mounted) setState(() => _i = i < rs.length ? i : 0);
    }();
  }

  @override
  Widget build(BuildContext context) {
    final i = _i;
    if (i == null) return const Scaffold(backgroundColor: AppColors.cream, body: Center(child: CircularProgressIndicator()));
    final n = widget.combo.rounds.length;
    return ToneRoundScreen(
      key: ValueKey(i),
      title: '${comboName(widget.combo.cell)} · ${trf('묶음 {0}/{1}', [i + 1, n])}',
      round: widget.combo.rounds[i],
      last: i == n - 1,
      onNext: () => setState(() => _i = (i + 1) % n),
    );
  }
}

/// 묶음 하나: 낱말 2개 → 3개 → 4개(낱말마다 이번에 [_perStep]번 말하면 하나 추가) → 문장.
class ToneRoundScreen extends StatefulWidget {
  const ToneRoundScreen({super.key, required this.title, required this.round, required this.onNext, this.last = false});
  final String title;
  final DrillRound round;
  final VoidCallback onNext;
  final bool last;

  @override
  State<ToneRoundScreen> createState() => _ToneRoundScreenState();
}

class _ToneRoundScreenState extends State<ToneRoundScreen> {
  static const _perStep = 3; // 이번 연습에서 낱말마다 이만큼 말하면 다음 낱말을 넣는다(점수와 무관)
  final _rnd = math.Random();
  int _active = 2;
  late final List<int> _tries = List.filled(widget.round.words.length, 0);
  final Map<String, int> _days = {};
  int _cur = 0;
  int? _last;
  bool _sentence = false;
  bool _recording = false;
  double _level = 0;
  DrillWord? _prevWord;
  WordResult? _prev;
  SentenceResult? _sres;
  String? _note;

  List<DrillWord> get _ws => widget.round.words;
  DrillWord get _w => _ws[_cur];

  @override
  void initState() {
    super.initState();
    () async {
      for (final w in _ws) {
        _days[w.th] = await PitchCoach.instance.days(w.th);
      }
      if (mounted) setState(() {});
    }();
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  /// 낱말이 바뀔 때마다 먼저 들려준다.
  void _say() {
    if (mounted && !_sentence && !_recording) TtsService.instance.speak(_w.th);
  }

  @override
  void dispose() {
    ToneRecorder.instance.cancel();
    DialogueAudio.instance.stop();
    super.dispose();
  }

  /// 앞 낱말도 계속 섞되, 이번에 덜 말한 낱말을 더 자주.
  int _pick() {
    final idx = [for (var i = 0; i < _active; i++) if (i != _last || _active == 1) i];
    final wt = [for (final i in idx) 1.0 + 2 * math.max(0, _perStep - _tries[i])];
    var x = _rnd.nextDouble() * wt.reduce((a, b) => a + b);
    for (var k = 0; k < idx.length; k++) {
      x -= wt[k];
      if (x <= 0) return idx[k];
    }
    return idx.last;
  }

  void _next() {
    setState(() {
      _last = _cur;
      _cur = _pick();
    });
    _say();
  }

  void _advance() {
    if (_active < _ws.length) {
      setState(() {
        _active++;
        _last = _cur;
        _cur = _active - 1; // 새 낱말을 먼저 한 번
        _note = trf('새 낱말 추가 — 이제 {0}개', [_active]);
      });
      _say();
    } else {
      setState(() {
        _sentence = true;
        _note = null;
      });
      _playSentence();
    }
  }

  Future<bool> _mic() async {
    if (await ToneRecorder.instance.hasPermission()) return true;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('마이크 권한이 필요해요.'))));
    return false;
  }

  Future<void> _recordWord() async {
    if (_recording || !await _mic()) return;
    await TtsService.instance.stop();
    final w = _w;
    setState(() => (_recording = true, _note = null));
    WordResult r;
    try {
      r = await PitchCoach.instance.scoreWord(w, onLevel: (l) => mounted ? setState(() => _level = l) : null);
    } catch (_) {
      r = const WordResult([], null);
    }
    if (!mounted) return;
    if (!r.valid) {
      setState(() => (_recording = false, _note = tr('소리를 잘 못 들었어요 — 또렷하게 한 번 더 말해 봐요')));
      return;
    }
    await PitchCoach.instance.countPractice(w.th); // 점수와 무관하게 연습으로 센다(하루 한 번)
    final days = await PitchCoach.instance.days(w.th);
    if (!mounted) return;
    setState(() {
      _recording = false;
      _prevWord = w;
      _prev = r;
      _days[w.th] = days;
      _tries[_cur]++;
    });
    if ([for (var i = 0; i < _active; i++) _tries[i]].every((t) => t >= _perStep)) {
      _advance();
    } else {
      _next(); // 말하고 나면 바로 다음 낱말
    }
  }

  Future<void> _recordSentence() async {
    if (_recording || !await _mic()) return;
    await DialogueAudio.instance.stop();
    setState(() => (_recording = true, _sres = null));
    SentenceResult r;
    try {
      r = await PitchCoach.instance.scoreSentence(widget.round.sentence, onLevel: (l) => mounted ? setState(() => _level = l) : null);
    } catch (_) {
      r = SentenceResult(null, null);
    }
    if (mounted) setState(() => (_recording = false, _sres = r));
  }

  Future<void> _playSentence() async {
    final s = widget.round.sentence;
    if (!await DialogueAudio.instance.play(s.ep, s.turn)) await TtsService.instance.speak(s.th);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)), children: [
        _steps(),
        const SizedBox(height: 12),
        if (_note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_note!, style: const TextStyle(color: AppColors.kluayMaiDeep, fontWeight: FontWeight.w700)),
          ),
        if (!_sentence) ..._wordView() else ..._sentenceView(),
      ]),
    );
  }

  Widget _steps() {
    final labels = [tr('낱말 2개'), tr('3개'), tr('4개'), tr('문장')];
    final at = _sentence ? 3 : _active - 2;
    return Row(children: [
      for (var i = 0; i < 4; i++) ...[
        Expanded(
          child: InkWell(
            // 잠금 없음 — 단계를 눌러 옮겨 갈 수 있다
            onTap: _recording
                ? null
                : () => setState(() {
                      _sentence = i == 3;
                      if (i < 3) {
                        _active = i + 2;
                        if (_cur >= _active) _cur = 0;
                      } else {
                        _playSentence();
                      }
                    }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: i < at ? AppColors.morakot.withValues(alpha: 0.15) : i == at ? AppColors.kluayMaiLight : AppColors.creamDeep,
                border: Border.all(color: i == at ? AppColors.kluayMai : AppColors.thong),
              ),
              child: Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: i == at ? FontWeight.w800 : FontWeight.w500, color: AppColors.khram)),
            ),
          ),
        ),
        if (i < 3) const SizedBox(width: 4),
      ],
    ]);
  }

  /// 낱말 칩: 연습한 날 ●(5일이면 완료).
  Widget _wordChip(int i) {
    final w = _ws[i], d = _days[w.th] ?? 0, n = PitchCoach.daysToFinish;
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: i == _cur ? AppColors.kluayMaiLight : AppColors.creamDeep,
      label: Text(d >= n ? '${w.th}  ✓' : '${w.th}  ${'●' * d}${'○' * (n - d)}', style: const TextStyle(fontSize: 12, color: AppColors.khram)),
    );
  }

  Widget _recordRow(VoidCallback listen, VoidCallback record) => Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _recording ? null : listen, icon: const Icon(Icons.volume_up), label: Text(tr('듣기')))),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _recording ? null : record,
            icon: Icon(_recording ? Icons.graphic_eq : Icons.mic),
            label: Text(_recording ? tr('말하세요…') : tr('따라 말하기')),
          ),
        ),
      ]);

  List<Widget> _wordView() {
    final w = _w;
    return [
      Wrap(spacing: 6, runSpacing: 6, children: [for (var i = 0; i < _active; i++) _wordChip(i)]),
      const SizedBox(height: 4),
      Text(tr('● = 연습한 날(하루 한 번 셈) · 5일이면 완료'), style: const TextStyle(fontSize: 10, color: AppColors.khramLight)),
      const SizedBox(height: 14),
      Center(
        child: Text.rich(
          TextSpan(children: [
            for (var i = 0; i < w.syl.length; i++) TextSpan(text: w.syl[i], style: TextStyle(color: toneColor(w.tones[i]))),
          ]),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, height: 1.5),
        ),
      ),
      Center(child: KoReadingText(w.rd, th: w.th, style: const TextStyle(fontSize: 17, color: AppColors.khramLight))),
      Center(child: Text(w.ko, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.khramLight))),
      const SizedBox(height: 10),
      // 말하기 전에 이 낱말의 목표 곡선부터 보여 준다
      SizedBox(height: 116, child: CustomPaint(key: const ValueKey('target-graph'), painter: _SylPainter(w.tones, null), size: Size.infinite)),
      const SizedBox(height: 12),
      _recordRow(() => TtsService.instance.speak(w.th), _recordWord),
      if (_recording) Padding(padding: const EdgeInsets.only(top: 8), child: LinearProgressIndicator(value: (_level * 6).clamp(0.0, 1.0))),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(onPressed: _recording ? null : _next, child: Text(tr('다음 낱말'))),
        TextButton(onPressed: _recording ? null : _advance, child: Text(_active < _ws.length ? tr('낱말 하나 더') : tr('문장으로'))),
      ]),
      if (_prev != null && _prevWord != null) ..._prevView(_prevWord!, _prev!),
    ];
  }

  /// 방금 말한 낱말 — 참고용 곡선·점수.
  List<Widget> _prevView(DrillWord w, WordResult r) {
    return [
      const Divider(height: 24),
      Row(children: [
        Text(trf('방금: {0}', [w.th]), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram)),
        const SizedBox(width: 8),
        Text(tr('(참고용)'), style: const TextStyle(fontSize: 11, color: AppColors.khramLight)),
        const Spacer(),
        Text(trf('참고 점수 {0}', [((r.score ?? 0) * 100).round()]), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram)),
      ]),
      const SizedBox(height: 6),
      SizedBox(height: 120, child: CustomPaint(painter: _SylPainter(w.tones, r), size: Size.infinite)),
      const SizedBox(height: 4),
      Text(
        r.syllables.isEmpty ? tr('채운 곡선 = 목표 · 음절이 잘 안 나뉘어 내 소리 선은 그리지 않았어요') : tr('채운 곡선 = 목표 · 선 = 내 소리(평소 내 음높이 기준)'),
        style: const TextStyle(fontSize: 10, color: AppColors.khramLight),
      ),
    ];
  }

  List<Widget> _sentenceView() {
    final s = widget.round.sentence;
    final r = _sres;
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.creamDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.thong)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.th, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.khram, height: 1.5)),
          const SizedBox(height: 4),
          KoReadingText(s.rd, th: s.th, style: const TextStyle(fontSize: 14, color: AppColors.khramLight)),
          Text(s.ko, style: const TextStyle(fontSize: 13, color: AppColors.khramLight)),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(height: 150, child: CustomPaint(painter: _SentPainter(s.ref, r?.mine), size: Size.infinite)),
      const SizedBox(height: 4),
      Text(tr('채운 곡선 = 기준 음성 · 선 = 내 소리 — 문장은 겹쳐 보기만 해요'), style: const TextStyle(fontSize: 10, color: AppColors.khramLight)),
      if (r != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            r.match == null ? tr('소리를 잘 못 들었어요 — 또렷하게 한 번 더 말해 봐요') : trf('참고 점수 {0}', [(r.match!.score * 100).round()]),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.khram),
          ),
        ),
      const SizedBox(height: 14),
      _recordRow(_playSentence, _recordSentence),
      if (_recording) Padding(padding: const EdgeInsets.only(top: 8), child: LinearProgressIndicator(value: (_level * 6).clamp(0.0, 1.0))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(onPressed: _recording ? null : () => setState(() => (_sentence = false, _sres = null)), child: Text(tr('낱말로 돌아가기'))),
        FilledButton(onPressed: _recording ? null : widget.onNext, child: Text(widget.last ? tr('처음 묶음으로') : tr('다음 묶음'))),
      ]),
    ];
  }
}

/// 그래프 세로 범위(반음, 위아래). 내 소리가 이 밖으로 나가면 범위를 넓혀 바닥에 평평하게 잘리지 않게 한다.
double _yMax = 8.0;
const _labelH = 16.0; // 칸 위 성조 이름 자리
double _y(double st, Size s) {
  final half = (s.height - _labelH) / 2 - 6;
  return _labelH + (s.height - _labelH) / 2 - (st.clamp(-_yMax, _yMax) / _yMax) * half;
}

double _rangeFor(Iterable<double> mine) {
  var m = 8.0;
  for (final v in mine) {
    if (v.abs() > m) m = v.abs();
  }
  return m.clamp(8.0, 24.0) + (m > 8 ? 1 : 0);
}

void _frame(Canvas c, Size s) {
  c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(8)), Paint()..color = AppColors.creamDeep);
  c.drawLine(Offset(0, _y(0, s)), Offset(s.width, _y(0, s)), Paint()..color = AppColors.thong..strokeWidth = 1);
}

void _boxLabel(Canvas c, String text, Rect box, Color color) {
  final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)), textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…')
    ..layout(maxWidth: box.width);
  tp.paint(c, Offset(box.left + (box.width - tp.width) / 2, 2));
}

void _curve(Canvas c, List<double> v, Rect box, Size s, Paint p) {
  if (v.length < 2) return;
  final pts = [for (var i = 0; i < v.length; i++) Offset(box.left + box.width * i / (v.length - 1), _y(v[i], s))];
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final o in pts.skip(1)) {
    path.lineTo(o.dx, o.dy);
  }
  c.drawPath(path, p..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round);
}

/// 목표 곡선 = 아래가 채워진 그래프(사용자 지시 「긴 막대선 말고 아래가 채워진 그래프」). 곡선은 부드럽게 잇고 그 아래를 옅게 채운다.
void _area(Canvas c, List<double> v, Rect box, Size s, Color color) {
  if (v.length < 2) return;
  final pts = [for (var i = 0; i < v.length; i++) Offset(box.left + box.width * i / (v.length - 1), _y(v[i], s))];
  final line = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 0; i + 1 < pts.length; i++) {
    final m = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
    line.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
  }
  line.lineTo(pts.last.dx, pts.last.dy);
  final fill = Path.from(line)
    ..lineTo(pts.last.dx, s.height)
    ..lineTo(pts.first.dx, s.height)
    ..close();
  c.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.08)])
            .createShader(Offset.zero & s));
  c.drawPath(
      line,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round);
}

/// 낱말: 음절 칸마다 목표(채움) + 내 소리(선). 내 소리 선은 한 가지 색 — 맞다·틀리다로 칠하지 않는다.
class _SylPainter extends CustomPainter {
  _SylPainter(this.tones, this.result);
  final List<String> tones;
  final WordResult? result;

  @override
  void paint(Canvas c, Size s) {
    final mine = result?.syllables ?? const <Contour?>[];
    _yMax = _rangeFor([for (final x in mine) ...?x?.st]);
    _frame(c, s);
    final n = tones.length, w = s.width / n;
    for (var i = 0; i < n; i++) {
      final box = Rect.fromLTWH(i * w + 8, 0, w - 16, s.height);
      if (i > 0) c.drawLine(Offset(i * w, 0), Offset(i * w, s.height), Paint()..color = AppColors.thong);
      _area(c, thaiIdeal(tones[i]), box, s, toneColor(tones[i]));
      _boxLabel(c, toneName(tones[i]), box, toneColor(tones[i]));
      if (i < mine.length && mine[i] != null) {
        _curve(c, mine[i]!.st, box, s,
            Paint()
              ..color = AppColors.khram
              ..strokeWidth = 3.5
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SylPainter o) => o.result != result || o.tones != tones;
}

class _SentPainter extends CustomPainter {
  _SentPainter(this.ref, this.mine);
  final Contour ref;
  final Contour? mine;

  @override
  void paint(Canvas c, Size s) {
    _yMax = _rangeFor([...ref.centered().st, ...?mine?.centered().st]);
    _frame(c, s);
    final box = Rect.fromLTWH(8, 0, s.width - 16, s.height);
    _area(c, ref.centered().st, box, s, AppColors.thongDeep);
    final m = mine;
    if (m != null) _curve(c, m.centered().st, box, s, Paint()..color = AppColors.kluayMaiDeep..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _SentPainter o) => o.mine != mine;
}
