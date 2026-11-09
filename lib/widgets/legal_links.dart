import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

/// 이용약관·개인정보처리방침 주소(uk 공통, 2026-11-09). 결제 화면·로그인·설정에서 같은 링크를 쓴다.
class Legal {
  Legal._();
  static const terms = 'https://talkverse.uk/terms/';
  static const privacy = 'https://talkverse.uk/talkverse/th/privacy/';
  static Future<void> open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// 「이용약관 · 개인정보처리방침」 한 줄 링크.
class LegalLinks extends StatelessWidget {
  final String? lead;
  const LegalLinks({super.key, this.lead});
  @override
  Widget build(BuildContext context) {
    const link = TextStyle(fontSize: 12, color: AppColors.thai, fontWeight: FontWeight.w700, decoration: TextDecoration.underline);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (lead != null) Text(lead!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.khramLight, height: 1.45)),
      Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        TextButton(onPressed: () => Legal.open(Legal.terms), child: Text(tr('이용약관'), style: link)),
        const Text('·', style: TextStyle(color: AppColors.khramLight)),
        TextButton(onPressed: () => Legal.open(Legal.privacy), child: Text(tr('개인정보처리방침'), style: link)),
      ]),
    ]);
  }
}
