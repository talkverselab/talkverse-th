import 'package:shared_preferences/shared_preferences.dart';

/// 문장별 사용자 메모. SharedPreferences 에 저장.
/// key = "memo:`patternId`:`idx`"
class MemoService {
  MemoService._();
  static final MemoService instance = MemoService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> _p() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _key(String patternId, int idx) => 'memo:$patternId:$idx';

  Future<String?> get(String patternId, int idx) async {
    final p = await _p();
    return p.getString(_key(patternId, idx));
  }

  Future<void> set(String patternId, int idx, String text) async {
    final p = await _p();
    if (text.trim().isEmpty) {
      await p.remove(_key(patternId, idx));
    } else {
      await p.setString(_key(patternId, idx), text.trim());
    }
  }

  Future<bool> has(String patternId, int idx) async {
    final m = await get(patternId, idx);
    return m != null && m.isNotEmpty;
  }

  /// 모든 메모 key·value 반환 (export 용)
  Future<List<MemoEntry>> all() async {
    final p = await _p();
    final keys = p.getKeys().where((k) => k.startsWith('memo:')).toList()..sort();
    return [
      for (final k in keys)
        MemoEntry(key: k, value: p.getString(k) ?? ''),
    ];
  }

  Future<int> count() async {
    final p = await _p();
    return p.getKeys().where((k) => k.startsWith('memo:')).length;
  }

  Future<void> clearAll() async {
    final p = await _p();
    final keys = p.getKeys().where((k) => k.startsWith('memo:')).toList();
    for (final k in keys) {
      await p.remove(k);
    }
  }
}

class MemoEntry {
  final String key;
  final String value;
  MemoEntry({required this.key, required this.value});

  String get patternId {
    final parts = key.split(':');
    return parts.length >= 2 ? parts[1] : '';
  }

  int get idx {
    final parts = key.split(':');
    return parts.length >= 3 ? int.tryParse(parts[2]) ?? 0 : 0;
  }
}
