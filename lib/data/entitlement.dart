import 'package:flutter/material.dart';

import '../core/backend.dart';
import '../screens/paywall_screen.dart';
import 'account.dart';
import 'purchase.dart';

/// 이용권 — Talkverse 계정 이용권(lang 'th', auth.talkverse.uk) OR 이 기기에서 산·복원한 평생 이용권(스토어). 한자 앱 entitlement.dart 와 같은 규칙.
/// 태국어앱은 아직 잠근 콘텐츠가 없다(무료/유료 구간 미정) — 잠글 때 화면에서 `Entitlement.premium` 을 보고 `showPaywall` 을 띄운다.
class Entitlement {
  Entitlement._();
  static const iosProduct = 'com.talkverse.thaiUniverse.lifetime';
  static const androidProduct = 'lang_th';

  static bool get premium => Account.has(Backend.appLang) || Purchase.owns(Backend.appLang);

  static Future<void> configure() => Purchase.configure({Backend.appLang: (iosProduct, androidProduct)});

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
