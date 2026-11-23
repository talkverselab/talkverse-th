import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_universe/data/entitlement.dart';
import 'package:thai_universe/data/purchase.dart';
import 'package:thai_universe/services/curriculum_service.dart';

/// 이용권 잠금 경계(PAYWALL_SPEC, 11-23) — 1단계 열림 · 2단계 잠김 · 문법 3스텝·언어감각 2급부터 잠김 · 이용권 있으면 열림.
void main() {
  testWidgets('잠금 경계와 이용권', (t) async {
    SharedPreferences.setMockInitialValues({
      'th_curriculum_plan': json.encode({
        'rev': 99,
        'freeSteps': 2,
        'freeSenseLevels': 1,
        'stages': [
          {'n': 1, 'dialogueIds': ['r0_friends_a1'], 'free': true},
          {'n': 2, 'dialogueIds': ['r0_friends_a2'], 'free': false},
          {'n': 3, 'dialogueIds': ['r0_friends_a3']},
        ],
        'prep': [],
      }),
    });
    final svc = CurriculumService.instance;
    await t.runAsync(svc.ensureLoaded);
    expect([svc.stageFree('1'), svc.stageFree('2'), svc.stageFree('3')], [true, false, false]);
    expect([Entitlement.dialogueFree('R0'), Entitlement.dialogueFree('R1'), Entitlement.dialogueFree('R2')], [true, true, false]);
    expect([Entitlement.stepFree(2), Entitlement.stepFree(3)], [true, false]);
    expect([Entitlement.senseLevelFree(1), Entitlement.senseLevelFree(2)], [true, false]);

    Purchase.owned.value = const {};
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = const {'lang_th_1m': 0}; // 이 언어 이용권
    expect(Entitlement.premium, isTrue);
    Purchase.owned.value = const {'all_life': 0}; // 종합 이용권
    expect(Entitlement.premium, isTrue);
    Purchase.owned.value = const {'lang_ja_life': 0}; // 다른 언어 것은 안 됨
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = {'lang_th_1m': DateTime(2000).millisecondsSinceEpoch}; // 기한 지남
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = const {};
  });
}
