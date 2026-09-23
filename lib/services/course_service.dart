import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'content_store.dart';

/// 「내 코스」 — 질문 답으로 미리 써 둔 스크립트에 점수를 매겨 재생 목록을 만든다.
///
/// 런타임에 글을 생성하지 않는다. 난수도 없다 — 같은 답이면 항상 같은 목록·같은 순서.
/// 선택 규칙의 기준 구현은 `drafts/script_engine/select_playlist.py` 이고, 이 파일은 그 이식이다.
class CourseTurn {
  final int num;
  final String speaker; // 'A' = 학습자, 'B' = 상대
  final String th;
  final String roman;
  final String ko;
  final String? note;
  const CourseTurn(this.num, this.speaker, this.th, this.roman, this.ko, this.note);
}

class CourseScript {
  final String id; // key#ep@variant
  final String key;
  final int ep;
  final int seriesLen;
  final String domain;
  final String level; // beg · mid · adv
  final String drive;
  final int heat;
  final String emoji;
  final String title;
  final String hook;
  final String recap;
  final String charA;
  final String charB;
  final List<String> flags;
  final Map<String, String> tags;
  final String variant;
  final String? prev;
  final String? next;
  final Map<String, String> voices; // 'A'/'B' → 'm'/'f'
  final List<CourseTurn> turns;

  CourseScript.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        key = j['key'] as String,
        ep = j['ep'] as int,
        seriesLen = (j['series_len'] as int?) ?? 1,
        domain = j['domain'] as String,
        level = (j['level'] as String?) ?? 'mid',
        drive = j['drive'] as String,
        heat = j['heat'] as int,
        emoji = j['emoji'] as String,
        title = j['title'] as String,
        hook = (j['hook'] as String?) ?? '',
        recap = (j['recap'] as String?) ?? '',
        charA = (j['characters'] as Map)['A'] as String,
        charB = (j['characters'] as Map)['B'] as String,
        flags = [...(j['flags'] as List).cast<String>()],
        tags = (j['tags'] as Map).map((k, v) => MapEntry(k as String, v as String)),
        variant = j['variant'] as String,
        prev = j['prev'] as String?,
        next = j['next'] as String?,
        voices = (j['voices'] as Map).map((k, v) => MapEntry(k as String, v as String)),
        turns = [
          for (final t in (j['turns'] as List).cast<Map<String, dynamic>>())
            CourseTurn(t['num'] as int, t['speaker'] as String, t['th'] as String,
                t['roman'] as String, t['ko'] as String, t['note'] as String?),
        ];

  /// 진행 기록용 id — 성별판을 바꿔도 이어지도록 @판을 뗀다.
  String get progressId => id.split('@').first;
}

class CourseOption {
  final String id;
  final String label;
  final String? sub;
  final String? emoji;
  final Map<String, int> score;
  final int? maxHeat;
  CourseOption.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        label = j['label'] as String,
        sub = j['sub'] as String?,
        emoji = j['emoji'] as String?,
        score = ((j['score'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, v as int)),
        maxHeat = j['max_heat'] as int?;
}

class CourseQuestion {
  final String id;
  final String section;
  final String ask;
  final int multi; // 0 = 하나만, n = n개까지
  final List<CourseOption> options;
  CourseQuestion.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        section = (j['section'] as String?) ?? '',
        ask = j['ask'] as String,
        multi = (j['multi'] as int?) ?? 0,
        options = [
          for (final o in (j['options'] as List).cast<Map<String, dynamic>>()) CourseOption.fromJson(o),
        ];
}

class CourseService {
  CourseService._();
  static final CourseService instance = CourseService._();

  static const _kAnswers = 'course_answers_v1';
  static const _kDone = 'course_done_v1';
  static const _kAnswersAt = 'course_answers_at_v1';
  static const playlistSize = 12;

  List<CourseQuestion> questions = const [];
  List<String> driveOrder = const [];
  Map<String, String> driveLabels = const {};
  List<CourseScript> _all = const [];
  Map<String, dynamic> answers = {};
  DateTime? answersUpdatedAt;
  Set<String> done = {};
  bool _loaded = false;

  bool get hasAnswers => questions.isNotEmpty && questions.every((q) => answers.containsKey(q.id));

  CourseQuestion get domainQuestion => questions.firstWhere((q) => q.id == 'q3_domain');
  List<String> get domains => ((answers['q3_domain'] as List?) ?? const []).cast<String>();
  List<String> get domainLabels =>
      [for (final id in domains) domainQuestion.options.firstWhere((o) => o.id == id).label];

  /// 도메인만 바꾼다(나머지 답은 그대로). 언제든 다시 고를 수 있게.
  Future<void> setDomains(List<String> ids) => saveAnswers({...answers, 'q3_domain': ids});

  CourseQuestion get levelQuestion => questions.firstWhere((q) => q.id == 'q3b_level');
  String? get level => answers['q3b_level'] as String?;
  Future<void> setLevel(String id) => saveAnswers({...answers, 'q3b_level': id});

  /// 고른 레벨과 함께 목록에 드는 레벨 — 이웃 한 칸까지.
  static const nearLevels = {
    'beg': ['beg', 'mid'],
    'mid': ['beg', 'mid', 'adv'],
    'adv': ['mid', 'adv'],
  };

  /// 2026-09-23 무대 개편(6 → 8) 전의 답을 새 무대 id 로 옮긴다.
  static const _oldDomain = {'biz': 'work', 'travel': 'trip', 'stay': 'home', 'fan': 'us', 'chat': 'phone'};
  static Map<String, dynamic> migrate(Map<String, dynamic> a) {
    final d = a['q3_domain'];
    if (d is! List) return a;
    final ids = <String>[];
    for (final x in d.cast<String>()) {
      final n = _oldDomain[x] ?? x;
      if (!ids.contains(n)) ids.add(n);
    }
    return {...a, 'q3_domain': ids};
  }

  int _rev = -1;

  Future<void> ensureLoaded() async {
    // 원격 콘텐츠를 새로 받았으면 다시 읽는다.
    if (_loaded && _rev == ContentStore.instance.revision.value) return;
    _rev = ContentStore.instance.revision.value;
    final cs = ContentStore.instance;
    final q = json.decode(await cs.loadString('assets/data/course/questions.json')) as Map<String, dynamic>;
    final s = json.decode(await cs.loadString('assets/data/course/scripts_th.json')) as Map<String, dynamic>;
    questions = [for (final x in (q['questions'] as List).cast<Map<String, dynamic>>()) CourseQuestion.fromJson(x)];
    driveOrder = [...((q['meta'] as Map)['drive_order'] as List).cast<String>()];
    driveLabels = (q['drives'] as Map).map((k, v) => MapEntry(k as String, (v as Map)['label'] as String));
    _all = [for (final x in (s['scripts'] as List).cast<Map<String, dynamic>>()) CourseScript.fromJson(x)];
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kAnswers);
    if (raw != null) answers = migrate(json.decode(raw) as Map<String, dynamic>);
    done = {...(p.getStringList(_kDone) ?? const [])};
    final at = p.getInt(_kAnswersAt);
    if (at != null) answersUpdatedAt = DateTime.fromMillisecondsSinceEpoch(at);
    _loaded = true;
  }

  /// [touch] = 지금 시각을 갱신 시각으로 기록(서버에서 내려받을 때는 false).
  Future<void> saveAnswers(Map<String, dynamic> a, {bool touch = true}) async {
    a = migrate(a);
    answers = a;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAnswers, json.encode(a));
    if (touch) {
      answersUpdatedAt = DateTime.now();
      await p.setInt(_kAnswersAt, answersUpdatedAt!.millisecondsSinceEpoch);
      onAnswersChanged?.call();
    }
  }

  /// 로그인 상태면 AuthService 가 여기에 서버 반영 훅을 건다.
  void Function()? onAnswersChanged;
  void Function(String scriptKey)? onDone;

  Future<void> markDone(CourseScript s) async {
    done.add(s.progressId);
    (await SharedPreferences.getInstance()).setStringList(_kDone, done.toList());
    onDone?.call(s.progressId);
  }

  Future<void> mergeDone(Set<String> keys) async {
    done.addAll(keys);
    (await SharedPreferences.getInstance()).setStringList(_kDone, done.toList());
  }

  bool isDone(CourseScript s) => done.contains(s.progressId);
  bool isUnlocked(CourseScript s) => s.prev == null || done.contains(s.prev!.split('@').first);
  CourseScript? byId(String? id) {
    if (id == null) return null;
    for (final s in _all) {
      if (s.id == id) return s;
    }
    return null;
  }

  String _one(String qid) => answers[qid] as String;
  CourseOption _opt(String qid) => questions.firstWhere((q) => q.id == qid).options.firstWhere((o) => o.id == _one(qid));

  /// 욕구 점수 (q4 +2, q5·q6 +1).
  Map<String, int> driveScores() {
    final sc = {for (final d in driveOrder) d: 0};
    for (final qid in const ['q4_moment', 'q5_scene', 'q6_friend']) {
      _opt(qid).score.forEach((d, v) => sc[d] = (sc[d] ?? 0) + v);
    }
    return sc;
  }

  /// 가장 센 욕구 — 동점이면 q4 에서 고른 쪽, 그래도 같으면 drive_order 앞쪽.
  String topDrive() {
    final sc = driveScores();
    final best = sc.values.reduce((a, b) => a > b ? a : b);
    final q4 = _opt('q4_moment').score.keys.first;
    if (sc[q4] == best) return q4;
    return driveOrder.firstWhere((d) => sc[d] == best);
  }

  /// 점수순 재생 목록. 이어지는 회차는 1편 바로 뒤에 붙는다.
  List<(int, CourseScript)> playlist() {
    if (!hasAnswers) return const [];
    final me = _one('q1_me');
    var pt = _one('q2_partner');
    if (pt == 'any') pt = me == 'm' ? 'f' : 'm';
    final domains = (answers['q3_domain'] as List).cast<String>();
    final lv = _one('q3b_level');
    final near = nearLevels[lv] ?? const ['beg', 'mid', 'adv'];
    final ds = driveScores();
    final maxHeat = _opt('q13_heat').maxHeat ?? 3;
    final noAlcohol = _one('q12_alcohol') == 'no';
    bool blocked(CourseScript s) => s.heat > maxHeat || (noAlcohol && s.flags.contains('alcohol'));
    int tag(CourseScript s, String k, String qid, int pts) => s.tags[k] == _one(qid) ? pts : 0;

    final scored = <(int, CourseScript)>[];
    for (final s in _all) {
      if (s.variant != me && s.variant != '$me$pt') continue;
      if (!domains.contains(s.domain)) continue; // 고른 무대만 — 점수가 아니라 필터
      if (!near.contains(s.level)) continue; // 고른 레벨과 이웃 레벨까지만
      if (s.ep != 1 || blocked(s)) continue;
      final pts = (ds[s.drive] ?? 0) +
          (s.level == lv ? 3 : 0) +
          tag(s, 'stage', 'q7_stage', 2) +
          tag(s, 'style', 'q8_style', 1) +
          tag(s, 'persona', 'q9_persona', 1) +
          tag(s, 'conflict', 'q10_conflict', 2) +
          tag(s, 'reg', 'q11_reg', 1);
      scored.add((pts, s));
    }
    scored.sort((a, b) => a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2.id.compareTo(b.$2.id));
    final out = <(int, CourseScript)>[];
    for (final (pts, s) in scored.take(playlistSize)) {
      out.add((pts, s));
      var n = byId(s.next);
      while (n != null && !blocked(n)) {
        out.add((pts, n));
        n = byId(n.next);
      }
    }
    return out;
  }
}
