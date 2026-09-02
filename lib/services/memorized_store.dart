import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 외우기 모드: 전체 보기 / 태국어·독음 가림 / 뜻 가림.
enum StudyMode { all, hideTh, hideKo }

/// 외운 단어·문장 저장소 (원문 키, SharedPreferences 영구 저장).
class MemorizedStore {
  MemorizedStore._();
  static const _key = 'memorized_words';
  static final Set<String> _set = {};
  static final ValueNotifier<int> version = ValueNotifier(0);
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    _set.addAll(p.getStringList(_key) ?? const []);
    _loaded = true;
    version.value++;
  }

  static bool contains(String key) => _set.contains(key);

  static Future<void> toggle(String key) async {
    if (!_set.remove(key)) _set.add(key);
    version.value++;
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, _set.toList());
  }
}
