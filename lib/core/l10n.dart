import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n_ko_en.dart';

/// 앱 표시 언어 — 한국어(기본) / 영어.
enum AppLang { ko, en }

/// 표시 언어 전역 설정. 프로필에서 바꾸면 앱 루트가 통째로 다시 그려진다.
class AppLangPrefs {
  AppLangPrefs._();

  static const _key = 'app_lang';
  static final ValueNotifier<AppLang> lang = ValueNotifier<AppLang>(AppLang.ko);

  static bool get isEn => lang.value == AppLang.en;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    lang.value = (p.getString(_key) ?? 'ko') == 'en' ? AppLang.en : AppLang.ko;
  }

  static Future<void> set(AppLang l) async {
    lang.value = l;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, l.name);
  }

  static Future<void> toggle() =>
      set(lang.value == AppLang.ko ? AppLang.en : AppLang.ko);
}

/// UI 문구 — 영어 모드면 사전(`kKoEn`)에서 찾고, 없으면 한국어 그대로.
String tr(String ko) => AppLangPrefs.isEn ? (kKoEn[ko] ?? ko) : ko;

/// 보간 문구 — 템플릿의 `{0}`, `{1}`… 자리에 값을 채운다.
/// 예) trf('{0}단계 · 문장당 {1}초', [stage, sec])
String trf(String template, List<Object?> args) {
  var s = AppLangPrefs.isEn ? (kKoEn[template] ?? template) : template;
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return s;
}
