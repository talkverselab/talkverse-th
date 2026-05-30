import 'package:flutter/material.dart';

/// 태국어유니버스 — 방콕 모던 테마.
///
/// 방콕의 현대적 브랜딩(쏨땀 핑크, 사원 골드, 트로피컬 틸)을 참고한 팔레트.
/// 난초(태국 국화)의 마젠타를 메인으로, 사원/승복의 사프란 골드와
/// 차오프라야강·트로피컬 무드의 틸을 포인트로 사용한다.
class AppTheme {
  // 메인 브랜드 — 방콕 모던 마젠타/핑크 (난초·네온 사인 무드)
  static const brand = Color(0xFFE6007E);
  // 사프란 골드 — 사원·승복·왕실 무드 강조
  static const gold = Color(0xFFF7B500);
  // 트로피컬 틸 — 차오프라야강·모던 카페 포인트
  static const teal = Color(0xFF12B5A5);
  // 딥 인디고 — 방콕 야경/대비 텍스트
  static const indigo = Color(0xFF2A1A4A);

  // 자음 3분류 컬러 코드 (고/중/저)
  static const classMid = Color(0xFF12B5A5); // 중자음 — 틸
  static const classHigh = Color(0xFFE6007E); // 고자음 — 마젠타
  static const classLow = Color(0xFFF7900E); // 저자음 — 오렌지

  // 홈 배경 그라데이션 (웜 핑크 크림 → 라이트)
  static const bgTop = Color(0xFFFFF0F7);
  static const bgBottom = Color(0xFFFFF9F2);

  static const _fontFallback = <String>[
    'Noto Sans Thai',
    'Leelawadee UI',
    'Noto Sans',
    'Noto Sans KR',
    'Segoe UI',
    'Malgun Gothic',
  ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    ).copyWith(secondary: teal, tertiary: gold);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFBF7),
      fontFamilyFallback: _fontFallback,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
    ).copyWith(secondary: teal, tertiary: gold);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamilyFallback: _fontFallback,
    );
  }
}
