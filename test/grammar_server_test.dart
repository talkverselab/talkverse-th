import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_universe/screens/sense_course_screen.dart';
import 'package:thai_universe/services/script_sync.dart';

String sha(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 12);

/// 문법 파트 서버 받기(사용자 지시 2026-11-23) — 서버 원고가 있으면 그것, 없으면 묶음 것 · 빈 스텝은 숨김.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('grammar_server'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  const lessons = 'grammar/lessons.json', sense = 'grammar/sense_course.json';
  const bundled = '{"lessons":[]}', server = '{"lessons":[{"id":"x","items":[1]}]}';

  test('서버 원고가 있으면 서버 것, 없으면 묶음 것', () async {
    final base = {
      'rev': 8,
      'files': {lessons: 'old', sense: 'same'},
    };
    // 서버 판 없음 → 묶음 것
    final none = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: base);
    expect(await none.refresh(), isFalse);
    expect(await none.loadOr('assets/data/$lessons', () async => bundled), bundled);

    // 서버 rev 9 에 문법 코스가 바뀜 → 서버 것
    Future<String?> fetch(String url) async {
      if (url.endsWith('/index.json')) {
        return json.encode({
          'rev': 9,
          'files': {lessons: sha(server), sense: 'same'},
        });
      }
      if (url.contains(lessons)) return server;
      return null;
    }

    final s = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: base);
    expect(await s.refresh(), isTrue);
    expect(s.has(lessons), isTrue);
    expect(s.has(sense), isFalse);
    expect(await s.loadOr('assets/data/$lessons', () async => bundled), server);
    expect(await s.loadOr('assets/data/$sense', () async => 'fallback'), 'fallback');
  });

  test('언어감각 스텝 — 목록·순서는 데이터에서, 회차 없는 스텝은 숨김', () {
    final d = {
      'levels': [
        for (var i = 1; i <= 10; i++)
          {
            'id': 'L$i',
            'title': 't$i',
            'lessons': i <= 3 ? [{'id': 's$i', 'title': 'x'}] : [],
          },
        {'id': 'L11', 'title': 'no lessons key'},
      ],
    };
    expect(SenseCourse.levels(d).map((l) => l['id']), ['L1', 'L2', 'L3']);
    expect(SenseCourse.flat(d).length, 3);
    expect(SenseCourse.levels({}), isEmpty);
  });

  test('서버 목록을 따름 — 빠지면 안 보임 · 더해지면 보임 · 서버 못 받으면 묶음 목록', () async {
    String course(List<String> ids) => json.encode({
          'levels': [
            for (final id in ids)
              {
                'id': id,
                'title': id,
                'lessons': [
                  {'id': '$id-1', 'title': 'x'}
                ],
              },
          ],
        });
    final bundledCourse = course([for (var i = 1; i <= 10; i++) 'L$i']);
    Future<List<String>> shown(ScriptSync s) async => SenseCourse.levels(
            json.decode(await s.loadOr('assets/data/$sense', () async => bundledCourse)) as Map<String, dynamic>)
        .map((l) => '${l['id']}')
        .toList();
    final base = {
      'rev': 8,
      'files': {sense: sha(bundledCourse)},
    };
    ScriptSync withServer(int rev, String? body) => ScriptSync.forTest(
        dir: dir,
        baseline: base,
        fetch: (url) async {
          if (body == null) return null;
          if (url.endsWith('/index.json')) {
            return json.encode({
              'rev': rev,
              'files': {sense: sha(body)},
            });
          }
          return body;
        });

    // 서버 못 받음 → 묶음 10
    final off = withServer(0, null);
    await off.refresh();
    expect((await shown(off)).length, 10);

    // 서버에서 L4~L10 을 뺌 → 3 만
    final fewer = withServer(9, course(['L1', 'L2', 'L3']));
    expect(await fewer.refresh(), isTrue);
    expect(await shown(fewer), ['L1', 'L2', 'L3']);

    // 서버에 15 까지 더함 → 15
    final more = withServer(10, course([for (var i = 1; i <= 15; i++) 'L$i']));
    expect(await more.refresh(), isTrue);
    expect((await shown(more)).length, 15);
    expect((await shown(more)).last, 'L15');
  });

  test('묶음 언어감각 10스텝 모두 내용 있음', () {
    final d = json.decode(File('assets/data/grammar/sense_course.json').readAsStringSync()) as Map<String, dynamic>;
    expect(SenseCourse.levels(d).length, 10);
  });
}
