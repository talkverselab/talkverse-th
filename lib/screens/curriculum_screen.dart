import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_audio.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../widgets/thai_decor.dart';

/// 토크버스 커리큘럼 — 전 언어 공통 기준(`~/talkverse/CURRICULUM_SPEC.md`, 2026-11-22). 일본어앱이 기준 구현.
/// 레벨 고르기 → 다이얼로그 고르기(3·5·10) → 편마다 듣기·확인 문제 → 코스 시험(80% 이상 통과) → 다음 코스. 하루 분량·복습.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final _svc = CurriculumService.instance;
  bool _loading = true;
  bool _picking = false; // 다이얼로그 고르는 중
  bool _confirmNew = false; // 「지금 코스를 버릴까요?」 칸
  bool _levelPick = false;
  int _pickCount = 5;
  final Set<String> _picked = {};

  CurriculumState get _st => _svc.state;

  @override
  void initState() {
    super.initState();
    _svc.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _levelPick = _st.level == null;
        _picking = _st.level != null && _st.course == null;
      });
    });
  }

  Future<void> _setLevel(String lv) async {
    _st.level = lv;
    await _svc.save();
    setState(() {
      _levelPick = false;
      _picked.clear();
      _picking = _st.course == null;
    });
  }

  Future<void> _startCourse() async {
    await _svc.startCourse(_picked.toList());
    setState(() {
      _picking = false;
      _picked.clear();
    });
  }

  Future<void> _practice(Dialogue d) async {
    await openFull(context, (_) => CurriculumPracticeScreen(dialogue: d));
    if (mounted) setState(() {});
  }

  Future<void> _exam() async {
    final c = _st.course!;
    final ds = [for (final id in c.dialogueIds) DialogueService.instance.byId(id)].whereType<Dialogue>().toList();
    final per = examPerDialogue(ds.length);
    final seed = DateTime.now().millisecondsSinceEpoch;
    final qs = [for (final d in ds) ...buildQuestions(d, limit: per, pool: ds, seed: seed)]..shuffle();
    final res = await openFull<QuizResult>(context, (_) => CurriculumQuizScreen(title: tr('코스 시험'), questions: qs.take(30).toList(), mode: QuizMode.exam));
    if (res == null || !mounted) return;
    final passed = _st.recordExam(res.correct, res.total, res.wrongDialogues, _svc.today, pass: _svc.passPercent);
    await _svc.save();
    if (!mounted) return;
    setState(() {});
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(passed ? tr('코스 통과!') : tr('조금만 더')),
        content: Text(passed
            ? trf('{0}점 — 80점을 넘었어요. 다음 코스를 골라요.', [scorePercent(res.correct, res.total)])
            : trf('{0}점 — 80점이 넘어야 통과예요. 틀린 편만 다시 연습하고 시험을 봐요.', [scorePercent(res.correct, res.total)])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('확인')))],
      ),
    );
    if (passed && mounted) {
      setState(() {
        _st.course = null;
        _picking = true;
      });
      await _svc.save();
    }
  }

  Future<void> _review() async {
    final due = _st.dueReview(_svc.today).take(20).toList();
    final qs = <CurQuestion>[];
    final seed = DateTime.now().millisecondsSinceEpoch;
    for (final r in due) {
      final d = DialogueService.instance.byId(r.dialogueId);
      if (d == null) continue;
      qs.addAll(buildQuestions(d, limit: 1, pool: DialogueService.instance.list(region: d.region), seed: seed, onlyTurns: {r.turn}));
    }
    if (qs.isEmpty) {
      // 원고가 바뀌어 줄이 없어진 항목은 대기열에서 뺀다
      _st.review.removeWhere((r) => due.contains(r));
      await _svc.save();
      setState(() {});
      return;
    }
    await openFull<QuizResult>(context, (_) => CurriculumQuizScreen(title: tr('오늘 복습'), questions: qs, mode: QuizMode.review));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(tr('토크버스 커리큘럼'), style: const TextStyle(color: AppColors.khram, fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          if (!_loading && _st.level != null && !_levelPick)
            TextButton(
              onPressed: () => setState(() => _levelPick = true),
              child: Text(tr(_svc.stageTitle(_st.level)), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.kluayMaiDeep)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)),
              children: _levelPick ? _levelPicker() : [_todayCard(), const SizedBox(height: 12), ..._courseBody()],
            ),
    );
  }

  // ── 레벨 고르기 ──
  List<Widget> _levelPicker() {
    final stages = _svc.stages; // 단계 목록·편 목록은 데이터에서(§12) — 편 없는 단계는 이미 빠져 있다
    final lowest = stages.isEmpty ? null : stages.first.key;
    return [
      Text(tr('단계를 골라요'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.khram)),
      const SizedBox(height: 4),
      Text(tr('처음이면 1단계부터 권해요. 문법 레벨과는 따로예요.'), style: const TextStyle(fontSize: 12.5, color: AppColors.khramLight)),
      const SizedBox(height: 12),
      for (final s in stages)
        for (final lv in [s.key])
          _card(
            onTap: () => _setLevel(lv),
            selected: _st.level == lv,
            child: Row(children: [
              GoldEmblem(text: lv, size: 40, color: AppColors.kluayMaiDeep),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr(s.title), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram)),
                  if (s.desc.isNotEmpty) Text(tr(s.desc), style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
                  Text(
                    trf('{0}편 · 통과 {1}', [s.dialogueIds.length, _svc.levelList(lv).where((d) => _st.passedDialogues.contains(d.id)).length]),
                    style: const TextStyle(fontSize: 12, color: AppColors.khramLight),
                  ),
                ]),
              ),
              if (_st.level == null && lv == lowest) _pill(tr('추천'), AppColors.morakot),
            ]),
          ),
    ];
  }

  // ── 오늘 분량 ──
  Widget _todayCard() {
    final today = _svc.today;
    final due = _st.dueReview(today).length;
    final newLeft = _st.newLeft(today);
    final doneNew = _st.todayDay == today ? _st.todayNew : 0;
    final doneRev = _st.todayDay == today ? _st.todayReview : 0;
    final total = doneNew + doneRev + due + newLeft;
    final done = _st.dayDone(today);
    final streak = _st.streakShown(today);
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(done ? tr('오늘 분량 끝') : tr('오늘 분량'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram, fontSize: 15)),
          const Spacer(),
          if (streak > 0) _pill(trf('🔥 {0}일 연속', [streak]), AppColors.kluayMaiDeep),
        ]),
        const SizedBox(height: 6),
        Text(trf('오늘: 복습 {0} · 새 편 {1}', [due, newLeft]), style: const TextStyle(fontSize: 13, color: AppColors.khramLight)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 1 : (doneNew + doneRev) / total,
            minHeight: 6,
            backgroundColor: AppColors.thong,
            color: AppColors.kluayMaiDeep,
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text(tr('하루 목표'), style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
          const SizedBox(width: 8),
          Expanded(
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              segments: [
                ButtonSegment(value: 1, label: Text(tr('가볍게'))),
                ButtonSegment(value: 2, label: Text(tr('보통'))),
                ButtonSegment(value: 3, label: Text(tr('집중'))),
              ],
              selected: {_st.dailyGoal},
              onSelectionChanged: (s) async {
                _st.dailyGoal = s.first;
                await _svc.save();
                setState(() {});
              },
            ),
          ),
        ]),
        if (due > 0) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep),
              onPressed: _review,
              icon: const Icon(Icons.replay, size: 18),
              label: Text(trf('복습 {0}줄 시작', [due])),
            ),
          ),
        ],
      ]),
    );
  }

  // ── 코스 ──
  List<Widget> _courseBody() {
    final c = _st.course;
    if (_confirmNew) {
      return [
        _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('지금 코스를 그만두고 새로 고를까요?'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram)),
            const SizedBox(height: 4),
            Text(tr('연습한 표시와 시험 점수는 사라져요. 통과한 편과 복습 줄은 남아요.'), style: const TextStyle(fontSize: 12.5, color: AppColors.khramLight)),
            const SizedBox(height: 10),
            Row(children: [
              OutlinedButton(onPressed: () => setState(() => _confirmNew = false), child: Text(tr('계속하기'))),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep),
                onPressed: () async {
                  _st.course = null;
                  await _svc.save();
                  setState(() {
                    _confirmNew = false;
                    _picking = true;
                  });
                },
                child: Text(tr('새로 고르기')),
              ),
            ]),
          ]),
        ),
      ];
    }
    if (_picking || c == null) return _picker();
    final ds = [for (final id in c.dialogueIds) DialogueService.instance.byId(id)].whereType<Dialogue>().toList();
    final lv = _st.level!;
    return [
      Row(children: [
        Text(trf('지금 코스 · {0}편', [ds.length]), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram, fontSize: 15)),
        const Spacer(),
        TextButton(onPressed: () => setState(() => _confirmNew = true), child: Text(tr('새 코스'))),
      ]),
      Text(trf('연습 {0}/{1}{2}', [c.practiced.length, ds.length, c.examScores.isEmpty ? '' : ' · ${trf('지난 시험 {0}점', [c.examScores.last])}']),
          style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
      const SizedBox(height: 8),
      for (final d in ds)
        _card(
          onTap: () => _practice(d),
          child: Row(children: [
            Text(d.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.khram)),
                Text('${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${trf('{0}줄', [d.turns.length])}', style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
              ]),
            ),
            if (c.practiced.contains(d.id)) const Icon(Icons.check_circle, color: AppColors.morakot) else _pill(tr('연습'), AppColors.kluayMaiDeep),
          ]),
        ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.khram, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: c.allPracticed && ds.isNotEmpty ? _exam : null,
          icon: const Icon(Icons.flag, size: 18),
          label: Text(c.allPracticed ? trf('코스 시험 보기 ({0}% 이상 통과)', [_svc.passPercent]) : tr('모든 편을 연습하면 시험이 열려요')),
        ),
      ),
      if (_svc.levelDone(lv) && _svc.nextLevel(lv) != null) ...[
        const SizedBox(height: 12),
        _card(
          onTap: () => _setLevel(_svc.nextLevel(lv)!),
          child: Text(trf('{0} 편을 모두 통과했어요 → {1} 로', [tr(_svc.stageTitle(lv)), tr(_svc.stageTitle(_svc.nextLevel(lv)))]), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.morakot)),
        ),
      ],
    ];
  }

  List<Widget> _picker() {
    final picks = _svc.pickCounts; // 고를 편 수는 단계 데이터에서(§12 덧붙임)
    if (!picks.contains(_pickCount)) _pickCount = picks[picks.length ~/ 2];
    final lv = _st.level!;
    final list = _svc.levelList(lv);
    final passed = _st.passedDialogues.toSet();
    final doneLevel = _svc.levelDone(lv);
    final next = _svc.nextLevel(lv);
    return [
      Text(tr('다이얼로그 고르기'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram, fontSize: 15)),
      const SizedBox(height: 2),
      Text(trf('이 편들로 연습하고, 코스 시험에서 {0}% 이상이면 다음 코스로 넘어가요.', [_svc.passPercent]), style: const TextStyle(fontSize: 12.5, color: AppColors.khramLight)),
      if (doneLevel && next != null) ...[
        const SizedBox(height: 8),
        _card(
          onTap: () => _setLevel(next),
          child: Text(trf('{0} 편을 모두 통과했어요 → {1} 로', [tr(_svc.stageTitle(lv)), tr(_svc.stageTitle(next))]), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.morakot)),
        ),
      ],
      const SizedBox(height: 10),
      // Row 대신 Wrap — 300px 폭(아이패드 분할 왼쪽)에서 넘치던 것(uk 전달, 몽골어앱 발견 2026-11-22)
      Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final n in _svc.pickCounts)
          ChoiceChip(
              label: Text(trf('{0}편', [n])),
              selected: _pickCount == n,
              onSelected: (_) => setState(() {
                _pickCount = n;
                while (_picked.length > n) {
                  _picked.remove(_picked.last);
                }
              }),
            ),
        TextButton.icon(
          onPressed: () => setState(() => _picked.addAll(recommend(list, passed, _picked, _pickCount))),
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: Text(tr('추천으로 채우기')),
        ),
      ]),
      const SizedBox(height: 6),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: _picked.isEmpty ? null : _startCourse,
          child: Text(trf('{0}/{1}편으로 코스 시작', [_picked.length, _pickCount])),
        ),
      ),
      const SizedBox(height: 10),
      for (final d in list)
        _card(
          selected: _picked.contains(d.id),
          onTap: () => setState(() {
            if (_picked.contains(d.id)) {
              _picked.remove(d.id);
            } else if (_picked.length < _pickCount) {
              _picked.add(d.id);
            }
          }),
          child: Row(children: [
            Icon(_picked.contains(d.id) ? Icons.check_box : Icons.check_box_outline_blank, color: _picked.contains(d.id) ? AppColors.kluayMaiDeep : AppColors.khramLight),
            const SizedBox(width: 8),
            Text(d.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.khram)),
                Text('${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${trf('{0}줄', [d.turns.length])}', style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
              ]),
            ),
            if (passed.contains(d.id)) _pill(tr('통과'), AppColors.morakot),
          ]),
        ),
    ];
  }
}

Widget _card({required Widget child, VoidCallback? onTap, bool selected = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.creamDeep : AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.kluayMaiDeep : AppColors.thong, width: selected ? 1.5 : 1),
            ),
            child: child,
          ),
        ),
      ),
    );

Widget _pill(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );

/// 편 하나 연습: ① 듣기·읽기(전체 재생·줄마다 뜻) ② 따라 말하기(줄을 눌러 반복 듣기, 채점 없음) ③ 확인 문제.
class CurriculumPracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  const CurriculumPracticeScreen({super.key, required this.dialogue});
  @override
  State<CurriculumPracticeScreen> createState() => _CurriculumPracticeScreenState();
}

class _CurriculumPracticeScreenState extends State<CurriculumPracticeScreen> {
  bool _showKo = true;
  int? _playing;
  bool _stop = false;

  Dialogue get d => widget.dialogue;

  @override
  void dispose() {
    _stop = true;
    DialogueAudio.instance.stop();
    super.dispose();
  }

  Future<void> _playAll() async {
    _stop = false;
    for (final t in d.turns) {
      if (_stop || !mounted) break;
      setState(() => _playing = t.num);
      await speakTurn(d, d.view(t));
    }
    if (mounted) setState(() => _playing = null);
  }

  Future<void> _playOne(int i) async {
    _stop = true;
    await DialogueAudio.instance.stop();
    _stop = false;
    final t = d.turns[i];
    setState(() => _playing = t.num);
    await speakTurn(d, d.view(t));
    if (mounted && _playing == t.num) setState(() => _playing = null);
  }

  Future<void> _quiz() async {
    _stop = true;
    await DialogueAudio.instance.stop();
    final svc = CurriculumService.instance;
    final qs = buildQuestions(d, limit: 10, pool: DialogueService.instance.list(region: d.region), seed: DateTime.now().millisecondsSinceEpoch);
    if (!mounted) return;
    final res = await openFull<QuizResult>(context, (_) => CurriculumQuizScreen(title: d.title, questions: qs, mode: QuizMode.practice));
    if (res == null || !mounted) return;
    svc.state.markPracticed(d.id, d.turns.map((t) => t.num), svc.today);
    await svc.save();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('${d.emoji} ${d.title}', style: const TextStyle(color: AppColors.khram, fontWeight: FontWeight.w800, fontSize: 15)),
        actions: [
          TextButton(onPressed: () => setState(() => _showKo = !_showKo), child: Text(_showKo ? tr('뜻 숨기기') : tr('뜻 보기'))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (d.sceneShown.isNotEmpty) Text(d.sceneShown, style: const TextStyle(fontSize: 12.5, color: AppColors.khramLight)),
          const SizedBox(height: 4),
          Text(tr('① 전체 듣기 ② 줄을 눌러 따라 말하기 ③ 확인 문제'), style: const TextStyle(fontSize: 12, color: AppColors.khramLight, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (var i = 0; i < d.turns.length; i++)
            Builder(builder: (_) {
              final t = d.view(d.turns[i]);
              final on = _playing == t.num;
              return _card(
                selected: on,
                onTap: () => _playOne(i),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 52,
                    child: Text(d.speakerName(t.speaker), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.kluayMaiDeep)),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(LearnerPrefs.fill(t.th), style: const TextStyle(fontSize: 16, color: AppColors.khram, height: 1.4, fontFamilyFallback: AppTheme.fontFallback)),
                      if (t.rd.isNotEmpty) Text(t.rd, style: const TextStyle(fontSize: 12, color: AppColors.kluayMaiDeep)),
                      if (_showKo && t.ko.isNotEmpty) Text(t.ko, style: const TextStyle(fontSize: 12.5, color: AppColors.khramLight)),
                    ]),
                  ),
                  Icon(on ? Icons.volume_up : Icons.replay, size: 18, color: on ? AppColors.kluayMaiDeep : AppColors.thong),
                ]),
              );
            }),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset(context)),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _playing == null ? _playAll : () async {
                _stop = true;
                await DialogueAudio.instance.stop();
                if (mounted) setState(() => _playing = null);
              },
              icon: Icon(_playing == null ? Icons.play_arrow : Icons.stop),
              label: Text(_playing == null ? tr('전체 듣기') : tr('멈추기')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep),
              onPressed: _quiz,
              icon: const Icon(Icons.quiz, size: 18),
              label: Text(tr('확인 문제')),
            ),
          ),
        ]),
      ),
    );
  }
}

enum QuizMode { practice, review, exam }

class QuizResult {
  final int correct, total;
  final Set<String> wrongDialogues;
  const QuizResult(this.correct, this.total, this.wrongDialogues);
}

/// 확인 문제·복습·코스 시험 공용. 한 문제씩 4지선다, 고르면 바로 정답 표시 → 다음.
/// 연습·복습은 문제마다 간격 반복에 반영, 시험은 점수만(끝에 부르는 쪽이 기록).
class CurriculumQuizScreen extends StatefulWidget {
  final String title;
  final List<CurQuestion> questions;
  final QuizMode mode;
  const CurriculumQuizScreen({super.key, required this.title, required this.questions, required this.mode});
  @override
  State<CurriculumQuizScreen> createState() => _CurriculumQuizScreenState();
}

class _CurriculumQuizScreenState extends State<CurriculumQuizScreen> {
  int _i = 0, _correct = 0;
  int? _chosen;
  final Set<String> _wrong = {};

  List<CurQuestion> get qs => widget.questions;

  Future<void> _choose(int k) async {
    if (_chosen != null) return;
    final q = qs[_i];
    final ok = k == q.answer;
    setState(() {
      _chosen = k;
      if (ok) {
        _correct++;
      } else {
        _wrong.add(q.dialogueId);
      }
    });
    if (widget.mode != QuizMode.exam) {
      final svc = CurriculumService.instance;
      svc.state.grade(q.lineId, ok, svc.today, countReview: widget.mode == QuizMode.review);
      await svc.save();
    }
  }

  void _next() {
    if (_i + 1 >= qs.length) {
      setState(() => _i = qs.length);
      return;
    }
    setState(() {
      _i++;
      _chosen = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _i >= qs.length;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(color: AppColors.khram, fontWeight: FontWeight.w800, fontSize: 15))),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
        child: qs.isEmpty
            ? _end(tr('이 편은 만들 문제가 없어요.'))
            : done
                ? _end(trf('{0}문제 중 {1}개 맞힘 · {2}점', [qs.length, _correct, scorePercent(_correct, qs.length)]))
                : _question(qs[_i]),
      ),
    );
  }

  Widget _end(String msg) => Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.khram)),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: () => Navigator.pop(context, QuizResult(_correct, qs.length, _wrong)),
          child: Text(tr('마침')),
        ),
      ]);

  Widget _question(CurQuestion q) {
    return ListView(children: [
      LinearProgressIndicator(value: _i / qs.length, minHeight: 4, backgroundColor: AppColors.thong, color: AppColors.kluayMaiDeep),
      const SizedBox(height: 8),
      Text('${_i + 1} / ${qs.length}', style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
      const SizedBox(height: 12),
      Text(q.kind == 'blank' ? tr('빈칸에 들어갈 말은?') : tr('뜻으로 맞는 것을 고르세요.'), style: const TextStyle(fontSize: 13, color: AppColors.khramLight, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(q.prompt, style: const TextStyle(fontSize: 20, color: AppColors.khram, height: 1.4, fontWeight: FontWeight.w600, fontFamilyFallback: AppTheme.fontFallback)),
      if (q.hint.isNotEmpty) ...[const SizedBox(height: 4), Text(q.hint, style: const TextStyle(fontSize: 13, color: AppColors.khramLight))],
      const SizedBox(height: 16),
      for (var k = 0; k < q.choices.length; k++)
        _card(
          onTap: _chosen == null ? () => _choose(k) : null,
          selected: _chosen != null && (k == q.answer || k == _chosen),
          child: Row(children: [
            Expanded(child: Text(q.choices[k], style: const TextStyle(fontSize: 15, color: AppColors.khram))),
            if (_chosen != null && k == q.answer) const Icon(Icons.check_circle, color: AppColors.morakot),
            if (_chosen != null && k == _chosen && k != q.answer) const Icon(Icons.cancel, color: AppColors.sunsetDeep),
          ]),
        ),
      if (_chosen != null) ...[
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.khram, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: _next,
          child: Text(_i + 1 >= qs.length ? tr('결과 보기') : tr('다음')),
        ),
      ],
    ]);
  }
}

/// 홈 카드 — 「오늘: 복습 N · 새 편 N」 + 진행 막대 + 연속 일수.
class CurriculumHomeCard extends StatefulWidget {
  const CurriculumHomeCard({super.key});
  @override
  State<CurriculumHomeCard> createState() => _CurriculumHomeCardState();
}

class _CurriculumHomeCardState extends State<CurriculumHomeCard> {
  final _svc = CurriculumService.instance;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _svc.changed.addListener(_refresh);
    _svc.ensureLoaded().then((_) => _refresh());
  }

  @override
  void dispose() {
    _svc.changed.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final st = _svc.state;
    final today = _svc.today;
    final due = _ready ? st.dueReview(today).length : 0;
    final newLeft = _ready ? st.newLeft(today) : 0;
    final doneN = _ready && st.todayDay == today ? st.todayNew + st.todayReview : 0;
    final total = doneN + due + newLeft;
    final streak = _ready ? st.streakShown(today) : 0;
    final sub = !_ready || st.level == null
        ? trf('단계에서 다이얼로그를 골라 연습 · {0}% 넘으면 다음 코스', [CurriculumService.instance.passPercent])
        : st.dayDone(today)
            ? (streak > 0 ? trf('오늘 분량 끝 · 🔥 {0}일 연속', [streak]) : tr('오늘 분량 끝'))
            : trf('오늘: 복습 {0} · 새 편 {1}', [due, newLeft]);
    return _card(
      onTap: () => openPane(context, (_) => const CurriculumScreen()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const GoldEmblem(text: 'เรียน', size: 40, color: AppColors.kluayMaiDeep),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('토크버스 커리큘럼'), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.khram)),
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.khramLight)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.khramLight),
        ]),
        if (_ready && st.level != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: total == 0 ? 1 : doneN / total, minHeight: 5, backgroundColor: AppColors.thong, color: AppColors.kluayMaiDeep),
          ),
        ],
      ]),
    );
  }
}
