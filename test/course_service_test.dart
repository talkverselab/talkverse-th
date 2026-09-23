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
    required String level,
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
        'q3b_level': level,
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

  test('겉은 일, 속은 설렘(중급) → 거래처 저녁 1·2편이 맨 앞, 초급 한 편이 이어서', () async {
    final svc = CourseService.instance;
    await svc.saveAnswers(answers(
        me: 'm', domains: ['work'], level: 'mid', moment: 'a', scene: 'a', friend: 'a', stage: 'first',
        style: 'direct', persona: 'mature', conflict: 'polite', reg: 'polite', alcohol: 'yes', heat: 'hot'));
    final ids = [for (final e in svc.playlist()) e.$2.id];
    expect(ids.take(4), [
      'work.romance.dinner#1@mf',
      'work.romance.dinner#2@mf',
      'work.romance.intro#1@mf',
      'work.status.senior#1@m',
    ]);
    expect(ids.length, 12);
    expect(ids.every((id) => id.startsWith('work.')), isTrue, reason: '고른 무대만 나온다');
    expect(svc.topDrive(), 'romance');
  });

  test('초급 여행자: 초급이 앞, 고급은 안 나옴, 술 제외·순한 맛', () async {
    final svc = CourseService.instance;
    await svc.saveAnswers(answers(
        me: 'm', domains: ['trip', 'move'], level: 'beg', moment: 'b', scene: 'b', friend: 'b', stage: 'first',
        style: 'joke', persona: 'playful', conflict: 'laugh', reg: 'polite', alcohol: 'no', heat: 'mild'));
    final list = svc.playlist();
    expect(list.first.$2.id, 'trip.win.market#1@m');
    expect(list[1].$2.id, 'move.win.meter#1@m');
    expect(list.every((e) => e.$2.level != 'adv'), isTrue);
    expect(list.every((e) => !e.$2.flags.contains('alcohol') && e.$2.heat <= 2), isTrue);
  });

  test('옛 도메인 답(biz·chat)은 새 무대로 옮겨진다', () async {
    final svc = CourseService.instance;
    await svc.saveAnswers(answers(
        me: 'm', domains: ['biz', 'chat'], level: 'mid', moment: 'a', scene: 'a', friend: 'a', stage: 'first',
        style: 'direct', persona: 'mature', conflict: 'polite', reg: 'polite', alcohol: 'yes', heat: 'hot'));
    expect(svc.domains, ['work', 'phone']);
  });

  test('여자 학습자 × 남자 상대 판(고급) + 회차 잠금', () async {
    final svc = CourseService.instance;
    await svc.saveAnswers(answers(
        me: 'f', partner: 'm', domains: ['phone', 'night'], level: 'adv', moment: 'a', scene: 'd', friend: 'a', stage: 'ex',
        style: 'indirect', persona: 'tsundere', conflict: 'escape', reg: 'casual', alcohol: 'yes', heat: 'hot'));
    final list = [for (final e in svc.playlist()) e.$2];
    expect(list.first.id, 'phone.romance.ex#1@fm');
    expect(list.every((s) => s.variant == 'f' || s.variant == 'fm'), isTrue);
    expect(list.every((s) => s.level != 'beg'), isTrue);
    expect(list.first.voices, {'A': 'f', 'B': 'm'});

    final ep1 = list.firstWhere((s) => s.id == 'night.romance.rooftop#1@fm');
    final ep2 = list.firstWhere((s) => s.id == 'night.romance.rooftop#2@fm');
    expect(svc.isUnlocked(ep2), isFalse);
    await svc.markDone(ep1);
    expect(svc.isUnlocked(ep2), isTrue);
  });
}
