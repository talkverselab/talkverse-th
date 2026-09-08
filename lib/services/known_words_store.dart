import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "아는 단어" 저장소 — 주제별 단어 타일의 체크박스.
/// 기본은 모두 체크(학습 대상). 체크를 없앤 단어 = 아는 단어 → 플래시카드에서 제외.
class KnownWordsStore {
  KnownWordsStore._();

  static const _key = 'known_words_th';
  static final Set<String> _known = {};
  static final ValueNotifier<int> version = ValueNotifier<int>(0);
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    _known
      ..clear()
      ..addAll(p.getStringList(_key) ?? const []);
    _loaded = true;
    version.value++;
  }

  /// 체크되어 있는가(= 아직 학습 대상인가).
  static bool isChecked(String th) => !_known.contains(th.trim());

  static bool isKnown(String th) => _known.contains(th.trim());

  static Future<void> setKnown(String th, bool known) async {
    final t = th.trim();
    if (known) {
      _known.add(t);
    } else {
      _known.remove(t);
    }
    version.value++;
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, _known.toList());
  }

  static Future<void> toggle(String th) => setKnown(th, !isKnown(th));

  static int get knownCount => _known.length;
}
