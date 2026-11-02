import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 학습자 프로필(「나」) — 일본어앱 learner_prefs.dart 이식(2026-11-02). 글로벌 버전이라 인물 이름을 고정하지 않는다(사용자 지시).
/// 회화의 화자 A = 학습자. 성별 → A 의 목소리(나중엔 장면 그림의 A 도), 이름 → `{name}` 자리.
class LearnerPrefs {
  LearnerPrefs._();
  static const _kName = 'learner_name';
  static const _kGender = 'learner_gender'; // male | female

  static final ValueNotifier<String> name = ValueNotifier('');
  static final ValueNotifier<String> gender = ValueNotifier('male');

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    name.value = p.getString(_kName) ?? '';
    gender.value = p.getString(_kGender) ?? 'male';
  }

  static Future<void> setName(String v) async {
    name.value = v.trim();
    (await SharedPreferences.getInstance()).setString(_kName, name.value);
  }

  static Future<void> setGender(String v) async {
    gender.value = v == 'female' ? 'female' : 'male';
    (await SharedPreferences.getInstance()).setString(_kGender, gender.value);
  }

  static bool get isFemale => gender.value == 'female';

  /// 화자 코드 → 목소리 성별. A = 학습자(프로필), C = 남성 조연, 그 밖(B·D) = 여성.
  static String voiceGender(String speaker) => speaker == 'A' ? gender.value : (speaker == 'C' ? 'male' : 'female');

  /// 본문의 `{name}` 치환. 이름이 없으면 자리표시 「○○」.
  static String fill(String text, {bool ko = false}) {
    if (!text.contains('{')) return text;
    final n = name.value.isNotEmpty ? name.value : '○○';
    return text.replaceAll('{name}', n).replaceAll(RegExp(r'\{(country|city|lang)\}'), '○○');
  }
}
