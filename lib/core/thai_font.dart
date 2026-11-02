import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 태국어 글꼴 선택 — 사용자 지시(2026-11-02) "태국어는 폰트에 따라 글자의 느낌이 많이 달라져, 고를 수 있게".
/// 고리(หัว) 있는 전통형과 고리 없는 현대형의 인상 차이가 커서 학습자가 바꿔 본다. 글꼴은 모두 OFL(assets/fonts/OFL_*.txt).
/// 선택한 글꼴은 ThemeData.fontFamily 로 들어가고, 한글 등 그 글꼴에 없는 글자는 AppTheme.fontFallback 으로 보인다.
class ThaiFont {
  final String id;
  final String? family; // null = 기기 기본
  final String label;
  final String desc;
  const ThaiFont(this.id, this.family, this.label, this.desc);
}

class ThaiFontPrefs {
  ThaiFontPrefs._();
  static const _k = 'thai_font_v1';

  static const options = <ThaiFont>[
    ThaiFont('system', null, '기기 기본', '폰에 들어 있는 태국어 글꼴'),
    ThaiFont('looped', 'NotoSansThaiLooped', '고리형 표준', '교과서·표지판처럼 고리가 있는 글꼴 — 처음 배울 때 추천'),
    ThaiFont('sarabun', 'Sarabun', '사라분', '공문서·신문에 많이 쓰는 고리형'),
    ThaiFont('serif', 'NotoSerifThai', '전통 세리프', '책 본문 같은 고전적인 느낌'),
    ThaiFont('kanit', 'Kanit', '깐잇', '광고·간판에 흔한 고리 없는 현대형'),
    ThaiFont('prompt', 'Prompt', '프롬', '둥글고 친근한 고리 없는 현대형'),
  ];

  static final ValueNotifier<String> id = ValueNotifier('system');

  static ThaiFont get current => options.firstWhere((o) => o.id == id.value, orElse: () => options.first);
  static String? get family => current.family;

  static Future<void> load() async {
    final v = (await SharedPreferences.getInstance()).getString(_k);
    if (v != null && options.any((o) => o.id == v)) id.value = v;
  }

  static Future<void> set(String v) async {
    id.value = v;
    (await SharedPreferences.getInstance()).setString(_k, v);
  }
}
