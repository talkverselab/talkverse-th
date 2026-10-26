import 'package:flutter/material.dart';

/// 컬러 팔레트 — talkverse.uk 톤(2026-10-26).
///
/// 흰 바탕 + 남색 글자 + 인디고 포인트 하나, 그 밖의 색은 절제한다.
/// 이름(kluayMai·thong·khram…)은 옛 "방콕 모던" 팔레트에서 온 것이라
/// 화면 코드가 그대로 쓰고, 값만 사이트 토큰(`--ink`·`--body`·`--accent`…)에 맞췄다.
/// 자음 분류·성조 색은 학습용이라 그대로 둔다.
class AppColors {
  // 주색 — 사이트 `--accent` 인디고
  static const Color kluayMai = Color(0xFF635BFF);
  static const Color kluayMaiDeep = Color(0xFF4B44D6); // `--accent-ink`
  static const Color kluayMaiLight = Color(0xFFA9A4FF);

  // 보조 — 옛 골드 자리. 테두리는 사이트 `--line` 계열, 밝은 강조는 히어로 피치
  static const Color thong = Color(0xFFDDE3EC);
  static const Color thongBright = Color(0xFFFFD39B);
  static const Color thongDeep = Color(0xFF6B7C93); // `--muted`

  // 글자 — `--ink` / `--body`
  static const Color khram = Color(0xFF0A2540);
  static const Color khramLight = Color(0xFF425466);

  // 바탕 — 흰색 / `--soft`
  static const Color cream = Color(0xFFFFFFFF);
  static const Color creamDeep = Color(0xFFF6F9FC);

  // 보조 강조 — 차분한 청록(완료·학습됨)
  static const Color morakot = Color(0xFF0E7C8C);

  // 태국어 카드색 — talkverse.uk 언어 카드의 `--c` (언어 배지 한 곳에만)
  static const Color thai = Color(0xFF3F9FD6);

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
    'Noto Sans Thai', // Android
    'Thonburi', // iOS 태국어
    'Leelawadee UI', // Windows
    'Noto Sans',
    'Noto Sans KR', // Android 한국어
    'Apple SD Gothic Neo', // iOS 한국어
    'Segoe UI',
    'Malgun Gothic',
  ];

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.kluayMai,
        onPrimary: Colors.white,
        primaryContainer: AppColors.kluayMaiLight,
        onPrimaryContainer: AppColors.khram,
        secondary: AppColors.khramLight,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.thongBright,
        onSecondaryContainer: AppColors.khram,
        tertiary: AppColors.morakot,
        onTertiary: AppColors.cream,
        tertiaryContainer: const Color(0xFFCDEFF2),
        onTertiaryContainer: AppColors.khram,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: AppColors.cream,
        onSurface: AppColors.khram,
        surfaceContainerHighest: AppColors.creamDeep,
        onSurfaceVariant: AppColors.khramLight,
        outline: AppColors.thongDeep,
        outlineVariant: AppColors.thong,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      fontFamilyFallback: fontFallback,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.khramLight,
        displayColor: AppColors.khram,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.khram,
        shape: Border(bottom: BorderSide(color: AppColors.thong, width: 1)),
        titleTextStyle: TextStyle(
          color: AppColors.khram,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          fontFamilyFallback: fontFallback,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cream,
        shadowColor: const Color(0x1A32325D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.thong, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFEFEEFE),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.kluayMai : AppColors.thongDeep,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.kluayMai : AppColors.thongDeep,
            size: 24,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.khram,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.khram,
          side: const BorderSide(color: AppColors.thong),
          shape: const StadiumBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.creamDeep,
        labelStyle:
            const TextStyle(color: AppColors.khram, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.thong),
        shape: const StadiumBorder(),
        selectedColor: AppColors.kluayMai,
        secondaryLabelStyle: const TextStyle(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.thong,
        thickness: 1,
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
