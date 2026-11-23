import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_universe/services/curriculum_service.dart';

/// 커리큘럼 §12 — 단계 목록·편 목록은 데이터(서버 → 묶음 → 회화 레벨 대응), 앱에 없는 편 건너뜀, 빈 단계 숨김.
void main() {
  test('옛 R 레벨은 단계로 바꿔 읽고, 저장은 단계 번호', () {
    expect(stageKey('R0'), '1');
    expect(stageKey('R1'), '1');
    expect(stageKey('R2'), '2');
    expect(stageKey(4), '4');
    expect(stageKey('3'), '3');
    expect(stageKey('x'), isNull);
    final st = CurriculumState.fromJson({'level': 'R3'});
    expect(st.level, '3');
    expect(st.toJson()['level'], 3);
  });

  test('묶음 기본값 형식', () {
    expect(parsePlan('{}'), isNull);
    final p = parsePlan('{"rev":2,"stages":[{"n":2,"title":"둘","dialogueIds":["b"]},{"n":1,"dialogueIds":["a"]}]}')!;
    expect(p.$1, 2);
    expect(p.$2.map((s) => s.n), [1, 2]);
    expect(p.$2.first.title, '1단계');
  });

  test('단계의 고를 개수·통과 점수·하루 분량도 데이터에서, 없으면 기본값', () {
    final p = parsePlan('{"rev":1,"stages":[{"n":1,"dialogueIds":["a"],"pick":[2,4],"pass":70,"daily":{"light":2,"normal":3,"focus":5}},{"n":2,"dialogueIds":["b"]}]}')!.$2;
    expect(p[0].pick, [2, 4]);
    expect(p[0].pass, 70);
    expect(p[0].daily, [2, 3, 5]);
    expect(p[1].pick, [3, 5, 10]);
    expect(p[1].pass, 80);
    expect(p[1].daily, [1, 2, 3]);
    // 통과 점수 70 → 7/10 통과
    final st = CurriculumState(course: Course('c', ['a']));
    expect(st.recordExam(7, 10, {}, '2026-11-23', pass: 70), isTrue);
    // 하루 새 편 수 = daily[dailyGoal-1]
    final d = CurriculumState(dailyGoal: 3)..dailyN = p[0].daily;
    expect(d.newLeft('2026-11-23'), 5);
  });

  testWidgets('서버 판이 더 높으면 그것 — 앱에 없는 편은 건너뛰고 빈 단계는 숨김, 단계가 빠지면 사라짐', (t) async {
    String plan(int rev, Map<int, List<String>> m) => json.encode({
          'rev': rev,
          'stages': [for (final e in m.entries) {'n': e.key, 'title': '${e.key}단계', 'dialogueIds': e.value}],
          'prep': [],
        });
    SharedPreferences.setMockInitialValues({
      'th_curriculum_plan': plan(99, {
        1: ['r0_friends_a1', 'nope'],
        2: ['nope'],
        3: ['r0_friends_a2'],
      }),
    });
    final svc = CurriculumService.instance;
    await t.runAsync(svc.ensureLoaded);
    expect(svc.planRev, 99);
    expect(svc.stages.map((s) => s.key), ['1', '3']);
    expect(svc.stage('1')!.dialogueIds, ['r0_friends_a1']);
    expect(svc.levelList('3').single.id, 'r0_friends_a2');
    expect(svc.nextLevel('1'), '3');

    // 낮은 rev 는 무시
    svc.fetch = (_) async => plan(50, {1: ['r0_friends_a1']});
    expect(await t.runAsync(svc.refreshPlan), isFalse);
    expect(svc.stages.length, 2);
    // 서버에서 3단계를 빼면 사라짐
    svc.fetch = (_) async => plan(100, {1: ['r0_friends_a1', 'r0_friends_a2']});
    expect(await t.runAsync(svc.refreshPlan), isTrue);
    expect(svc.stages.map((s) => s.key), ['1']);
    expect(svc.nextLevel('1'), isNull);
    // 서버 못 받음 → 그대로
    svc.fetch = (_) async => null;
    expect(await t.runAsync(svc.refreshPlan), isFalse);
    expect(svc.planRev, 100);
  });
}
