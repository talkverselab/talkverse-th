import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'thai_dict_service.dart';
import 'vocab_service.dart';

/// 루트 단어 — 여러 단어에 공통으로 들어가는 핵심 형태소 (예: น้ำ 남 '물').
class RootInfo {
  final String th;
  final String reading;
  final String ko;
  final String note;
  const RootInfo({
    required this.th,
    required this.reading,
    required this.ko,
    this.note = '',
  });

  factory RootInfo.fromJson(Map<String, dynamic> m) => RootInfo(
    th: m['th'] as String,
    reading: (m['reading'] as String?) ?? '',
    ko: (m['ko'] as String?) ?? '',
    note: (m['note'] as String?) ?? '',
  );
}

/// 분해 조각 — th 와 뜻(없으면 null), 루트 여부.
class RootPiece {
  final String th;
  final String? ko;
  final bool isRoot;
  const RootPiece(this.th, this.ko, this.isRoot);
}

/// 루트 파생어를 어느 단어 풀에서 찾을지.
enum RootStage {
  all, // 통합 단어장 전체 (단어 행 링크용 기본)
  upTo2, // 1~2단계 누적 — 회화 빈도 1~250위
  upTo3, // ~3단계 누적 — ~500위
  upTo4, // ~4단계 누적 — ~750위
  upTo5, // ~5단계 누적 — ~1000위
  standard, // 표준 — 빈도 1000 + 교육부 표준 단어(ป.1~3), 최대 범위
}

/// 루트 가족 — 확실한 파생(strong)과 후보(weak).
class RootFamily {
  final RootInfo root;
  final List<VocabEntry> strong;
  final List<VocabEntry> weak;
  const RootFamily({
    required this.root,
    required this.strong,
    required this.weak,
  });
  int get count => strong.length + weak.length;
  List<VocabEntry> get all => [...strong, ...weak];
}

/// 루트 단어 ↔ 파생어 연결.
///
/// zh 의 발음부(声旁)와 같은 역할: 루트 화면에서 가족을 펼치고,
/// 모든 단어 행에서 자기 루트로 링크한다. 파생 판정은 문자열 포함 +
/// 음절 경계 규칙(루트 앞뒤가 결합 모음/성조 부호가 아님).
class RootService {
  RootService._();
  static final RootService instance = RootService._();

  final List<RootInfo> _roots = [];
  final Map<String, RootInfo> _byTh = {};
  final Map<String, RootFamily> _familyCache = {};
  final Map<RootStage, Map<String, RootFamily>> _stageCache = {};
  final Map<String, String> _pieces = {}; // 루트가 아닌 조각의 뜻 (검토본)
  final Set<String> _reject = {}; // 'root|word' — 철자만 우연히 포함

  /// 뜻을 못 찾은 조각의 표시 라벨.
  static const unknownLabel = '어원불명확';
  final Map<String, List<RootInfo>> _rootsOfCache = {};
  bool _loaded = false;
  Future<void>? _loading;

  List<RootInfo> get roots => _roots;
  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    await VocabService.instance.ensureLoaded();
    await ThaiDictService.instance.ensureLoaded();
    try {
      final raw = await rootBundle.loadString(
        'assets/data/vocab/th_roots.json',
      );
      final data = json.decode(raw) as Map<String, dynamic>;
      for (final r in (data['roots'] as List)) {
        final info = RootInfo.fromJson(r as Map<String, dynamic>);
        if (_byTh.containsKey(info.th)) continue;
        _roots.add(info);
        _byTh[info.th] = info;
      }
      for (final e in ((data['pieces'] as Map?) ?? {}).entries) {
        _pieces['${e.key}'] = '${e.value}';
      }
      for (final r in (data['reject'] as List? ?? [])) {
        _reject.add('$r');
      }
    } catch (_) {}
    // 파생 수 기준 정렬 (많은 순)
    _roots.sort((a, b) => familyOf(b).count.compareTo(familyOf(a).count));
    _loaded = true;
  }

  RootInfo? lookup(String th) => _byTh[th];

  // 결합 모음·성조 부호 (앞 자음에 붙음)
  static bool _isCombining(int c) =>
      c == 0x0E31 ||
      (c >= 0x0E34 && c <= 0x0E3A) ||
      (c >= 0x0E47 && c <= 0x0E4E);
  // 뒤따르는 모음 (앞 음절을 이어감)
  static bool _isTrailingVowel(int c) =>
      c == 0x0E30 || c == 0x0E32 || c == 0x0E33;
  // 앞에 오는 모음 (다음 자음과 한 음절)
  static bool _isLeadingVowel(int c) => c >= 0x0E40 && c <= 0x0E44;

  /// [word] 안에 [root]가 음절 경계에 맞게 들어있는지.
  static bool containsAtBoundary(String word, String root) {
    if (root.isEmpty || word == root) return false;
    var start = 0;
    while (true) {
      final idx = word.indexOf(root, start);
      if (idx < 0) return false;
      final end = idx + root.length;
      var ok = true;
      if (end < word.length) {
        final next = word.codeUnitAt(end);
        if (_isCombining(next) || _isTrailingVowel(next)) ok = false;
      }
      if (idx > 0) {
        final prev = word.codeUnitAt(idx - 1);
        if (_isLeadingVowel(prev)) ok = false;
        // 루트 첫 글자가 결합 부호로 시작하지 않는 한, 바로 앞이 자음이면
        // 그 자음의 모음 없는 음절일 수 있음 — 허용
      }
      if (ok) return true;
      start = idx + 1;
    }
  }

  /// 조각의 뜻 — 단어장 → 루트 → (없으면 null). 조각 안에 다른 루트가 있으면 그 루트로 재분해.
  String? _pieceKo(String piece) {
    final curated = _pieces[piece];
    if (curated != null) return curated;
    final r = _byTh[piece];
    if (r != null) return r.ko.split(',').first.trim();
    final v = VocabService.instance.lookup(piece);
    if (v != null) return v.ko.split(',').first.trim();
    return null;
  }

  /// 조각 뜻 (없으면 [unknownLabel]).
  String pieceLabel(RootPiece p) =>
      (p.ko == null || p.ko!.isEmpty) ? unknownLabel : p.ko!;

  /// 분해 공식 — 예: '방 + 물 ⇒ 화장실'. 루트 자체면 뜻만.
  String formula(String word, String root, String ko) {
    final w = word.split('/').first.trim();
    final first = ko.split(RegExp(r'[,;·]')).first.trim();
    if (w == root) return first;
    final parts = breakdown(w, root);
    if (parts.length < 2) return first;
    return '${parts.map(pieceLabel).join(' + ')} ⇒ $first';
  }

  /// 조각이 홀로 설 수 없는 파편(자음 하나, 부호로 시작, 괄호 등)이면 우연 일치.
  static bool isFragment(String piece) {
    final p = piece.trim();
    if (p.isEmpty) return false;
    if (p.contains(')') || p.contains('(') || p.contains('/')) return true;
    final c = p.codeUnitAt(0);
    if (_isCombining(c) || _isTrailingVowel(c)) return true;
    if (p.length == 1 && c >= 0x0E01 && c <= 0x0E2E) return true; // 자음 하나
    if (p.length <= 2 && p.contains('\u0E4C')) return true; // ย์ ห์ ต์ ษ์
    return false;
  }

  /// 단어를 루트와 나머지 조각으로 분해하고 각 조각의 뜻을 붙인다.
  /// 예: น้ำแข็ง / น้ำ → [น้ำ(물), แข็ง(딱딱하다)]
  List<RootPiece> breakdown(String word, String root) {
    final w = word.trim();
    final idx = w.indexOf(root);
    if (idx < 0) return [RootPiece(w, _pieceKo(w), false)];
    final out = <RootPiece>[];
    void addRest(String rest) {
      final p = rest.trim();
      if (p.isEmpty) return;
      final ko = _pieceKo(p);
      if (ko != null) {
        out.add(RootPiece(p, ko, false));
        return;
      }
      // 나머지에 다른 루트가 있으면 한 번 더 쪼갠다
      for (final r in _roots) {
        if (r.th != root && p != r.th && containsAtBoundary(p, r.th)) {
          final j = p.indexOf(r.th);
          addRest(p.substring(0, j));
          out.add(RootPiece(r.th, r.ko, true));
          addRest(p.substring(j + r.th.length));
          return;
        }
      }
      out.add(RootPiece(p, null, false));
    }

    addRest(w.substring(0, idx));
    out.add(RootPiece(root, _byTh[root]?.ko ?? _pieceKo(root), true));
    addRest(w.substring(idx + root.length));
    return out;
  }

  RootFamily familyOf(RootInfo root, {RootStage stage = RootStage.all}) {
    final cache = stage == RootStage.all
        ? _familyCache
        : _stageCache.putIfAbsent(stage, () => {});
    return cache.putIfAbsent(root.th, () {
      final vs = VocabService.instance;
      final pool = switch (stage) {
        RootStage.all => vs.entries,
        RootStage.upTo2 => vs.entriesUpToLevel(2),
        RootStage.upTo3 => vs.entriesUpToLevel(3),
        RootStage.upTo4 => vs.entriesUpToLevel(4),
        RootStage.upTo5 => vs.entriesUpToLevel(5),
        RootStage.standard => vs.standardEntries,
      };
      final strong = <VocabEntry>[];
      final weak = <VocabEntry>[];
      final seen = <String>{};
      for (final e in pool) {
        var matched = false;
        for (final v in e.variants) {
          if (!containsAtBoundary(v, root.th)) continue;
          matched = true;
        }
        if (!matched) continue;
        final key = '${e.th}|${e.ko}';
        if (!seen.add(key)) continue;
        final w = e.th.split('/').first.trim();
        if (_reject.contains('${root.th}|$w') || _reject.contains('${root.th}|${e.th}')) {
          continue;
        }
        // 나머지 조각이 파편이면 철자만 우연히 겹친 것 — 가족에서 제외
        final pieces = breakdown(w, root.th);
        if (pieces.any((p) => !p.isRoot && isFragment(p.th))) continue;
        // 검토 완료: 후보 구분 없이 모두 가족으로 (뜻 없는 조각은 '어원불명확')
        strong.add(e);
      }
      int cmp(VocabEntry a, VocabEntry b) => a.th.length.compareTo(b.th.length);
      strong.sort(cmp);
      weak.sort(cmp);
      return RootFamily(root: root, strong: strong, weak: weak);
    });
  }

  RootFamily? familyOfTh(String th) {
    final r = _byTh[th];
    return r == null ? null : familyOf(r);
  }

  /// [word]에 들어있는 루트들 (긴 루트 우선, 자기 자신 제외).
  List<RootInfo> rootsOf(String word) {
    final w = word.trim();
    return _rootsOfCache.putIfAbsent(w, () {
      final found = <RootInfo>[];
      for (final variant in w.split('/')) {
        final v = variant.trim();
        for (final r in _roots) {
          if (found.contains(r)) continue;
          if (v == r.th) continue;
          if (containsAtBoundary(v, r.th)) found.add(r);
        }
      }
      // 다른 루트에 완전히 포함된 짧은 루트 제거 (รองเท้า 있으면 เท้า 제외)
      found.removeWhere((r) => found.any((o) => o != r && o.th.contains(r.th)));
      found.sort((a, b) => b.th.length.compareTo(a.th.length));
      return found;
    });
  }

  /// 단어 자체가 루트인지.
  bool isRoot(String th) => _byTh.containsKey(th.trim());
}
