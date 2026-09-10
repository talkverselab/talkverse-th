import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 단어 타일의 그림(이모지) — 한국어 뜻의 키워드로 고르고, 없으면 주제별 풀에서
/// 같은 화면 안에서 겹치지 않게 배정한다.
class EmojiService {
  EmojiService._();
  static final EmojiService instance = EmojiService._();

  final Map<String, String> _keywords = {};
  final Map<String, String> _words = {}; // 태국어 표제어 → 그림 (검토본, 최우선)
  List<String> _keywordOrder = []; // 긴 키워드 우선
  final Map<String, List<String>> _pools = {};
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/vocab/th_emoji_map.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      (data['keywords'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        if (k.trim().isNotEmpty && '$v'.trim().isNotEmpty) {
          _keywords[k.trim()] = '$v'.trim();
        }
      });
      (data['words'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        if (k.trim().isNotEmpty && '$v'.trim().isNotEmpty) {
          _words[k.trim()] = '$v'.trim();
        }
      });
      (data['pools'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        _pools[k] = [for (final e in (v as List)) '$e'];
      });
      _keywordOrder = _keywords.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
    } catch (_) {
      // 에셋 없이도 동작 (기본 풀)
    }
    if (_pools.isEmpty) {
      _pools['core'] = _fallback;
    }
    _loaded = true;
  }

  static const List<String> _fallback = [
    '📘', '📗', '📙', '📕', '📒', '📔', '🗂️', '🔖', '🏷️', '📌', '📍', '🧭', '🔑', '🔔', '🎈',
    '🎀', '🎁', '🧩', '🎯', '🪁', '🧸', '🪄', '🔮', '🪙', '💎', '🧿', '🪞', '🧺', '🪣', '🧴',
  ];

  /// 키워드 매칭 (긴 키워드 우선). 없으면 null.
  String? byKeyword(String ko) {
    if (ko.isEmpty) return null;
    for (final k in _keywordOrder) {
      if (!ko.contains(k)) continue;
      // 짧은 키워드(3자 이하)는 낱말 경계에서만 — '만약'의 '약', '강조'의 '강' 방지
      if (k.length <= 3 && !_wholeWord(ko, k)) continue;
      return _keywords[k];
    }
    return null;
  }

  static bool _wholeWord(String ko, String k) {
    var start = 0;
    while (true) {
      final i = ko.indexOf(k, start);
      if (i < 0) return false;
      final before = i == 0 ? null : ko.codeUnitAt(i - 1);
      final afterIdx = i + k.length;
      final after = afterIdx >= ko.length ? null : ko.codeUnitAt(afterIdx);
      if (!_isHangul(before) && !_isHangul(after)) return true;
      start = i + 1;
    }
  }

  static bool _isHangul(int? c) => c != null && c >= 0xAC00 && c <= 0xD7A3;

  /// 표제어로 직접 지정된 그림 (없으면 null).
  String? byTh(String th) {
    final t = th.trim();
    return _words[t] ?? _words[t.split('/').first.trim()];
  }

  /// 한 화면의 단어 목록에 그림을 배정 — 표제어로 직접 지정한 그림을 먼저 쓰고,
  /// 나머지(키워드, 풀)는 같은 화면 안에서 같은 그림이 나오지 않게.
  /// [kos] 순서대로 이모지 목록을 돌려준다.
  List<String> assign(
    List<String> kos, {
    List<String>? ths,
    String topic = 'core',
  }) {
    final used = <String>{};
    final out = List<String>.filled(kos.length, '');
    // 0) 표제어 직접 지정 먼저 — 검토된 그림이므로 겹쳐도 그대로 쓴다
    //    (키워드, 풀 배정만 화면 안에서 중복을 피한다)
    if (ths != null) {
      for (var i = 0; i < kos.length && i < ths.length; i++) {
        final e = byTh(ths[i]);
        if (e != null) {
          out[i] = e;
          used.add(e);
        }
      }
    }
    // 1) 키워드 매칭
    for (var i = 0; i < kos.length; i++) {
      if (out[i].isNotEmpty) continue;
      final e = byKeyword(kos[i]);
      if (e != null && used.add(e)) out[i] = e;
    }
    // 2) 나머지는 주제 풀 → core 풀 → 기본 풀 순서로 중복 없이
    final pool = <String>[
      ...?_pools[topic],
      ...?_pools['core'],
      ..._fallback,
      for (final p in _pools.values) ...p,
    ];
    var cursor = 0;
    for (var i = 0; i < kos.length; i++) {
      if (out[i].isNotEmpty) continue;
      while (cursor < pool.length && used.contains(pool[cursor])) {
        cursor++;
      }
      if (cursor < pool.length) {
        out[i] = pool[cursor];
        used.add(pool[cursor]);
        cursor++;
      } else {
        out[i] = '🔸';
      }
    }
    return out;
  }
}
