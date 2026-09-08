import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import 'tone_service.dart';

/// 독음 표시 방식 — 한글 / 한글+성조 / 로마자(우리 표기)+성조 / 숨김.
enum ReadingStyle { ko, koTone, roman, off }

/// 독음(발음 표기) 전역 설정 — 모든 메뉴 공용.
/// 성조·로마자 표시는 `ToneService`(th_tones.json) 가 해당 문자열을 알 때만 가능하며,
/// 모르면 원래 한글 독음으로 표시한다.
class KoReadingPrefs {
  KoReadingPrefs._();

  static const _key = 'show_ko_reading';
  static const _styleKey = 'reading_style';

  /// 하위 호환: 표시 여부 (off 가 아니면 true).
  static final ValueNotifier<bool> show = ValueNotifier<bool>(true);
  static final ValueNotifier<ReadingStyle> style =
      ValueNotifier<ReadingStyle>(ReadingStyle.ko);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final idx = p.getInt(_styleKey);
    if (idx != null && idx >= 0 && idx < ReadingStyle.values.length) {
      style.value = ReadingStyle.values[idx];
    } else {
      style.value =
          (p.getBool(_key) ?? true) ? ReadingStyle.ko : ReadingStyle.off;
    }
    show.value = style.value != ReadingStyle.off;
    ToneService.instance.ensureLoaded();
  }

  static Future<void> set(ReadingStyle s) async {
    style.value = s;
    show.value = s != ReadingStyle.off;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_styleKey, s.index);
    await p.setBool(_key, show.value);
  }

  /// 한글 → 한글+성조 → 로마자 → 숨김 → 한글 … 순환.
  static Future<void> toggle() => set(ReadingStyle
      .values[(style.value.index + 1) % ReadingStyle.values.length]);

  static String label(ReadingStyle s) => switch (s) {
        ReadingStyle.ko => '한',
        ReadingStyle.koTone => '한ˊ',
        ReadingStyle.roman => 'ABC',
        ReadingStyle.off => '한',
      };

  static String tooltip(ReadingStyle s) => switch (s) {
        ReadingStyle.ko => '한글 독음 (탭: 성조 표시)',
        ReadingStyle.koTone => '한글 독음 + 성조 (탭: 로마자)',
        ReadingStyle.roman => '로마자 + 성조 (탭: 독음 숨기기)',
        ReadingStyle.off => '독음 숨김 (탭: 한글 독음)',
      };
}

/// 앱바용 독음 토글 버튼 — 한 / 한ˊ / ABC / 숨김 순환.
class KoReadingToggleAction extends StatelessWidget {
  const KoReadingToggleAction({super.key});

  @override
  Widget build(BuildContext context) {
    final base = IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return ValueListenableBuilder<ReadingStyle>(
      valueListenable: KoReadingPrefs.style,
      builder: (context, s, _) {
        final on = s != ReadingStyle.off;
        final color = on ? base : base.withValues(alpha: 0.35);
        return IconButton(
          tooltip: KoReadingPrefs.tooltip(s),
          onPressed: KoReadingPrefs.toggle,
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.2),
              borderRadius: BorderRadius.circular(6),
              color: s == ReadingStyle.ko || s == ReadingStyle.off
                  ? null
                  : color.withValues(alpha: 0.12),
            ),
            child: Text(
              KoReadingPrefs.label(s),
              style: TextStyle(
                fontSize: s == ReadingStyle.roman ? 11 : 14,
                fontWeight: FontWeight.w700,
                color: color,
                decoration: on ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 독음 텍스트 — 전역 설정에 따라 한글 / 한글+성조 / 로마자+성조 / 숨김.
/// `th` 를 주면 성조·로마자 모드에서 ToneService 값으로 바꿔 보여 준다.
class KoReadingText extends StatelessWidget {
  const KoReadingText(
    this.reading, {
    super.key,
    this.th,
    this.style,
    this.textAlign,
  });

  final String reading;
  final String? th;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ReadingStyle>(
      valueListenable: KoReadingPrefs.style,
      builder: (context, s, _) {
        if (s == ReadingStyle.off) return const SizedBox.shrink();
        if (s == ReadingStyle.ko || th == null) {
          return Text(reading, textAlign: textAlign, style: style);
        }
        final tr = ToneService.instance.lookup(th!);
        if (tr == null) {
          return Text(reading, textAlign: textAlign, style: style);
        }
        if (s == ReadingStyle.koTone) {
          return Text(tr.ko, textAlign: textAlign, style: style);
        }
        return RomanText(tr.ro, textAlign: textAlign, style: style);
      },
    );
  }
}

/// 우리 로마자 표기 렌더러 — `{..}` 구간을 밑줄(장음)로.
class RomanText extends StatelessWidget {
  const RomanText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? const TextStyle()).copyWith(
      fontFamilyFallback: AppTheme.fontFallback,
      decorationColor: style?.color,
      decorationThickness: 2,
    );
    final spans = <TextSpan>[];
    final re = RegExp(r'\{([^}]*)\}');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(decoration: TextDecoration.underline),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: textAlign,
    );
  }
}
