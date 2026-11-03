import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'learner_prefs.dart';

/// 새 회화(R0~R4, 주제별 JSON) 로더 — 2026-11-03 (일본어앱 이식).
///
/// 파일: `assets/data/dialogues/R<레벨>/<주제>/<편id>.json` (구조는 `docs/DIALOGUE_WORKFLOW_TH.md`).
/// 레벨: R0 왕초보 · R1 초보(기본) · R2 중급 · R3 고급 · R4 최상급 — 절벽 구간 기준.
/// 사용자 레벨 모드(`dialogue_level`): 기본 R1, "너무 힘들면" R0. R2 이상은 주제 목록에서 그대로 열 수 있다.
/// 문장 내용어 한 개: 표면형·기본형(태국어는 어형 변화가 없어 보통 표면형과 같음)·한글 독음. `tools/add_lemmas.py` 가 채운다.
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

class DialogueTurn {
  final int num;
  final String speaker; // A(학습자)·B·C·D
  final String th;
  final String rd; // 한글 독음
  final String ko;
  final String note;
  final List<String> tags;
  final List<String> newWords;
  final String? at; // 채팅 시각
  final String? stamp; // 채팅 스탬프 이모지
  final bool bubble; // 채팅 말풍선 표시
  final String? art; // 장면 그림 URL(나중에 채움)
  final List<Lemma> lemmas; // 문장 내용어(표면형·기본형·독음) — 단어장 연결(2026-11-04)
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.th,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    this.lemmas = const [],
    required this.newWords,
    this.at,
    this.stamp,
    this.bubble = false,
    this.art,
  });
  factory DialogueTurn.fromJson(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        th: j['th'] as String? ?? '',
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        newWords: (j['new'] as List?)?.cast<String>() ?? const [],
        at: j['at'] as String?,
        stamp: j['stamp'] as String?,
        bubble: j['ui'] == 'bubble',
        art: j['art'] as String?,
        lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
      );

  /// 그림 조회용 핵심 단어 후보: new → expr 태그 → 없음.
  List<String> get pictureWords {
    final out = <String>[...newWords];
    for (final t in tags) {
      if (t.startsWith('expr:')) out.add(t.substring(5).replaceAll(RegExp(r'[?!…]'), ''));
    }
    return out;
  }
}

class Dialogue {
  final String id;
  final String region; // R0..R4
  final String island; // survival friends love life travel culture work study
  final String kind; // survival short long chat
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers;
  final String register;
  final int twist;
  final List<String> expressions;
  final List<DialogueTurn> turns;
  final bool draft;
  final String? art; // 편 대표 장면 그림 URL(나중에 채움)
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.kind,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.register,
    required this.twist,
    required this.expressions,
    required this.turns,
    this.draft = false,
    this.art,
  });
  factory Dialogue.fromJson(Map<String, dynamic> j) => Dialogue(
        id: j['id'] as String,
        region: j['region'] as String? ?? 'R1',
        island: j['island'] as String? ?? '',
        kind: j['kind'] as String? ?? 'long',
        title: j['title'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '💬',
        scene: j['scene'] as String? ?? '',
        speakers: ((j['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
        register: j['register'] as String? ?? '',
        twist: j['twist'] as int? ?? 0,
        expressions: (j['expressions'] as List?)?.cast<String>() ?? const [],
        turns: ((j['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromJson(t as Map<String, dynamic>)).toList(),
        draft: j['draft'] == true,
        art: j['art'] as String?,
      );
  bool get isChat => kind == 'chat';

  /// 화자 표시 이름: `{name}`(학습자 자리) → 프로필 이름 또는 「나」, 그 밖의 중괄호는 뗀다.
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 편 순서 키: survival → a → b → c, 번호 순.
  String get orderKey {
    final m = RegExp(r'_([abcs])(\d+)$').firstMatch(id);
    if (m == null) return id;
    const o = {'s': 0, 'a': 1, 'b': 2, 'c': 3};
    return '${o[m.group(1)]}${m.group(2)!.padLeft(2, '0')}';
  }
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '일',
    'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🆘',
    'friends': '🤝',
    'love': '💘',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '🎓',
  };
  static const levels = ['R0', 'R1', 'R2', 'R3', 'R4'];
  static const levelKo = {'R0': '왕초보', 'R1': '초보', 'R2': '중급', 'R3': '고급', 'R4': '최상급'};
  static const _prefLevel = 'dialogue_level';
  static const _prefLast = 'dialogue_last';
  static const _prefDone = 'dialogue_done';
  String? _lastOpened;
  final Set<String> _done = {};

  /// 마지막으로 연 편(홈 「이어서 읽기」).
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await SharedPreferences.getInstance()).setString(_prefLast, id);
  }

  bool isDone(String id) => _done.contains(id);

  /// 끝까지 들은 편 기록. 처음이면 true.
  Future<bool> markDone(String id) async {
    final first = _done.add(id);
    (await SharedPreferences.getInstance()).setStringList(_prefDone, _done.toList());
    return first;
  }

  final Map<String, Dialogue> _byId = {};
  bool _loaded = false;
  String _level = 'R1';

  /// 사용자 레벨 모드(R0 왕초보 / R1 초보). 기본 R1.
  String get level => _level;
  Future<void> setLevel(String lv) async {
    _level = lv;
    (await SharedPreferences.getInstance()).setString(_prefLevel, lv);
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _level = prefs.getString(_prefLevel) ?? 'R1';
    _lastOpened = prefs.getString(_prefLast);
    _done.addAll(prefs.getStringList(_prefDone) ?? const []);
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest.listAssets().where((p) => RegExp(r'^assets/data/dialogues/R[0-4]/[^/]+/[^/]+\.json$').hasMatch(p));
    for (final p in paths) {
      try {
        final d = Dialogue.fromJson(json.decode(await rootBundle.loadString(p)) as Map<String, dynamic>);
        if (d.turns.isNotEmpty) _byId[d.id] = d;
      } catch (_) {}
    }
    _loaded = true;
  }

  Dialogue? byId(String id) => _byId[id];
  List<Dialogue> get all => _byId.values.toList();

  /// 레벨·주제의 편 목록(편 순서대로).
  List<Dialogue> list({String? region, String? island}) {
    final r = region ?? _level;
    final out = _byId.values.where((d) => d.region == r && (island == null || d.island == island)).toList();
    out.sort((a, b) => a.orderKey.compareTo(b.orderKey));
    return out;
  }

  /// 레벨별 주제 목록(편이 있는 주제만, 고정 순서).
  List<String> islandsOf(String region) {
    final has = _byId.values.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _byId.values.where((d) => d.region == region).length;
  int get total => _byId.length;
}
