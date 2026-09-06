import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 회화집 본문(12~153쪽) — 섹션 → 주제(페이지) → 그룹 → 행.
class PbSection {
  final String id;
  final String name;
  final String emoji;
  final int from;
  const PbSection(
      {required this.id,
      required this.name,
      required this.emoji,
      required this.from});
}

class PbRow {
  final String ko;
  final String th;
  final String reading;
  final String en;
  final bool reply;
  final String ref;
  final bool template;
  final bool uncertain;
  const PbRow({
    required this.ko,
    required this.th,
    required this.reading,
    required this.en,
    this.reply = false,
    this.ref = '',
    this.template = false,
    this.uncertain = false,
  });

  /// TTS 용 — 빈칸(____)·기호 제거, "A / B" 는 첫 변형.
  String get speakable => th
      .split('/')
      .first
      .replaceAll(RegExp(r'[_～~\[\]()!?]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  factory PbRow.fromJson(Map<String, dynamic> m) => PbRow(
        ko: (m['ko'] as String?) ?? '',
        th: (m['th'] as String?) ?? '',
        reading: (m['reading'] as String?) ?? '',
        en: (m['en'] as String?) ?? '',
        reply: m['reply'] == true,
        ref: (m['ref'] as String?) ?? '',
        template: m['template'] == true,
        uncertain: m['uncertain'] == true,
      );
}

class PbGroup {
  final String label;
  final bool isWord; // kind == word
  final int page;
  final List<PbRow> rows;
  const PbGroup(
      {required this.label,
      required this.isWord,
      required this.page,
      required this.rows});

  factory PbGroup.fromJson(Map<String, dynamic> m) => PbGroup(
        label: (m['label'] as String?) ?? '',
        isWord: m['kind'] == 'word',
        page: (m['page'] as num?)?.toInt() ?? 0,
        rows: [
          for (final r in (m['rows'] as List? ?? []))
            PbRow.fromJson(r as Map<String, dynamic>)
        ],
      );
}

class PbNote {
  final String title;
  final String body;
  const PbNote({required this.title, required this.body});
}

class PbTopic {
  final String id;
  final String section;
  final String title;
  final int page;
  final String intro;
  final List<PbGroup> groups;
  final List<PbNote> notes;
  final List<String> captions;
  const PbTopic({
    required this.id,
    required this.section,
    required this.title,
    required this.page,
    required this.intro,
    required this.groups,
    required this.notes,
    required this.captions,
  });

  int get phraseCount =>
      groups.where((g) => !g.isWord).fold(0, (n, g) => n + g.rows.length);
  int get wordCount =>
      groups.where((g) => g.isWord).fold(0, (n, g) => n + g.rows.length);

  factory PbTopic.fromJson(Map<String, dynamic> m) => PbTopic(
        id: (m['id'] as String?) ?? '',
        section: (m['section'] as String?) ?? '',
        title: (m['title'] as String?) ?? '',
        page: (m['page'] as num?)?.toInt() ?? 0,
        intro: (m['intro'] as String?) ?? '',
        groups: [
          for (final g in (m['groups'] as List? ?? []))
            PbGroup.fromJson(g as Map<String, dynamic>)
        ],
        notes: [
          for (final n in (m['notes'] as List? ?? []).whereType<Map>())
            PbNote(
                title: (n['title'] as String?) ?? '',
                body: (n['body'] as String?) ?? '')
        ],
        captions: [
          for (final c in (m['captions'] as List? ?? [])) '$c'
        ],
      );
}

/// 검색 결과 한 건 — 어느 주제/그룹의 행인지.
class PbHit {
  final PbTopic topic;
  final PbGroup group;
  final PbRow row;
  const PbHit(this.topic, this.group, this.row);
}

class PhrasebookService {
  PhrasebookService._();
  static final PhrasebookService instance = PhrasebookService._();

  final List<PbSection> _sections = [];
  final List<PbTopic> _topics = [];
  bool _loaded = false;
  Future<void>? _loading;

  List<PbSection> get sections => _sections;
  List<PbTopic> get topics => _topics;
  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/vocab/th_phrasebook.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final meta = data['meta'] as Map<String, dynamic>?;
      for (final s in (meta?['sections'] as List? ?? []).whereType<Map>()) {
        _sections.add(PbSection(
          id: (s['id'] as String?) ?? '',
          name: (s['name'] as String?) ?? '',
          emoji: (s['emoji'] as String?) ?? '💬',
          from: (s['from'] as num?)?.toInt() ?? 0,
        ));
      }
      for (final t in (data['topics'] as List? ?? [])) {
        _topics.add(PbTopic.fromJson(t as Map<String, dynamic>));
      }
    } catch (_) {
      // 에셋 없이도 동작
    }
    _loaded = true;
  }

  List<PbTopic> bySection(String id) =>
      _topics.where((t) => t.section == id).toList();

  int phraseCount(String? section) => _topics
      .where((t) => section == null || t.section == section)
      .fold(0, (n, t) => n + t.phraseCount);

  int wordCount(String? section) => _topics
      .where((t) => section == null || t.section == section)
      .fold(0, (n, t) => n + t.wordCount);

  static final _hangul = RegExp(r'[가-힣]');
  static final _thai = RegExp(r'[฀-๿]');

  /// 태국어(부분일치) / 한글(뜻·독음) / 영어 검색.
  List<PbHit> search(String query, {int limit = 300}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final compact = q.replaceAll(' ', '');
    final lq = q.toLowerCase();
    bool match(PbRow r) {
      if (_thai.hasMatch(q)) return r.th.contains(q);
      if (_hangul.hasMatch(q)) {
        return r.ko.contains(q) ||
            r.reading.contains(q) ||
            r.reading.replaceAll(' ', '').contains(compact);
      }
      return r.en.toLowerCase().contains(lq) ||
          r.ko.toLowerCase().contains(lq);
    }

    final out = <PbHit>[];
    for (final t in _topics) {
      for (final g in t.groups) {
        for (final r in g.rows) {
          if (match(r)) {
            out.add(PbHit(t, g, r));
            if (out.length >= limit) return out;
          }
        }
      }
    }
    return out;
  }
}
