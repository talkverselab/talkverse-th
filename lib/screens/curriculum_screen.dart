import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_audio.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../widgets/thai_decor.dart';

/// 토크버스 커리큘럼(전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`, 2026-11-22).
/// 레벨 고르기 → 다이얼로그 골라 코스 → 편마다 듣기·확인 문제 → 복습(1·3·7일) → 코스 시험 80% 이상 통과.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

const _goalLabels = {1: '가볍게', 2: '보통', 3: '집중'};

class _CurriculumScreenState extends State<CurriculumScreen> {
  bool _loading = true;
  bool _pickLevel = false;
  bool _confirmNew = false;
  final _svc = CurriculumService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DialogueService.instance.ensureLoaded();
    await _svc.ensureLoaded();
    if (mounted) setState(() => _loading = false);
  }

  CurriculumState get _s => _svc.state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(tr('토크버스 커리큘럼'), style: const TextStyle(color: AppColors.khram, fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.kluayMai))
          : (_s.level == null || _pickLevel)
              ? _levelPicker()
              : _main(),
    );
  }

  // ── 레벨 고르기 ──
  Widget _levelPicker() {
    final levels = _svc.availableLevels();
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        Text(tr('회화 레벨을 고르세요'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.khram)),
        const SizedBox(height: 4),
        Text(tr('처음이면 가장 낮은 레벨부터 권합니다.'), style: const TextStyle(fontSize: 13, color: AppColors.khramLight)),
        const SizedBox(height: 14),
        for (final (i, lv) in levels.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _card(
              onTap: () async {
                await _svc.setLevel(lv);
                setState(() => _pickLevel = false);
              },
              child: Row(children: [
                GoldEmblem(text: lv, size: 40, color: AppColors.badges[i % AppColors.badges.length]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr(DialogueService.levelKo[lv] ?? lv), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.khram)),
                    Text(trf('{0}편 · 통과 {1}편', [DialogueService.instance.count(lv), _passedIn(lv)]),
                        style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
                  ]),
                ),
                if (i == 0 && _s.level == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.kluayMaiLight, borderRadius: BorderRadius.circular(10)),
                    child: Text(tr('추천'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.kluayMaiDeep)),
                  ),
                if (lv == _s.level) const Icon(Icons.check_circle, color: AppColors.morakot),
              ]),
            ),
          ),
      ],
    );
  }

  int _passedIn(String lv) => DialogueService.instance.list(region: lv).where((d) => _s.passedDialogues.contains(d.id)).length;

  // ── 메인 ──
  Widget _main() {
    final today = _svc.today;
    _s.rollDay(today);
    final due = _s.dueOn(today).length;
    final newLeft = _s.newLeftToday();
    final doneCount = _s.todayReviewDone + _s.todayNew.length;
    final totalCount = doneCount + due + newLeft;
    final c = _s.course;
    final lv = _s.level!;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)),
      children: [
        Row(children: [
          ActionChip(
            avatar: const Icon(Icons.swap_vert, size: 16, color: AppColors.kluayMaiDeep),
            label: Text('$lv · ${tr(DialogueService.levelKo[lv] ?? lv)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram)),
            onPressed: () => setState(() => _pickLevel = true),
          ),
          const Spacer(),
          Text(trf('통과 {0}/{1}편', [_passedIn(lv), DialogueService.instance.count(lv)]), style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
        ]),
        const SizedBox(height: 10),
        // 오늘 분량
        _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text(tr('오늘 분량'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.khram)),
              const Spacer(),
              if (_s.streakCount > 0) Text(trf('🔥 연속 {0}일', [_s.streakCount]), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sunsetDeep)),
            ]),
            const SizedBox(height: 6),
            Text(_s.dailyDone(today) ? tr('오늘 분량 끝 🎉') : trf('오늘: 복습 {0} · 새 편 {1}', [due, newLeft]),
                style: const TextStyle(fontSize: 13, color: AppColors.khramLight)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: totalCount == 0 ? 1 : doneCount / totalCount,
                minHeight: 8,
                backgroundColor: AppColors.creamDeep,
                color: AppColors.morakot,
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Text(tr('하루 목표'), style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
              const SizedBox(width: 8),
              for (final g in const [1, 2, 3])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(trf('{0} · 새 편 {1}', [tr(_goalLabels[g]!), g]), style: const TextStyle(fontSize: 11)),
                    selected: _s.dailyGoal == g,
                    selectedColor: AppColors.kluayMaiLight,
                    onSelected: (_) async {
                      await _svc.setDailyGoal(g);
                      setState(() {});
                    },
                  ),
                ),
            ]),
            if (due > 0) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('curr-review'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.morakot),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _ReviewScreen()));
                  setState(() {});
                },
                icon: const Icon(Icons.sync_rounded),
                label: Text(trf('복습 {0}개 하기', [due])),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        if (_confirmNew) _confirmPanel() else ..._courseSection(c),
      ],
    );
  }

  List<Widget> _courseSection(CurriculumCourse? c) {
    if (c == null || c.passed) {
      return [
        if (c != null && c.passed)
          _card(child: Text(trf('지난 코스 통과 · {0}%', [c.examScores.isEmpty ? 0 : c.examScores.last]), style: const TextStyle(color: AppColors.morakot, fontWeight: FontWeight.w800))),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const ValueKey('curr-new-course'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: _newCourse,
          icon: const Icon(Icons.playlist_add),
          label: Text(tr('새 코스 만들기')),
        ),
      ];
    }
    final dialogues = [for (final id in c.dialogueIds) ?DialogueService.instance.byId(id)];
    final next = dialogues.where((d) => !c.practiced.contains(d.id)).firstOrNull;
    return [
      Row(children: [
        Text(trf('지금 코스 · {0}편', [dialogues.length]), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.khram)),
        const Spacer(),
        TextButton(onPressed: () => setState(() => _confirmNew = true), child: Text(tr('새 코스'))),
      ]),
      for (final d in dialogues)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _card(
            onTap: () => _practice(d),
            child: Row(children: [
              Text(d.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.khram))),
              Icon(c.practiced.contains(d.id) ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: c.practiced.contains(d.id) ? AppColors.morakot : AppColors.thong),
            ]),
          ),
        ),
      const SizedBox(height: 6),
      if (next != null)
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: () => _practice(next),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(trf('다음 편 연습 · {0}', [next.title]), maxLines: 1, overflow: TextOverflow.ellipsis),
        )
      else
        FilledButton.icon(
          key: const ValueKey('curr-exam'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetDeep, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _ExamScreen()));
            setState(() {});
          },
          icon: const Icon(Icons.emoji_events_outlined),
          label: Text(tr('코스 시험 보기 (80% 이상 통과)')),
        ),
      if (c.examScores.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(trf('지난 시험 {0}% — 틀린 편을 다시 연습한 뒤 시험을 다시 봅니다.', [c.examScores.last]),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.sunsetDeep)),
        ),
    ];
  }

  Widget _confirmPanel() => _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr('지금 코스를 그만두고 새 코스를 만들까요?'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram)),
          const SizedBox(height: 4),
          Text(tr('연습 기록과 복습 대기열은 그대로 남습니다.'), style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _confirmNew = false), child: Text(tr('계속하기')))),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetDeep),
                onPressed: () {
                  setState(() => _confirmNew = false);
                  _newCourse();
                },
                child: Text(tr('새 코스 만들기')),
              ),
            ),
          ]),
        ]),
      );

  Future<void> _newCourse() async {
    final ids = await Navigator.of(context).push<List<String>>(MaterialPageRoute(builder: (_) => _CoursePickScreen(level: _s.level!)));
    if (ids == null || ids.isEmpty) return;
    await _svc.startCourse(ids);
    setState(() {});
  }

  Future<void> _practice(Dialogue d) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PracticeScreen(dialogue: d)));
    setState(() {});
  }
}

Widget _card({required Widget child, VoidCallback? onTap}) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.thong)),
          child: child,
        ),
      ),
    );

// ── 코스 고르기 ──
class _CoursePickScreen extends StatefulWidget {
  final String level;
  const _CoursePickScreen({required this.level});
  @override
  State<_CoursePickScreen> createState() => _CoursePickScreenState();
}

class _CoursePickScreenState extends State<_CoursePickScreen> {
  int _size = 5;
  final List<String> _picked = [];

  @override
  Widget build(BuildContext context) {
    final list = DialogueService.instance.list(region: widget.level);
    final passed = CurriculumService.instance.state.passedDialogues.toSet();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(tr('다이얼로그 고르기'), style: const TextStyle(color: AppColors.khram, fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(children: [
            Text(tr('개수'), style: const TextStyle(fontSize: 13, color: AppColors.khramLight)),
            const SizedBox(width: 8),
            for (final n in const [3, 5, 10])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('$n'),
                  selected: _size == n,
                  selectedColor: AppColors.kluayMaiLight,
                  onSelected: (_) => setState(() {
                    _size = n;
                    if (_picked.length > n) _picked.removeRange(n, _picked.length);
                  }),
                ),
              ),
            const Spacer(),
            TextButton.icon(
              key: const ValueKey('curr-recommend'),
              onPressed: () => setState(() {
                final r = recommend(list, passed, _size, keep: _picked);
                _picked
                  ..clear()
                  ..addAll(r);
              }),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(tr('추천으로 채우기')),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final d = list[i];
              final on = _picked.contains(d.id);
              return CheckboxListTile(
                value: on,
                activeColor: AppColors.kluayMaiDeep,
                onChanged: (v) => setState(() {
                  if (on) {
                    _picked.remove(d.id);
                  } else if (_picked.length < _size) {
                    _picked.add(d.id);
                  }
                }),
                secondary: Text(d.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(d.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.khram)),
                subtitle: Text(
                  '${tr(DialogueService.islandKo[d.island] ?? d.island)}${passed.contains(d.id) ? ' · ${tr('통과')} ✓' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.khramLight),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('curr-start'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep, padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: _picked.length == _size || (_picked.isNotEmpty && _picked.length == list.length) ? () => Navigator.of(context).pop([..._picked]) : null,
              child: Text(trf('코스 시작 · {0}/{1}', [_picked.length, _size])),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── 편 연습: 듣기·읽기 → 확인 문제 ──
class _PracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  const _PracticeScreen({required this.dialogue});
  @override
  State<_PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<_PracticeScreen> {
  bool _showKo = true;
  bool _quiz = false;
  int? _playing;
  bool _stop = false;
  List<CurriculumQuestion>? _qs;

  Dialogue get d => widget.dialogue;

  @override
  void dispose() {
    _stop = true;
    DialogueAudio.instance.stop();
    super.dispose();
  }

  Future<void> _play(DialogueTurn t, {int times = 1}) async {
    _stop = false;
    for (var i = 0; i < times && !_stop; i++) {
      if (mounted) setState(() => _playing = t.num);
      await speakTurn(d, t);
    }
    if (mounted) setState(() => _playing = null);
  }

  Future<void> _playAll() async {
    _stop = false;
    for (final t in d.turns) {
      if (_stop || !mounted) break;
      setState(() => _playing = t.num);
      await speakTurn(d, t);
    }
    if (mounted) setState(() => _playing = null);
  }

  Future<void> _halt() async {
    _stop = true;
    await DialogueAudio.instance.stop();
    if (mounted) setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(d.title, style: const TextStyle(color: AppColors.khram, fontSize: 15, fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
      ),
      body: _quiz
          ? _QuizView(
              questions: _qs ??= CurriculumService.instance.practiceQuestions(d),
              onDone: (results) async {
                await CurriculumService.instance.finishPractice(d, [for (final r in results) if (!r.$2) r.$1.lineId]);
              },
              doneLabel: tr('코스로 돌아가기'),
            )
          : _listen(),
    );
  }

  Widget _listen() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(children: [
          Text(tr('① 듣기·읽기'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.khram)),
          const Spacer(),
          TextButton(onPressed: () => setState(() => _showKo = !_showKo), child: Text(_showKo ? tr('뜻 숨기기') : tr('뜻 보기'))),
          IconButton(
            tooltip: tr('전체 재생'),
            onPressed: _playing == null ? _playAll : _halt,
            icon: Icon(_playing == null ? Icons.play_circle_fill : Icons.stop_circle, color: AppColors.kluayMaiDeep, size: 30),
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final t in d.turns) _line(t),
            const SizedBox(height: 4),
            Text(tr('② 따라 말하기: 🔁 를 누르면 그 줄을 세 번 들려줍니다.'), style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
            const SizedBox(height: 12),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('curr-quiz'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () async {
              await _halt();
              setState(() => _quiz = true);
            },
            icon: const Icon(Icons.quiz_outlined),
            label: Text(tr('③ 확인 문제')),
          ),
        ),
      ),
    ]);
  }

  Widget _line(DialogueTurn t) {
    final v = d.view(t);
    final on = _playing == t.num;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: t.speaker == 'A' ? AppColors.bubbleA : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: on ? AppColors.kluayMai : AppColors.thong, width: on ? 2 : 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.speakerName(t.speaker), style: const TextStyle(fontSize: 11, color: AppColors.khramLight, fontWeight: FontWeight.w700)),
            Text(LearnerPrefs.fill(v.th), style: const TextStyle(fontSize: 17, color: AppColors.khram, fontFamilyFallback: AppTheme.fontFallback)),
            if (v.rd.isNotEmpty) Text(v.rd, style: const TextStyle(fontSize: 12, color: AppColors.kluayMaiDeep)),
            if (_showKo) Text(LearnerPrefs.fill(v.ko, ko: true), style: const TextStyle(fontSize: 13, color: AppColors.khramLight)),
          ]),
        ),
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => _play(t), icon: const Icon(Icons.volume_up_rounded, color: AppColors.kluayMaiDeep)),
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => _play(t, times: 3), icon: const Text('🔁')),
      ]),
    );
  }
}

// ── 코스 시험 ──
class _ExamScreen extends StatefulWidget {
  const _ExamScreen();
  @override
  State<_ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<_ExamScreen> {
  late final _qs = CurriculumService.instance.examQuestions();
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(tr('코스 시험'), style: const TextStyle(color: AppColors.khram, fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
      ),
      body: _QuizView(
        questions: _qs,
        resultNote: () => _result,
        onDone: (results) async {
          final svc = CurriculumService.instance;
          final correct = results.where((r) => r.$2).length;
          final wrong = {for (final r in results) if (!r.$2) r.$1.dialogueId};
          final pass = await svc.finishExam(correct, results.length, wrong);
          final lu = svc.levelUp;
          _result = pass
              ? (lu != null ? trf('통과! 이 레벨을 모두 마쳐 {0} 레벨이 열렸습니다.', [lu]) : tr('통과! 다음 코스를 만들어 보세요.'))
              : trf('80% 미만입니다. 틀린 편 {0}개를 다시 연습한 뒤 시험을 다시 봅니다.', [wrong.length]);
        },
        doneLabel: tr('코스로 돌아가기'),
      ),
    );
  }
}

// ── 복습 ──
class _ReviewScreen extends StatefulWidget {
  const _ReviewScreen();
  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  final svc = CurriculumService.instance;
  late final _qs = svc.reviewQuestions();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(tr('오늘 복습'), style: const TextStyle(color: AppColors.khram, fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.khram,
        elevation: 0,
      ),
      body: _QuizView(
        questions: _qs,
        onAnswer: (q, ok) => svc.answerReview(q.lineId, ok),
        onDone: (_) async {},
        doneLabel: tr('돌아가기'),
      ),
    );
  }
}

// ── 뜻 고르기 4지선다 ──
class _QuizView extends StatefulWidget {
  final List<CurriculumQuestion> questions;
  final Future<void> Function(List<(CurriculumQuestion, bool)> results) onDone;
  final Future<void> Function(CurriculumQuestion q, bool ok)? onAnswer;
  final String? Function()? resultNote;
  final String doneLabel;
  const _QuizView({required this.questions, required this.onDone, required this.doneLabel, this.onAnswer, this.resultNote});
  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  int _i = 0;
  int? _chosen;
  bool _finished = false;
  final List<(CurriculumQuestion, bool)> _results = [];

  @override
  void initState() {
    super.initState();
    if (widget.questions.isEmpty) _finish();
  }

  Future<void> _finish() async {
    await widget.onDone(_results);
    if (mounted) setState(() => _finished = true);
  }

  Future<void> _choose(int k) async {
    if (_chosen != null) return;
    final q = widget.questions[_i];
    final ok = k == q.answer;
    setState(() => _chosen = k);
    _results.add((q, ok));
    await widget.onAnswer?.call(q, ok);
  }

  void _next() {
    if (_i + 1 >= widget.questions.length) {
      _finish();
      return;
    }
    setState(() {
      _i++;
      _chosen = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      final correct = _results.where((r) => r.$2).length;
      final note = widget.resultNote?.call();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_results.isNotEmpty) ...[
              Text('${scorePercent(correct, _results.length)}%', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.kluayMaiDeep)),
              Text(trf('{0}문제 중 {1}개 맞힘', [_results.length, correct]), style: const TextStyle(color: AppColors.khramLight)),
            ] else
              Text(tr('지금 풀 문제가 없습니다.'), style: const TextStyle(color: AppColors.khramLight)),
            if (note != null) ...[
              const SizedBox(height: 12),
              Text(note, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.khram)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('curr-done'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.doneLabel),
            ),
          ]),
        ),
      );
    }
    if (widget.questions.isEmpty) return const Center(child: CircularProgressIndicator(color: AppColors.kluayMai));
    final q = widget.questions[_i];
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        LinearProgressIndicator(value: (_i + 1) / widget.questions.length, color: AppColors.kluayMai, backgroundColor: AppColors.creamDeep),
        const SizedBox(height: 6),
        Text('${_i + 1} / ${widget.questions.length} · ${tr('뜻 고르기')}', style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
        const SizedBox(height: 14),
        _card(
          child: Column(children: [
            Text(q.th, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: AppColors.khram, fontFamilyFallback: AppTheme.fontFallback)),
            if (q.rd.isNotEmpty) Text(q.rd, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.kluayMaiDeep)),
          ]),
        ),
        const SizedBox(height: 14),
        for (final (k, o) in q.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              key: ValueKey('curr-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _chosen == null
                    ? Colors.white
                    : k == q.answer
                        ? const Color(0xFFDDEFE2)
                        : (k == _chosen ? const Color(0xFFF6D9D2) : Colors.white),
                side: BorderSide(color: AppColors.thong),
              ),
              onPressed: () => _choose(k),
              child: Text(o, style: const TextStyle(color: AppColors.khram, fontSize: 14)),
            ),
          ),
        if (_chosen != null)
          FilledButton(
            key: const ValueKey('curr-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMaiDeep),
            onPressed: _next,
            child: Text(_i + 1 >= widget.questions.length ? tr('결과 보기') : tr('다음')),
          ),
      ],
    );
  }
}

/// 홈 카드 — 「오늘: 복습 N · 새 편 N」 + 진행 막대 + 연속 일수.
class CurriculumHomeCard extends StatefulWidget {
  final VoidCallback onTap;
  const CurriculumHomeCard({super.key, required this.onTap});
  @override
  State<CurriculumHomeCard> createState() => _CurriculumHomeCardState();
}

class _CurriculumHomeCardState extends State<CurriculumHomeCard> {
  final _svc = CurriculumService.instance;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _svc.ensureLoaded().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _svc.revision,
      builder: (_, _, _) {
        final s = _svc.state;
        final today = _svc.today;
        if (_ready) s.rollDay(today);
        final due = _ready ? s.dueOn(today).length : 0;
        final newLeft = _ready ? s.newLeftToday() : 0;
        final done = s.todayReviewDone + s.todayNew.length;
        final total = done + due + newLeft;
        final line = !_ready || s.level == null
            ? tr('레벨을 고르고 다이얼로그로 코스를 시작하세요')
            : s.dailyDone(today)
                ? (s.streakCount > 0 ? trf('오늘 분량 끝 🎉 · 연속 {0}일', [s.streakCount]) : tr('오늘 분량 끝 🎉'))
                : trf('오늘: 복습 {0} · 새 편 {1}', [due, newLeft]);
        return InkWell(
          key: const ValueKey('curriculum-card'),
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.thong),
              boxShadow: const [BoxShadow(color: Color(0x1A5A3E28), blurRadius: 5, offset: Offset(0, 2), spreadRadius: -1)],
            ),
            child: Row(children: [
              GoldEmblem(text: 'เรียน', size: 40, color: AppColors.badges[1]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('토크버스 커리큘럼'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.khram)),
                  const SizedBox(height: 2),
                  Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
                  if (_ready && s.level != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: total == 0 ? 1 : done / total, minHeight: 5, backgroundColor: AppColors.creamDeep, color: AppColors.morakot),
                    ),
                  ],
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppColors.khramLight),
            ]),
          ),
        );
      },
    );
  }
}
