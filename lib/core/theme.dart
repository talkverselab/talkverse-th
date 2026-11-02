import 'package:flutter/material.dart';

/// 컬러 팔레트 — 「사원 노을 실크」(2026-11-02, 사용자 지시 "일반적인 태국 느낌, 부드럽고 따뜻하게" → Grok 제안).
///
/// 사원 지붕 금빛이 노을에 물든 색 + 실크 광택 + 망고·파파야의 은은한 색. 낮은 채도·웜톤, 본문 대비 AA.
/// 이름(kluayMai·thong·khram…)은 옛 팔레트에서 온 것이라 화면 코드가 그대로 쓰고 값만 바꾼다.
/// 자음 분류·성조 색은 학습용이라 그대로 둔다.
class AppColors {
  // 주색 — 사원 금빛(primary)
  static const Color kluayMai = Color(0xFFC48A4A);
  static const Color kluayMaiDeep = Color(0xFF9A6830); // primaryDeep — 눌림·진한 강조 글자, 흰 글자 바탕
  static const Color kluayMaiLight = Color(0xFFF4E4C8); // primaryLight — 연한 강조 바탕·칩

  // 보조 — 노을 테라코타(secondary)
  static const Color sunset = Color(0xFFD48A6A);
  static const Color sunsetDeep = Color(0xFFA85A3A);

  // 테두리·밝은 강조·보조 글자 (옛 골드 자리)
  static const Color thong = Color(0xFFE6DCD0); // line
  static const Color thongBright = Color(0xFFE8B48A); // secondaryBright
  static const Color thongDeep = Color(0xFF7A6B60); // muted

  // 글자 — ink / body
  static const Color khram = Color(0xFF3A2F28);
  static const Color khramLight = Color(0xFF5A4A40);

  // 바탕 — background / surfaceSoft (카드는 흰색)
  static const Color cream = Color(0xFFFFF8F3);
  static const Color creamDeep = Color(0xFFF7F0E8);

  // 완료·학습됨 — accentCalm
  static const Color morakot = Color(0xFF6A9B78);

  // 회화 버블 — 학습자(A) · 상대(B)
  static const Color bubbleA = Color(0xFFFDE8D4);
  static const Color bubbleAText = Color(0xFF5A3E28);
  static const Color bubbleB = Color(0xFFF5E0D4);
  static const Color bubbleBText = Color(0xFF4A3A32);

  // 오늘의 학습 카드 · 홈 상단 그라데이션
  static const List<Color> todayCard = [Color(0xFFF4E4C8), Color(0xFFE8B48A)];
  static const List<Color> homeHeader = [Color(0xFFFFF8F3), Color(0xFFF4E4C8), Color(0xFFFDE8D4)];

  // 메뉴 타일 배지 12색(같은 따뜻한 톤 안에서 구별)
  static const List<Color> badges = [
    Color(0xFFC48A4A), Color(0xFFD48A6A), Color(0xFFE0A070), Color(0xFFB87A5A),
    Color(0xFFA67C3A), Color(0xFF6A9B78), Color(0xFFC4A05A), Color(0xFFD4B070),
    Color(0xFFA85A4A), Color(0xFF8A7A6A), Color(0xFFE8C090), Color(0xFFB09070),
  ];

  // 태국어 카드색 — talkverse.uk 언어 카드의 `--c` (언어 배지 한 곳에만)
  static const Color thai = Color(0xFF3F9FD6);

  /// 배지·채운 바탕 위 글자색 — 밝은 바탕이면 진한 글자, 어두우면 흰 글자.
  static Color onFill(Color bg) => bg.computeLuminance() > 0.35 ? khram : Colors.white;

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
        secondary: AppColors.sunset,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.thongBright,
        onSecondaryContainer: AppColors.khram,
        tertiary: AppColors.morakot,
        onTertiary: AppColors.cream,
        tertiaryContainer: const Color(0xFFDDEBE0),
        onTertiaryContainer: AppColors.khram,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: Colors.white,
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
        color: Colors.white,
        shadowColor: const Color(0x1A5A3E28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.thong, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.kluayMaiLight,
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
