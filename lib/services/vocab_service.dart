import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'thai_dict_service.dart';

/// 통합 단어장 항목 — 회화집 캡처(capture) + 나혼자 단어장 30일(book).
class VocabEntry {
  final String id;
  final String th;
  final String reading; // 한글 독음(정규화)
  final String readingRaw; // 원서 표기
  final String ko;
  final String src; // capture | book
  final int order;
  final int day; // book only
  final String theme; // book only
  final String kind; // main | plus
  final int? num; // book main 번호
  final String group;
  final String pages;
  final VocabExample? ex;
  final bool uncertain;

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
  });

  bool get isBook => src == 'book';
  bool get isBody => src == 'body';

  /// "A / B" 형태의 변형 목록.
  List<String> get variants =>
      th.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// TTS 용 첫 변형 (괄호 제거).
  String get speakable =>
      variants.first.replaceAll(RegExp(r'[()]'), '').trim();

  String get sourceLabel {
    if (isBook) return '나혼자 30일 · $day일차${theme.isNotEmpty ? ' $theme' : ''}';
    if (isBody) {
      return '회화집 본문 p.$pages${group.isNotEmpty ? ' · $group' : ''}';
    }
    return '회화집 단어장';
  }

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
    );
  }
}

int? _toInt(Object? v) =>
    v is int ? v : (v is double ? v.toInt() : int.tryParse('$v'));

class VocabExample {
  final String th;
  final String reading;
  final String ko;
  const VocabExample({required this.th, required this.reading, required this.ko});

  factory VocabExample.fromJson(Map<String, dynamic> m) => VocabExample(
        th: (m['th'] as String?) ?? '',
        reading: (m['reading'] as String?) ?? '',
        ko: (m['ko'] as String?) ?? '',
      );
}

/// 통합 단어장 로더/검색.
class VocabService {
  VocabService._();
  static final VocabService instance = VocabService._();

  final List<VocabEntry> _entries = [];
  final Map<String, VocabEntry> _byId = {};
  final Map<String, List<VocabEntry>> _byTh = {};
  final Map<int, String> _themes = {};
  bool _loaded = false;
  Future<void>? _loading;

  List<VocabEntry> get entries => _entries;
  Map<int, String> get themes => _themes;
  bool get isLoaded => _loaded;
  int get count => _entries.length;

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/vocab/th_vocab.json');
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
    _loaded = true;
  }

  VocabEntry? byId(String id) => _byId[id];

  /// 태국어 표제어 완전일치 항목들.
  List<VocabEntry> byTh(String th) => _byTh[th.trim()] ?? const [];

  bool hasTh(String th) => _byTh.containsKey(th.trim());

  Iterable<VocabEntry> get captureEntries =>
      _entries.where((e) => !e.isBook && !e.isBody);
  Iterable<VocabEntry> get bodyEntries => _entries.where((e) => e.isBody);
  Iterable<VocabEntry> get bookEntries => _entries.where((e) => e.isBook);

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
          .where((e) =>
              e.ko.contains(q) ||
              e.reading.contains(q) ||
              e.reading.replaceAll(' ', '').contains(compact))
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
