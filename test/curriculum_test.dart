import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:thai_universe/services/curriculum_service.dart';

void main() {
  group('점수 80% 경계', () {
    test('소수점 버림', () {
      expect(scorePercent(2, 3), 66);
      expect(scorePercent(0, 0), 0);
    });
    test('80% 이상만 통과', () {
      expect(isPass(8, 10), isTrue);
      expect(isPass(7, 10), isFalse);
      expect(isPass(24, 30), isTrue); // 80
      expect(isPass(23, 30), isFalse); // 76.6 → 76
      expect(isPass(4, 5), isTrue);
      expect(isPass(11, 14), isFalse); // 78.5 → 78
    });
  });

  group('간격 반복 1·3·7일', () {
    const day = '2026-11-22';
    test('넣으면 다음 날', () {
      final s = CurriculumState()..enqueue('d#1', day);
      expect(s.review.single.due, '2026-11-23');
      expect(s.dueOn(day), isEmpty);
      expect(s.dueOn('2026-11-23').length, 1);
    });
    test('맞히면 3일 → 7일 → 졸업, 틀리면 1일로', () {
      final s = CurriculumState()..enqueue('d#1', day);
      s.answerReview('d#1', true, '2026-11-23');
      expect(s.review.single.due, '2026-11-26');
      s.answerReview('d#1', true, '2026-11-26');
      expect(s.review.single.due, '2026-12-03'); // 달 넘김
      s.answerReview('d#1', false, '2026-12-03');
      expect(s.review.single.due, '2026-12-04');
      expect(s.review.single.step, 0);
      s.answerReview('d#1', true, '2026-12-04');
      s.answerReview('d#1', true, '2026-12-07');
      s.answerReview('d#1', true, '2026-12-14');
      expect(s.review, isEmpty);
    });
    test('연습한 편 줄은 이미 있는 간격을 건드리지 않음', () {
      final s = CurriculumState()..enqueue('d#1', day);
      s.answerReview('d#1', true, '2026-11-23');
      s.enqueueIfAbsent('d#1', '2026-11-24');
      expect(s.review.single.due, '2026-11-26');
    });
  });

  group('하루 분량 · 연속 일수', () {
    test('목표 채우고 복습 0이면 끝, 연속 일수', () {
      final s = CurriculumState(dailyGoal: 1)..rollDay('2026-11-22');
      expect(s.dailyDone('2026-11-22'), isFalse);
      s.todayNew.add('a');
      s.touchStreak('2026-11-22');
      expect(s.streakCount, 1);
      s.rollDay('2026-11-23');
      s.todayNew.add('b');
      s.touchStreak('2026-11-23');
      expect(s.streakCount, 2);
      s.rollDay('2026-11-25');
      s.todayNew.add('c');
      s.touchStreak('2026-11-25');
      expect(s.streakCount, 1);
    });
  });

  test('시험 편당 문제 수: 최소 3, 최대 30', () {
    expect(examPerDialogue(3), 10);
    expect(examPerDialogue(5), 6);
    expect(examPerDialogue(10), 3);
  });

  test('문제: 정답 1 + 오답 3', () {
    final lines = [for (var i = 0; i < 5; i++) QuizLine('d#$i', 'd', 'th$i', '', 'ko$i')];
    final qs = buildQuestions(lines, [for (var i = 0; i < 8; i++) 'ko$i'], rnd: Random(1));
    expect(qs.length, 5);
    for (final q in qs) {
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4);
      expect(q.options[q.answer], 'ko${q.lineId.split('#').last}');
    }
  });

  test('저장 형식 왕복(curriculum_v1)', () {
    final s = CurriculumState(level: 'R1', dailyGoal: 3)
      ..course = CurriculumCourse(id: 'c1', dialogueIds: ['a', 'b'], practiced: ['a'], examScores: [70])
      ..passedDialogues.add('z')
      ..enqueue('a#1', '2026-11-22');
    final j = s.toJson();
    expect(j.keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    final r = CurriculumState.fromJson(j);
    expect(r.level, 'R1');
    expect(r.course!.practiced, ['a']);
    expect(r.course!.allPracticed, isFalse);
    expect(r.review.single.lineId, 'a#1');
  });
}
