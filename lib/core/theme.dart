import 'package:flutter/material.dart';

/// 태국풍 컬러 팔레트 — 방콕 모던.
///
/// 난초(กล้วยไม้)의 마젠타를 메인으로, 사원·승복의 골드(ทอง),
/// 에메랄드 사원(มรกต)의 틸, 방콕 야경의 인디고(คราม)를 조합한다.
class AppColors {
  // 主色 — 난초 마젠타 (กล้วยไม้, 태국 국화·방콕 네온)
  static const Color kluayMai = Color(0xFFE6007E);
  static const Color kluayMaiDeep = Color(0xFFA80058);
  static const Color kluayMaiLight = Color(0xFFFF4DA6);

  // 副色 — 골드 (ทอง, 왓 아룬·사원 금박·승복 사프란)
  static const Color thong = Color(0xFFDBA514);
  static const Color thongBright = Color(0xFFF7C948);
  static const Color thongDeep = Color(0xFF8F6A0A);

  // 인디고 (คราม, 방콕 야경·짙은 텍스트)
  static const Color khram = Color(0xFF241A3E);
  static const Color khramLight = Color(0xFF544A6E);

  // 크림 (실크·코코넛 크림 배경)
  static const Color cream = Color(0xFFFFF8EE);
  static const Color creamDeep = Color(0xFFF4E8D2);

  // 에메랄드 (มรกต, 에메랄드 사원·보조 강조)
  static const Color morakot = Color(0xFF0FA98E);

  // 자음 3분류 컬러 (고/중/저)
  static const Color classHigh = Color(0xFFE6007E); // 고자음 — 마젠타
  static const Color classMid = Color(0xFF0FA98E); // 중자음 — 에메랄드
  static const Color classLow = Color(0xFFF7900E); // 저자음 — 오렌지

  // 5성조 컬러 (시각 학습용)
  static const Color toneMid = Color(0xFF8E8579); // 평성 สามัญ — 회색
  static const Color toneLow = Color(0xFF1E88E5); // 저성 เอก — 파랑
  static const Color toneFalling = Color(0xFFE53935); // 하성 โท — 빨강
  static const Color toneHigh = Color(0xFFFB8C00); // 고성 ตรี — 주황
  static const Color toneRising = Color(0xFF43A047); // 상성 จัตวา — 초록

  // brand alias
  static const Color brand = kluayMai;
}

class AppTheme {
  static const fontFallback = <String>[
    'Noto Sans Thai',
    'Leelawadee UI',
    'Noto Sans',
    'Noto Sans KR',
    'Segoe UI',
    'Malgun Gothic',
  ];

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.kluayMai,
        onPrimary: AppColors.cream,
        primaryContainer: AppColors.kluayMaiLight,
        onPrimaryContainer: AppColors.khram,
        secondary: AppColors.thong,
        onSecondary: AppColors.khram,
        secondaryContainer: AppColors.thongBright,
        onSecondaryContainer: AppColors.khram,
        tertiary: AppColors.morakot,
        onTertiary: AppColors.cream,
        tertiaryContainer: const Color(0xFFB7E4D8),
        onTertiaryContainer: AppColors.khram,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: AppColors.cream,
        onSurface: AppColors.khram,
        surfaceContainerHighest: AppColors.creamDeep,
        onSurfaceVariant: AppColors.khramLight,
        outline: AppColors.thongDeep,
        outlineVariant: const Color(0xFFE2D3AE),
      ),
      scaffoldBackgroundColor: AppColors.cream,
      fontFamilyFallback: fontFallback,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.kluayMai,
        foregroundColor: AppColors.cream,
        titleTextStyle: TextStyle(
          color: AppColors.cream,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamilyFallback: fontFallback,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.thong, width: 0.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.khram,
        indicatorColor: AppColors.kluayMai,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.thongBright : AppColors.creamDeep,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.cream : AppColors.creamDeep,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.creamDeep,
        labelStyle:
            const TextStyle(color: AppColors.khram, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.thong),
        selectedColor: AppColors.kluayMai,
        secondaryLabelStyle: const TextStyle(color: AppColors.cream),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.thong,
        thickness: 0.5,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.kluayMai,
        textColor: AppColors.khram,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kluayMai,
        brightness: Brightness.dark,
      ),
      fontFamilyFallback: fontFallback,
    );
  }
}

/// 5성조 컬러 (tone id: mid/low/falling/high/rising)
Color toneColor(String? toneId) {
  switch (toneId) {
    case 'mid':
      return AppColors.toneMid;
    case 'low':
      return AppColors.toneLow;
    case 'falling':
      return AppColors.toneFalling;
    case 'high':
      return AppColors.toneHigh;
    case 'rising':
      return AppColors.toneRising;
    default:
      return AppColors.khramLight;
  }
}

/// 자음 분류 컬러 (cls: high/mid/low)
Color consonantClassColor(String? cls) {
  switch (cls) {
    case 'high':
      return AppColors.classHigh;
    case 'mid':
      return AppColors.classMid;
    case 'low':
      return AppColors.classLow;
    default:
      return AppColors.khramLight;
  }
}
