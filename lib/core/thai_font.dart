import 'package:flutter/foundation.dart';
import './prefs.dart';
import 'embed_env.dart';

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

  /// Grok 추천(2026-11-02, 느낌이 서로 크게 다르면서 많이 쓰이는 3종) + 기기 기본.
  static const options = <ThaiFont>[
    ThaiFont('sarabun', 'Sarabun', '사라분', '고리 있는 표준형 — 교과서·공문서 느낌, 글자 모양 익히기 좋아요'),
    ThaiFont('kanit', 'Kanit', '깐잇', '고리 없는 현대형 — 간판·광고·SNS 느낌'),
    ThaiFont('baijamjuree', 'BaiJamjuree', '바이짬쭈리', '부드러운 손글씨 느낌 — 분위기 전환용'),
    ThaiFont('system', null, '기기 기본', '폰에 들어 있는 태국어 글꼴'),
  ];

  static final ValueNotifier<String> id = ValueNotifier('sarabun'); // 기본 = 고리형(초보에게 유리, Grok 추천)

  static ThaiFont get current => options.firstWhere((o) => o.id == id.value, orElse: () => options.first);
  static String? get family => fontFamilyOf(current.family); // 통합 앱이면 packages/thai_universe/ 접두

  static Future<void> load() async {
    final v = (await Prefs.getInstance()).getString(_k);
    if (v != null && options.any((o) => o.id == v)) id.value = v;
  }

  /// 다음 글꼴로(회화 화면 앱바의 글꼴 버튼 — 바로 바꿔 보기).
  static Future<void> next() {
    final i = options.indexWhere((o) => o.id == id.value);
    return set(options[(i + 1) % options.length].id);
  }

  static Future<void> set(String v) async {
    id.value = v;
    (await Prefs.getInstance()).setString(_k, v);
  }
}
