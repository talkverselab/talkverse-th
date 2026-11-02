import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/thai_font.dart';
import '../core/theme.dart';

/// 앱바 글꼴 버튼 — 누를 때마다 태국어 글꼴이 바뀐다(사라분 → 깐잇 → 바이짬쭈리 → 기기 기본). 버튼의 「ก」가 지금 글꼴로 보인다.
class ThaiFontAction extends StatelessWidget {
  const ThaiFontAction({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: ThaiFontPrefs.id,
        builder: (context, _, _) {
          final f = ThaiFontPrefs.current;
          return IconButton(
            tooltip: trf('태국어 글꼴: {0}', [tr(f.label)]),
            onPressed: () async {
              await ThaiFontPrefs.next();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  duration: const Duration(milliseconds: 1400),
                  content: Text(trf('태국어 글꼴: {0}', [tr(ThaiFontPrefs.current.label)])),
                ));
            },
            icon: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.kluayMai, width: 1.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('ก', style: TextStyle(fontFamily: f.family, fontSize: 18, height: 1.1, color: AppColors.kluayMaiDeep)),
            ),
          );
        },
      );
}
