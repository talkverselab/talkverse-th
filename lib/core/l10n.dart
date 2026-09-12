import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n_dict.dart';

/// 앱 표시 언어 — 한국어(기본) / English / 日本語 / 中文.
/// 화면 문구(메뉴·버튼·안내)만 바뀐다. 회화·단어 콘텐츠는 그대로.
enum AppLang {
  ko('한국어'),
  en('English'),
  ja('日本語'),
  zh('中文');

  final String label;
  const AppLang(this.label);
}

/// 표시 언어 전역 설정. 프로필에서 바꾸면 앱 루트가 통째로 다시 그려진다.
class AppLangPrefs {
  AppLangPrefs._();

  static const _key = 'app_lang';
  static final ValueNotifier<AppLang> lang = ValueNotifier<AppLang>(AppLang.ko);

  static bool get isKo => lang.value == AppLang.ko;
  static bool get isEn => lang.value == AppLang.en;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key) ?? 'ko';
    lang.value = AppLang.values.firstWhere((l) => l.name == v, orElse: () => AppLang.ko);
  }

  static Future<void> set(AppLang l) async {
    lang.value = l;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, l.name);
  }

  /// 다음 순서의 언어 (프로필 부제목용).
  static AppLang peekNext() => AppLang.values[(lang.value.index + 1) % AppLang.values.length];

  /// 한국어 → English → 日本語 → 中文 → 한국어 … 순환.
  static Future<void> next() =>
      set(AppLang.values[(lang.value.index + 1) % AppLang.values.length]);
}

Map<String, String>? _dictFor(AppLang l) => switch (l) {
      AppLang.ko => null,
      AppLang.en => kDictEn,
      AppLang.ja => kDictJa,
      AppLang.zh => kDictZh,
    };

/// UI 문구 — 현재 언어 사전에서 찾고, 없으면 한국어 그대로.
String tr(String ko) => _dictFor(AppLangPrefs.lang.value)?[ko] ?? ko;

/// 보간 문구 — 템플릿의 `{0}`, `{1}`… 자리에 값을 채운다.
/// 예) trf('{0}단계 · 문장당 {1}초', [stage, sec])
String trf(String template, List<Object?> args) {
  var s = _dictFor(AppLangPrefs.lang.value)?[template] ?? template;
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return s;
}
