import 'package:flutter/material.dart';

import '../core/backend.dart';
import '../screens/paywall_screen.dart';
import 'account.dart';
import 'purchase.dart';

/// 이용권 — Talkverse 계정 이용권(lang 'th') OR 스토어 구매(언어 `lang_th_*` · 종합 `all_*`, 구독은 기한 안). 일본어앱 방식(2026-11-09 가격표).
/// 태국어앱은 아직 잠근 콘텐츠가 없다(출시 때 무료 구간 결정) — 잠글 때 `Entitlement.premium` 을 보고 `showPaywall` 을 띄운다.
class Entitlement {
  Entitlement._();

  static bool get premium => Account.has(Backend.appLang) || Purchase.owns(Backend.appLang);

  /// 가격 = ~/talkverse/PRICING.md 앱 할인가(정가). 실제 가격은 스토어 등록값이 우선.
  static Future<void> configure() => Purchase.configure(Backend.appLang, const [
        Plan('lang_th_1m', 1, 3900, listKrw: 5500),
        Plan('lang_th_3m', 3, 9000, listKrw: 12900),
        Plan('lang_th_1y', 12, 19900, listKrw: 28500),
        Plan('lang_th_life', 0, 49000, listKrw: 69900),
        Plan('all_1y', 12, 79000, listKrw: 112900, bundle: true),
        Plan('all_life', 0, 329000, listKrw: 469000, bundle: true),
      ]);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
