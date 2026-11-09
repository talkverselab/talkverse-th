import 'package:shared_preferences/shared_preferences.dart';

import 'embed_env.dart';

/// SharedPreferences 를 이 언어 접두(`th_`)로 감싼 것 — 통합 앱에서 다른 언어 패키지와 키가 겹치지 않게(2026-11-09).
/// API 는 SharedPreferences 와 같은 이름만 둔다. 단독 앱의 옛 키(접두 없음)는 처음 한 번 `th_` 로 옮긴다.
class Prefs {
  Prefs._(this._p);
  final SharedPreferences _p;
  static Prefs? _i;
  static const _migrated = '${storePrefix}_migrated_v1';

  static Future<Prefs> getInstance() async {
    if (_i != null) return _i!;
    final p = await SharedPreferences.getInstance();
    if (!embedded && !(p.getBool(_migrated) ?? false)) {
      for (final k in p.getKeys().toList()) {
        if (k.startsWith(storePrefix)) continue;
        final v = p.get(k);
        final nk = '$storePrefix$k';
        if (p.containsKey(nk)) continue;
        if (v is String) await p.setString(nk, v);
        if (v is bool) await p.setBool(nk, v);
        if (v is int) await p.setInt(nk, v);
        if (v is double) await p.setDouble(nk, v);
        if (v is List) await p.setStringList(nk, v.map((e) => '$e').toList());
        await p.remove(k);
      }
      await p.setBool(_migrated, true);
    }
    return _i = Prefs._(p);
  }

  String _k(String k) => '$storePrefix$k';

  Object? get(String k) => _p.get(_k(k));
  String? getString(String k) => _p.getString(_k(k));
  bool? getBool(String k) => _p.getBool(_k(k));
  int? getInt(String k) => _p.getInt(_k(k));
  double? getDouble(String k) => _p.getDouble(_k(k));
  List<String>? getStringList(String k) => _p.getStringList(_k(k));
  bool containsKey(String k) => _p.containsKey(_k(k));
  Future<bool> setString(String k, String v) => _p.setString(_k(k), v);
  Future<bool> setBool(String k, bool v) => _p.setBool(_k(k), v);
  Future<bool> setInt(String k, int v) => _p.setInt(_k(k), v);
  Future<bool> setDouble(String k, double v) => _p.setDouble(_k(k), v);
  Future<bool> setStringList(String k, List<String> v) => _p.setStringList(_k(k), v);
  Future<bool> remove(String k) => _p.remove(_k(k));

  /// 이 언어의 키만(접두를 뗀 이름).
  Set<String> getKeys() => {for (final k in _p.getKeys()) if (k.startsWith(storePrefix) && k != _migrated) k.substring(storePrefix.length)};

  /// 이 언어의 키만 지운다(다른 언어 기록은 그대로).
  Future<void> clear() async {
    for (final k in _p.getKeys().toList()) {
      if (k.startsWith(storePrefix) && k != _migrated) await _p.remove(k);
    }
  }
}
