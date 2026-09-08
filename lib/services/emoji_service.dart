import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 단어 타일의 그림(이모지) — 한국어 뜻의 키워드로 고르고, 없으면 주제별 풀에서
/// 같은 화면 안에서 겹치지 않게 배정한다.
class EmojiService {
  EmojiService._();
  static final EmojiService instance = EmojiService._();

  final Map<String, String> _keywords = {};
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
      if (ko.contains(k)) return _keywords[k];
    }
    return null;
  }

  /// 한 화면의 단어 목록에 그림을 배정 — 같은 화면 안에서는 같은 그림이 나오지 않게.
  /// [kos] 순서대로 이모지 목록을 돌려준다.
  List<String> assign(List<String> kos, {String topic = 'core'}) {
    final used = <String>{};
    final out = List<String>.filled(kos.length, '');
    // 1) 키워드 매칭 먼저
    for (var i = 0; i < kos.length; i++) {
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
