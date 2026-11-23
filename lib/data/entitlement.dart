import 'package:flutter/material.dart';

import '../core/backend.dart';
import '../screens/paywall_screen.dart';
import '../services/curriculum_service.dart';
import 'account.dart';
import 'purchase.dart';

/// 이용권 — Talkverse 계정 이용권(lang 'th') OR 스토어 구매(언어 `lang_th_*` · 종합 `all_*`, 구독은 기한 안). 일본어앱 방식(2026-11-09 가격표).
/// 범위 = `~/talkverse/PAYWALL_SPEC.md`(11/23 사용자 「1 2 모두 진행」, 범위는 uk 의 정함):
/// 무료 = 커리큘럼 1단계·회화 R0·R1·글자/발음/단어 기본·문법 1~2스텝·언어감각 1급. 유료 = 그 밖. 단계 free·freeSteps·freeSenseLevels 는 서버 커리큘럼 판(rev 2~).
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

  /// 회화 목록의 편 — 1단계(R0·R1)만 무료.
  static bool dialogueFree(String region) => region == 'R0' || region == 'R1';

  /// 문법 스텝 n(1부터) — freeSteps(기본 2)까지 무료.
  static bool stepFree(int n) => n <= CurriculumService.instance.freeSteps;

  /// 언어감각 급 순번(1부터) — freeSenseLevels(기본 1)까지 무료.
  static bool senseLevelFree(int n) => n <= CurriculumService.instance.freeSenseLevels;

  /// 잠겨 있으면 결제 화면을 띄우고, 닫힌 뒤 열렸는지(true = 지나가도 됨)를 돌려준다.
  static Future<bool> gate(BuildContext context, bool free) async {
    if (free || premium) return true;
    await PaywallScreen.show(context);
    return premium;
  }
}

/// 잠긴 칸의 작은 자물쇠(무엇을 사는지 보이게 숨기지 않는다 — 애플 3.1.1).
class LockBadge extends StatelessWidget {
  final double size;
  const LockBadge({super.key, this.size = 16});
  @override
  Widget build(BuildContext context) => Icon(Icons.lock_outline, size: size, color: const Color(0xFF9A5F38));
}
