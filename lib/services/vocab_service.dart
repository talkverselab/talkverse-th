import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'thai_dict_service.dart';

/// 통합 단어장 항목 — 표제어 기준으로 병합된 단어 (출처는 노출하지 않는다).
class VocabEntry {
  final String id;
  final String th;
  final String reading; // 한글 독음(정규화)
  final String readingRaw; // 원서 표기
  final String ko;
  final String src; // (호환용) 비어 있을 수 있음
  final int order;
  final int day; // 30일 코스 일차 (0 = 없음)
  final String theme; // 30일 코스 테마
  final String kind; // main | plus
  final int? num;
  final String group;
  final String pages;
  final VocabExample? ex;
  final bool uncertain;
  final int rank; // 빈도 순위 (0 = 없음)
  final String topic; // 주제 id (th_topics.json)
  final String part; // 편 이름
  final int level; // 빈도 단계 1~5 (1 = 최상위, 0 = 없음)

  const VocabEntry({
    required this.id,
    required this.th,
    required this.reading,
    required this.readingRaw,
    required this.ko,
    required this.src,
    required this.order,
    this.day = 0,
    this.theme = '',
    this.kind = '',
    this.num,
    this.group = '',
    this.pages = '',
    this.ex,
    this.uncertain = false,
    this.rank = 0,
    this.level = 0,
    this.topic = 'core',
    this.part = '',
  });

  bool get isBook => day > 0;
  bool get isBody => src == 'body';

  /// "A / B" 형태의 변형 목록.
  List<String> get variants =>
      th.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// TTS 용 첫 변형 (괄호 제거).
  String get speakable => variants.first.replaceAll(RegExp(r'[()]'), '').trim();

  /// 분류 라벨 — 30일 코스 일차/테마만. 출처(책명·쪽수)는 노출하지 않는다.
  String get sourceLabel =>
      isBook ? '$day일차${theme.isNotEmpty ? ' · $theme' : ''}' : '';

  /// 빈도 단계 별 표시 — 1단계(최상위) = ★★★★★. level 0 이면 빈 문자열.
  String get levelStars =>
      level == 0 ? '' : '★' * (6 - level) + '☆' * (level - 1);
  String get levelLabel => level == 0 ? '' : '빈도 $level단계 $levelStars';

  factory VocabEntry.fromJson(Map<String, dynamic> m) {
    final exm = m['ex'] as Map<String, dynamic>?;
    return VocabEntry(
      id: m['id'] as String,
      th: m['th'] as String,
      reading: (m['reading'] as String?) ?? '',
      readingRaw: (m['readingRaw'] as String?) ?? '',
      ko: (m['ko'] as String?) ?? '',
      src: (m['src'] as String?) ?? 'capture',
      order: _toInt(m['order']) ?? 0,
      day: _toInt(m['day']) ?? 0,
      theme: (m['theme'] as String?) ?? '',
      kind: (m['kind'] as String?) ?? '',
      num: _toInt(m['num']),
      group: (m['group'] as String?) ?? '',
      pages: (m['pages'] as String?) ?? '',
      ex: exm == null ? null : VocabExample.fromJson(exm),
      uncertain: m['uncertain'] == true,
      rank: _toInt(m['rank']) ?? 0,
      level: _toInt(m['level']) ?? 0,
      topic: (m['topic'] as String?) ?? 'core',
      part: (m['part'] as String?) ?? '',
    );
  }
}

int? _toInt(Object? v) =>
    v is int ? v : (v is double ? v.toInt() : int.tryParse('$v'));

class VocabExample {
  final String th;
  final String reading;
  final String ko;
  const VocabExample({
    required this.th,
    required this.reading,
    required this.ko,
  });

  factory VocabExample.fromJson(Map<String, dynamic> m) => VocabExample(
    th: (m['th'] as String?) ?? '',
    reading: (m['reading'] as String?) ?? '',
    ko: (m['ko'] as String?) ?? '',
  );
}

/// 주제(th_topics.json / th_expressions.json 의 topics).
class VocabTopic {
  final String id;
  final String name;
  final String emoji;
  final int count;
  final List<String> parts;
  const VocabTopic(this.id, this.name, this.emoji, this.count, this.parts);

  factory VocabTopic.fromJson(Map m) => VocabTopic(
    '${m['id']}',
    '${m['name']}',
    '${m['emoji'] ?? '📖'}',
    (m['count'] as num?)?.toInt() ?? 0,
    [
      for (final p in (m['parts'] as List? ?? []).whereType<Map>())
        '${p['name']}',
    ],
  );
}

/// 통합 단어장 로더/검색.
class VocabService {
  VocabService._();
  static final VocabService instance = VocabService._();

  final List<VocabEntry> _entries = [];
  final List<VocabEntry> _obec = []; // 교육부 표준(ป.1~3) — 단어장 화면에는 노출하지 않음
  final List<VocabEntry> _expressions = []; // 표현학습 — 단어장에서 분리한 문장·표현
  final List<VocabTopic> _expressionTopics = [];
  final Map<String, VocabEntry> _byId = {};
  final Map<String, List<VocabEntry>> _byTh = {};
  final Map<int, String> _themes = {};
  bool _loaded = false;
  Future<void>? _loading;

  List<VocabEntry> get entries => _entries;

  /// 태국 교육부 기초 단어(ป.1~3) 풀 — 이미 단어장에 있는 단어는 그 항목을 재사용.
  List<VocabEntry> get obecEntries => _obec;

  /// 표현학습(문장·표현) 목록과 주제.
  List<VocabEntry> get expressions => _expressions;
  List<VocabTopic> get expressionTopics => _expressionTopics;

  /// 빈도 Top1000 풀.
  List<VocabEntry> get top1000Entries =>
      _entries.where((e) => e.rank > 0).toList();

  /// 절벽 구간 누적 풀 — 빈도 1단계부터 [level]단계까지 (1 = 최상위).
  List<VocabEntry> entriesUpToLevel(int level) =>
      _entries.where((e) => e.level > 0 && e.level <= level).toList();

  /// 표준 풀(최대 범위) — 빈도 1000 + 교육부 표준(ป.1~3), 표제어 중복 없음.
  List<VocabEntry> get standardEntries {
    final seen = <String>{};
    return [
      for (final e in [...top1000Entries, ..._obec])
        if (seen.add(e.th)) e,
    ];
  }

  /// 교육부 표준 단어 중 빈도 1000 밖의 단어 (단어장 '표준 단어' 단계).
  List<VocabEntry> get standardExtraEntries =>
      _obec.where((e) => e.level == 0).toList();
  Map<int, String> get themes => _themes;
  bool get isLoaded => _loaded;
  int get count => _entries.length;

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/vocab/th_vocab.json',
      );
      final data = json.decode(raw) as Map<String, dynamic>;
      final meta = data['meta'] as Map<String, dynamic>?;
      final themes = meta?['themes'] as Map<String, dynamic>?;
      if (themes != null) {
        themes.forEach((k, v) {
          final d = int.tryParse(k);
          if (d != null) _themes[d] = '$v';
        });
      }
      for (final e in (data['entries'] as List)) {
        final entry = VocabEntry.fromJson(e as Map<String, dynamic>);
        _entries.add(entry);
        _byId[entry.id] = entry;
        for (final v in entry.variants) {
          _byTh.putIfAbsent(v, () => []).add(entry);
        }
      }
    } catch (_) {
      // 에셋 없이도 동작
    }
    await _loadObec();
    await _loadExpressions();
    _loaded = true;
  }

  Future<void> _loadExpressions() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/vocab/th_expressions.json',
      );
      final data = json.decode(raw) as Map<String, dynamic>;
      for (final t in (data['topics'] as List? ?? []).whereType<Map>()) {
        _expressionTopics.add(VocabTopic.fromJson(t));
      }
      for (final e in (data['entries'] as List? ?? [])) {
        _expressions.add(VocabEntry.fromJson(e as Map<String, dynamic>));
      }
    } catch (_) {
      // 에셋 없이도 동작
    }
  }

  Future<void> _loadObec() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/wordsets/th_obec_basic.json',
      );
      final data = json.decode(raw) as Map<String, dynamic>;
      var i = 0;
      for (final m in (data['standard'] as List? ?? []).whereType<Map>()) {
        final th = '${m['th'] ?? ''}'.trim();
        if (th.isEmpty) continue;
        final existing = _byTh[th];
        if (existing != null && existing.isNotEmpty) {
          _obec.add(existing.first);
          continue;
        }
        final ko = '${m['ko'] ?? ''}'.trim();
        if (ko.isEmpty) continue; // 뜻 없는 항목은 아직 제외
        _obec.add(
          VocabEntry(
            id: 'o${i++}',
            th: th,
            reading: '${m['reading'] ?? ''}',
            readingRaw: '',
            ko: ko,
            src: 'obec',
            order: 100000 + i,
            day: 0,
            theme: 'ป.${m['grade'] ?? ''}',
            rank: (m['rank'] as num?)?.toInt() ?? 0,
            level: (m['level'] as num?)?.toInt() ?? 0,
          ),
        );
      }
    } catch (_) {
      // 에셋 없이도 동작
    }
  }

  VocabEntry? byId(String id) => _byId[id];

  /// 태국어 표제어 완전일치 항목들.
  List<VocabEntry> byTh(String th) => _byTh[th.trim()] ?? const [];

  bool hasTh(String th) => _byTh.containsKey(th.trim());

  Iterable<VocabEntry> get bookEntries => _entries.where((e) => e.isBook);
  Iterable<VocabEntry> get rankedEntries =>
      _entries.where((e) => e.rank > 0).toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));

  List<VocabEntry> byDay(int day) =>
      _entries.where((e) => e.isBook && e.day == day).toList();

  static final _hangul = RegExp(r'[가-힣]');
  static final _thai = RegExp(r'[฀-๿]');

  /// 검색: 태국어(부분일치) / 한글(독음·뜻 부분일치).
  List<VocabEntry> search(String query, {Iterable<VocabEntry>? within}) {
    final q = query.trim();
    if (q.isEmpty) return (within ?? _entries).toList();
    final pool = within ?? _entries;
    if (_thai.hasMatch(q)) {
      return pool.where((e) => e.th.contains(q)).toList();
    }
    if (_hangul.hasMatch(q)) {
      final compact = q.replaceAll(' ', '');
      return pool
          .where(
            (e) =>
                e.ko.contains(q) ||
                e.reading.contains(q) ||
                e.reading.replaceAll(' ', '').contains(compact),
          )
          .toList();
    }
    final lq = q.toLowerCase();
    return pool.where((e) => e.ko.toLowerCase().contains(lq)).toList();
  }

  /// 청크(단어)가 단어장에 있으면 첫 항목의 뜻/독음.
  VocabEntry? lookup(String th) {
    final list = byTh(th);
    return list.isEmpty ? null : list.first;
  }

  static bool isThai(String s) => ThaiDictService.isThai(s);
}
