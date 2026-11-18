import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_universe/services/script_sync.dart';

String sha(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('script_sync'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  const a = 'dialogues/R0/friends/a.json', b = 'dialogues/R0/friends/b.json', c = 'dialogues/R0/friends/c.json';
  const newA = '{"id":"a","v":2}', newC = '{"id":"c"}';
  Map<String, dynamic> base(int rev) => {
        'rev': rev,
        'files': {a: 'old-a', b: 'same-b'},
      };

  test('서버 rev 가 크면 바뀐 파일만 받고, 빠진 편·새 편을 안다. 새 빌드(rev 같음)면 받은 것을 버린다', () async {
    final asked = <String>[];
    Future<String?> fetch(String url) async {
      asked.add(url);
      if (url.endsWith('/index.json')) {
        return json.encode({
          'rev': 3,
          'files': {a: sha(newA), c: sha(newC)},
        });
      }
      if (url.contains(a)) return newA;
      if (url.contains(c)) return newC;
      return null;
    }

    final s = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: base(2));
    expect(await s.refresh(), isTrue);
    expect(s.rev, 3);
    expect(await s.load(a), newA);
    expect(s.removed, {b});
    expect(s.added.toList(), [c]);
    expect(asked.length, 3);

    // 같은 실행에서는 다시 묻지 않는다
    asked.clear();
    expect(await s.refresh(), isFalse);
    expect(asked, isEmpty);

    // 다시 켠 앱(같은 빌드)은 받은 것을 그대로 쓴다
    final again = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: base(2));
    await again.init();
    expect(again.rev, 3);
    expect(await again.load(a), newA);

    // rev 3 을 실은 새 빌드를 깔면 받은 것을 버린다
    final newer = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: base(3));
    await newer.init();
    expect(newer.rev, 0);
    expect(newer.overlayCount, 0);
    expect(dir.existsSync(), isFalse);
  });

  test('내용이 sha 와 다르거나 받다가 실패하면 아무것도 바꾸지 않는다', () async {
    Future<String?> fetch(String url) async => url.endsWith('/index.json')
        ? json.encode({
            'rev': 5,
            'files': {a: sha(newA), b: 'same-b'},
          })
        : '{"id":"tampered"}';
    final s = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: base(2));
    expect(await s.refresh(), isFalse);
    expect(s.rev, 0);
    expect(s.overlayCount, 0);
    expect(File('${dir.path}/state.json').existsSync(), isFalse);
  });

  test('서버 rev 가 앱 안 rev 이하면 받지 않는다', () async {
    final s = ScriptSync.forTest(dir: dir, fetch: (u) async => json.encode({'rev': 2, 'files': {a: 'x'}}), baseline: base(2));
    expect(await s.refresh(), isFalse);
  });
}
