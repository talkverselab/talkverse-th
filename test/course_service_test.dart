import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_universe/services/course_service.dart';

/// 재생 목록이 기준 구현(drafts/script_engine/select_playlist.py)과 같은 순서로 나오는지.
/// 아래 기대값은 그 스크립트의 DEMO 프로필 출력이다 — 카탈로그를 고치면 같이 갱신한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> answers({
    required String me,
    String partner = 'any',
    required List<String> domains,
    required String moment,
    required String scene,
    required String friend,
    required String stage,
    required String style,
    required String persona,
    required String conflict,
    required String reg,
    required String alcohol,
    required String heat,
  }) =>
      {
        'q1_me': me,
        'q2_partner': partner,
        'q3_domain': domains,
        'q4_moment': moment,
        'q5_scene': scene,
        'q6_friend': friend,
        'q7_stage': stage,
        'q8_style': style,
        'q9_persona': persona,
        'q10_conflict': conflict,
        'q11_reg': reg,
        'q12_alcohol': alcohol,
        'q13_heat': heat,
      };

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await CourseService.instance.ensureLoaded();
  });

  test('겉은 출장, 속은 설렘 → 거래처 저녁 1·2편이 맨 앞', () async {
    final svc = CourseService.instance;
    await svc.saveAnswers(answers(
        me: 'm', domains: ['biz'], moment: 'a', scene: 'a', friend: 'a', stage: 'first',
        style: 'direct', persona: 'mature', conflict: 'polite', reg: 'polite', alcohol: 'yes', heat: 'hot'));
    final ids = [for (final e in svc.playlist()) e.$2.id];
    expect(ids.take(5), [
      'biz.romance.dinner#1@mf',
      'biz.romance.dinner#2@mf',
      'stay.romance.elevator#1@mf',
      'stay.romance.elevator#2@mf',
      'stay.romance.teacher#1@mf',
    ]);
    expect(ids.length, 16);
    expect(svc.topDrive(), 'romance');
  });

  test('술 제외·순한 맛 필터와 웃어넘김 우선', () async {
    final svc = CourseService.instance;
    await svc.saveAnswers(answers(
        me: 'm', domains: ['travel', 'stay'], moment: 'b', scene: 'b', friend: 'b', stage: 'first',
        style: 'joke', persona: 'playful', conflict: 'laugh', reg: 'polite', alcohol: 'no', heat: 'mild'));
    final list = svc.playlist();
    expect(list.first.$2.id, 'travel.win.tout#1@m');
    expect(list.every((e) => !e.$2.flags.contains('alcohol') && e.$2.heat <= 2), isTrue);
  });

  test('여자 학습자 × 남자 상대 판 + 회차 잠금', () async {
    final svc = CourseService.instance;
    await svc.saveAnswers(answers(
        me: 'f', partner: 'm', domains: ['chat', 'night'], moment: 'a', scene: 'd', friend: 'a', stage: 'ex',
        style: 'indirect', persona: 'tsundere', conflict: 'escape', reg: 'casual', alcohol: 'yes', heat: 'hot'));
    final list = [for (final e in svc.playlist()) e.$2];
    expect(list.first.id, 'chat.romance.ex#1@fm');
    expect(list.every((s) => s.variant == 'f' || s.variant == 'fm'), isTrue);
    expect(list.first.voices, {'A': 'f', 'B': 'm'});

    final ep1 = list.firstWhere((s) => s.id == 'night.romance.rooftop#1@fm');
    final ep2 = list.firstWhere((s) => s.id == 'night.romance.rooftop#2@fm');
    expect(svc.isUnlocked(ep2), isFalse);
    await svc.markDone(ep1);
    expect(svc.isUnlocked(ep2), isTrue);
  });
}
