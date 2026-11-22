import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/prefs.dart';
import '../services/learner_prefs.dart';
import 'dialogue_service.dart';

/// 토크버스 커리큘럼 — 전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`(2026-11-22).
/// 회화 레벨에서 다이얼로그를 골라 코스 → 편마다 듣기·확인 문제 → 틀린 줄 간격 반복(1·3·7일)
/// → 코스 시험 80% 이상이면 통과. 하루 목표(새 편 1·2·3 + 복습). 기기 저장 키 `curriculum_v1`.

/// 날짜 문자열 yyyy-MM-dd (기기 시간 기준).
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseDay(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String addDays(String day, int n) {
  final d = _parseDay(day);
  return dayKey(DateTime(d.year, d.month, d.day + n));
}

/// 점수 = 정답 수 / 문제 수, 소수점 버림(%).
int scorePercent(int correct, int total) => total <= 0 ? 0 : (correct * 100) ~/ total;

/// 80% 이상 = 통과.
bool isPass(int correct, int total) => scorePercent(correct, total) >= 80;

/// 간격 반복 단계별 간격(일). 맞히면 다음 간격, 세 번째(7일)까지 맞히면 졸업, 틀리면 1일로.
const reviewIntervals = [1, 3, 7];

class ReviewItem {
  final String lineId; // 「편id#턴번호」
  String due; // yyyy-MM-dd
  int step; // 다음 복습에서 맞히면 쓰는 간격 위치
  ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map<String, dynamic> j) =>
      ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

class CurriculumCourse {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  String? passedAt;
  CurriculumCourse({required this.id, required this.dialogueIds, List<String>? practiced, List<int>? examScores, this.passedAt})
      : practiced = practiced ?? [],
        examScores = examScores ?? [];
  bool get allPracticed => dialogueIds.every(practiced.contains);
  bool get passed => passedAt != null;
  Map<String, dynamic> toJson() =>
      {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory CurriculumCourse.fromJson(Map<String, dynamic> j) => CurriculumCourse(
        id: '${j['id']}',
        dialogueIds: [for (final e in (j['dialogueIds'] as List? ?? const [])) '$e'],
        practiced: [for (final e in (j['practiced'] as List? ?? const [])) '$e'],
        examScores: [for (final e in (j['examScores'] as List? ?? const [])) (e as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
}

/// 저장 형식(전 언어 같음): {level, dailyGoal, course, passedDialogues[], review[], streak{count,lastDay}}
/// + today{day, newIds[], reviewDone} — 하루 분량 집계용(기기 전용 보조 칸).
class CurriculumState {
  String? level;
  int dailyGoal; // 새 편 수 1·2·3
  CurriculumCourse? course;
  final List<String> passedDialogues;
  final List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  String todayDay;
  final List<String> todayNew;
  int todayReviewDone;

  CurriculumState({
    this.level,
    this.dailyGoal = 2,
    this.course,
    List<String>? passedDialogues,
    List<ReviewItem>? review,
    this.streakCount = 0,
    this.streakLastDay,
    this.todayDay = '',
    List<String>? todayNew,
    this.todayReviewDone = 0,
  })  : passedDialogues = passedDialogues ?? [],
        review = review ?? [],
        todayNew = todayNew ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'newIds': todayNew, 'reviewDone': todayReviewDone},
      };

  factory CurriculumState.fromJson(Map<String, dynamic> j) {
    final s = (j['streak'] as Map?) ?? const {};
    final t = (j['today'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: ((j['dailyGoal'] as num?)?.toInt() ?? 2).clamp(1, 3),
      course: j['course'] is Map ? CurriculumCourse.fromJson((j['course'] as Map).cast<String, dynamic>()) : null,
      passedDialogues: [for (final e in (j['passedDialogues'] as List? ?? const [])) '$e'],
      review: [
        for (final e in (j['review'] as List? ?? const []))
          if (e is Map) ReviewItem.fromJson(e.cast<String, dynamic>())
      ],
      streakCount: (s['count'] as num?)?.toInt() ?? 0,
      streakLastDay: s['lastDay'] as String?,
      todayDay: '${t['day'] ?? ''}',
      todayNew: [for (final e in (t['newIds'] as List? ?? const [])) '$e'],
      todayReviewDone: (t['reviewDone'] as num?)?.toInt() ?? 0,
    );
  }

  /// 날이 바뀌었으면 오늘 집계를 비운다.
  void rollDay(String today) {
    if (todayDay == today) return;
    todayDay = today;
    todayNew.clear();
    todayReviewDone = 0;
  }

  List<ReviewItem> dueOn(String today) => review.where((r) => r.due.compareTo(today) <= 0).toList();

  /// 줄을 복습 대기열에 넣는다(이미 있으면 1일로 되돌림).
  void enqueue(String lineId, String today) {
    final i = review.indexWhere((r) => r.lineId == lineId);
    if (i >= 0) {
      review[i]
        ..step = 0
        ..due = addDays(today, reviewIntervals[0]);
    } else {
      review.add(ReviewItem(lineId, addDays(today, reviewIntervals[0]), 0));
    }
  }

  /// 연습한 편의 줄 — 대기열에 없을 때만 넣는다(이미 있는 간격은 건드리지 않음).
  void enqueueIfAbsent(String lineId, String today) {
    if (review.any((r) => r.lineId == lineId)) return;
    review.add(ReviewItem(lineId, addDays(today, reviewIntervals[0]), 0));
  }

  /// 복습 답: 맞히면 다음 간격(1→3→7일, 7일 뒤 맞히면 졸업), 틀리면 1일로.
  void answerReview(String lineId, bool correct, String today) {
    final i = review.indexWhere((r) => r.lineId == lineId);
    if (i < 0) return;
    final r = review[i];
    if (!correct) {
      r
        ..step = 0
        ..due = addDays(today, reviewIntervals[0]);
      return;
    }
    final next = r.step + 1;
    if (next >= reviewIntervals.length) {
      review.removeAt(i);
    } else {
      r
        ..step = next
        ..due = addDays(today, reviewIntervals[next]);
    }
  }

  int newLeftToday() => max(0, dailyGoal - todayNew.length);

  /// 오늘 분량 끝 = 복습 대기 0 + 새 편 목표 채움.
  bool dailyDone(String today) => dueOn(today).isEmpty && newLeftToday() == 0;

  /// 오늘 분량을 다 했으면 연속 일수를 올린다(하루 한 번).
  void touchStreak(String today) {
    if (!dailyDone(today) || streakLastDay == today) return;
    streakCount = (streakLastDay != null && addDays(streakLastDay!, 1) == today) ? streakCount + 1 : 1;
    streakLastDay = today;
  }
}

/// 확인 문제 — 태국어 줄을 보고 뜻 고르기(4지선다).
class CurriculumQuestion {
  final String lineId;
  final String dialogueId;
  final String th;
  final String rd;
  final List<String> options;
  final int answer;
  const CurriculumQuestion({required this.lineId, required this.dialogueId, required this.th, required this.rd, required this.options, required this.answer});
}

/// 문제를 만들 줄(뜻·본문이 있는 턴).
class QuizLine {
  final String lineId, dialogueId, th, rd, ko;
  const QuizLine(this.lineId, this.dialogueId, this.th, this.rd, this.ko);
}

/// 줄 목록에서 뜻 고르기 문제를 만든다. 오답 보기는 [pool] 의 다른 뜻에서.
List<CurriculumQuestion> buildQuestions(List<QuizLine> lines, List<String> pool, {int limit = 10, Random? rnd}) {
  final r = rnd ?? Random();
  final pick = [...lines]..shuffle(r);
  final out = <CurriculumQuestion>[];
  for (final l in pick.take(limit)) {
    final others = pool.where((k) => k.isNotEmpty && k != l.ko).toSet().toList()..shuffle(r);
    if (others.length < 3) continue;
    final opts = [l.ko, ...others.take(3)]..shuffle(r);
    out.add(CurriculumQuestion(lineId: l.lineId, dialogueId: l.dialogueId, th: l.th, rd: l.rd, options: opts, answer: opts.indexOf(l.ko)));
  }
  return out;
}

/// 코스 시험 편당 문제 수: 편당 최소 3, 전체 최대 30.
int examPerDialogue(int dialogues) => dialogues <= 0 ? 0 : max(3, 30 ~/ dialogues);

/// 추천으로 채우기 — 아직 통과 안 한 편에서 주제가 겹치지 않게 먼저 고르고, 모자라면 남은 편.
List<String> recommend(List<Dialogue> list, Set<String> passed, int n, {List<String> keep = const []}) {
  final out = [...keep];
  final usedIsland = {for (final d in list) if (keep.contains(d.id)) d.island};
  final fresh = list.where((d) => !passed.contains(d.id) && !out.contains(d.id)).toList();
  for (final d in fresh) {
    if (out.length >= n) break;
    if (usedIsland.add(d.island)) out.add(d.id);
  }
  for (final d in fresh) {
    if (out.length >= n) break;
    if (!out.contains(d.id)) out.add(d.id);
  }
  return out.take(n).toList();
}

class CurriculumService {
  CurriculumService._();
  static final CurriculumService instance = CurriculumService._();
  static const prefKey = 'curriculum_v1';

  CurriculumState state = CurriculumState();
  final ValueNotifier<int> revision = ValueNotifier(0);
  bool _loaded = false;

  /// 테스트에서 날짜를 고정할 때.
  DateTime Function() clock = DateTime.now;
  String get today => dayKey(clock());

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = (await Prefs.getInstance()).getString(prefKey);
    if (raw != null) {
      try {
        state = CurriculumState.fromJson((json.decode(raw) as Map).cast<String, dynamic>());
      } catch (_) {}
    }
    state.rollDay(today);
    _loaded = true;
  }

  Future<void> save() async {
    state.rollDay(today);
    state.touchStreak(today);
    await (await Prefs.getInstance()).setString(prefKey, json.encode(state.toJson()));
    revision.value++;
  }

  // ── 줄 ──
  static String lineIdOf(Dialogue d, DialogueTurn t) => '${d.id}#${t.num}';

  QuizLine? lineOf(Dialogue d, DialogueTurn t) {
    final v = d.view(t);
    final th = LearnerPrefs.fill(v.th).trim();
    final ko = LearnerPrefs.fill(v.ko, ko: true).trim();
    if (th.isEmpty || ko.isEmpty) return null;
    return QuizLine(lineIdOf(d, t), d.id, th, v.rd, ko);
  }

  List<QuizLine> linesOf(Dialogue d) => [for (final t in d.turns) ?lineOf(d, t)];

  QuizLine? lineById(String lineId) {
    final i = lineId.lastIndexOf('#');
    if (i < 0) return null;
    final d = DialogueService.instance.byId(lineId.substring(0, i));
    final n = int.tryParse(lineId.substring(i + 1));
    if (d == null || n == null) return null;
    for (final t in d.turns) {
      if (t.num == n) return lineOf(d, t);
    }
    return null;
  }

  /// 오답 보기 후보 — 같은 레벨의 뜻들.
  List<String> poolFor(String region) => [
        for (final d in DialogueService.instance.list(region: region))
          for (final l in linesOf(d)) l.ko
      ];

  List<CurriculumQuestion> practiceQuestions(Dialogue d) => buildQuestions(linesOf(d), [...linesOf(d).map((l) => l.ko), ...poolFor(d.region)]);

  List<CurriculumQuestion> examQuestions() {
    final c = state.course;
    if (c == null) return [];
    final per = examPerDialogue(c.dialogueIds.length);
    final out = <CurriculumQuestion>[];
    for (final id in c.dialogueIds) {
      final d = DialogueService.instance.byId(id);
      if (d == null) continue;
      out.addAll(buildQuestions(linesOf(d), [...linesOf(d).map((l) => l.ko), ...poolFor(d.region)], limit: per));
    }
    out.shuffle();
    return out.take(30).toList();
  }

  List<CurriculumQuestion> reviewQuestions({int limit = 20}) {
    final out = <CurriculumQuestion>[];
    for (final r in state.dueOn(today)) {
      if (out.length >= limit) break;
      final l = lineById(r.lineId);
      if (l == null) {
        state.review.remove(r); // 원고에서 사라진 줄
        continue;
      }
      final region = DialogueService.instance.byId(l.dialogueId)?.region ?? state.level ?? 'R1';
      out.addAll(buildQuestions([l], poolFor(region), limit: 1));
    }
    return out;
  }

  // ── 동작 ──
  Future<void> setLevel(String lv) async {
    state.level = lv;
    await save();
  }

  Future<void> setDailyGoal(int n) async {
    state.dailyGoal = n.clamp(1, 3);
    await save();
  }

  Future<void> startCourse(List<String> ids) async {
    state.course = CurriculumCourse(id: 'c${clock().millisecondsSinceEpoch}', dialogueIds: ids);
    await save();
  }

  /// 편 연습 끝: 연습 표시 · 오늘 새 편 집계 · 줄은 복습 대기열, 틀린 줄은 1일로.
  Future<void> finishPractice(Dialogue d, List<String> wrongLineIds) async {
    final c = state.course;
    state.rollDay(today);
    if (c != null && !c.practiced.contains(d.id)) {
      c.practiced.add(d.id);
      if (!state.todayNew.contains(d.id)) state.todayNew.add(d.id);
    }
    for (final l in linesOf(d)) {
      state.enqueueIfAbsent(l.lineId, today);
    }
    for (final w in wrongLineIds) {
      state.enqueue(w, today);
    }
    await save();
  }

  Future<void> answerReview(String lineId, bool correct) async {
    state.rollDay(today);
    state.answerReview(lineId, correct, today);
    state.todayReviewDone++;
    await save();
  }

  /// 시험 결과 기록. 통과면 true. 미달이면 틀린 편은 다시 연습하도록 연습 표시를 지운다.
  /// 통과하고 그 레벨 편을 모두 통과했으면 [levelUp] 에 다음 레벨이 들어간다.
  String? levelUp;
  Future<bool> finishExam(int correct, int total, Set<String> wrongDialogues) async {
    final c = state.course;
    if (c == null) return false;
    final score = scorePercent(correct, total);
    c.examScores.add(score);
    levelUp = null;
    final pass = isPass(correct, total);
    if (pass) {
      c.passedAt = today;
      for (final id in c.dialogueIds) {
        if (!state.passedDialogues.contains(id)) state.passedDialogues.add(id);
      }
      final lv = state.level;
      if (lv != null) {
        final all = DialogueService.instance.list(region: lv).map((d) => d.id);
        if (all.every(state.passedDialogues.contains)) {
          final levels = availableLevels();
          final i = levels.indexOf(lv);
          if (i >= 0 && i + 1 < levels.length) {
            levelUp = levels[i + 1];
            state.level = levelUp;
          }
        }
      }
    } else {
      c.practiced.removeWhere(wrongDialogues.contains);
    }
    await save();
    return pass;
  }

  /// 이 앱에 편이 있는 회화 레벨(R0~R5).
  List<String> availableLevels() => [
        for (final lv in const ['R0', 'R1', 'R2', 'R3', 'R4', 'R5'])
          if (DialogueService.instance.count(lv) > 0) lv
      ];
}
