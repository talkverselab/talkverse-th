import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// 콘텐츠만 바꾼 수정(스크립트 문장·문법 예문·질문 문구)을 APK 없이 받는다.
///
/// - 저장소 `assets/data/content_manifest.json` = {version, files: {경로: sha1}}.
///   `python tools/content_manifest.py` 가 만든다(`publish_to_app.py` 가 자동 호출).
/// - 앱이 켜질 때 GitHub(공개 저장소 master)의 manifest 를 받아, sha1 이 다른 파일만 내려받아
///   앱 문서 폴더 `content/` 에 둔다. 읽을 때는 받은 파일이 있으면 그걸, 없으면 APK 번들.
/// - 새 APK 의 번들 manifest 버전이 받아 둔 것보다 높으면 받아 둔 것을 버린다(번들이 최신).
/// - 코드(화면·기능)는 이 방법으로 바뀌지 않는다 — 그건 APK 업데이트.
class ContentStore {
  ContentStore._();
  static final ContentStore instance = ContentStore._();

  static const _remote = 'https://raw.githubusercontent.com/talkverselab/talkverse-th/master/';
  static const _manifest = 'assets/data/content_manifest.json';

  /// 새 콘텐츠를 받으면 올라간다 — 화면·서비스가 듣고 다시 읽는다.
  final ValueNotifier<int> revision = ValueNotifier(0);
  int bundledVersion = 0;
  int activeVersion = 0;
  String lastResult = '';
  Directory? _dir;

  Future<Directory> _root() async =>
      _dir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/content');

  Future<Map<String, dynamic>> _readManifest(String raw) async => json.decode(raw) as Map<String, dynamic>;

  /// 앱 시작 때 한 번. 번들보다 오래된 캐시는 지운다.
  Future<void> init() async {
    try {
      final b = await _readManifest(await rootBundle.loadString(_manifest));
      bundledVersion = (b['version'] as num?)?.toInt() ?? 0;
      final root = await _root();
      final local = File('${root.path}/manifest.json');
      activeVersion = bundledVersion;
      if (await local.exists()) {
        final l = await _readManifest(await local.readAsString());
        final lv = (l['version'] as num?)?.toInt() ?? 0;
        if (lv <= bundledVersion) {
          await root.delete(recursive: true);
        } else {
          activeVersion = lv;
        }
      }
    } catch (e) {
      debugPrint('ContentStore.init: $e');
    }
  }

  /// 받은 파일이 있으면 그것, 없으면 번들.
  Future<String> loadString(String assetPath) async {
    try {
      final f = File('${(await _root()).path}/$assetPath');
      if (await f.exists()) return await f.readAsString();
    } catch (_) {}
    return rootBundle.loadString(assetPath);
  }

  Future<String> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  /// 원격 manifest 와 비교해 바뀐 파일만 받는다. 받은 게 있으면 true.
  Future<bool> refresh() async {
    try {
      final remote = await _readManifest(await _get('$_remote$_manifest?t=${DateTime.now().millisecondsSinceEpoch ~/ 60000}'));
      final rv = (remote['version'] as num?)?.toInt() ?? 0;
      if (rv <= activeVersion) {
        lastResult = '최신 ($activeVersion)';
        return false;
      }
      final root = await _root();
      // 지금 쓰는 판(받은 것 또는 번들)의 sha1 목록
      final localFile = File('${root.path}/manifest.json');
      final cur = await localFile.exists()
          ? await _readManifest(await localFile.readAsString())
          : await _readManifest(await rootBundle.loadString(_manifest));
      final curFiles = (cur['files'] as Map?) ?? const {};
      final files = (remote['files'] as Map).cast<String, String>();
      var n = 0;
      for (final e in files.entries) {
        if (curFiles[e.key] == e.value) continue;
        final body = await _get('$_remote${e.key}?v=${e.value}');
        json.decode(body); // 깨진 JSON 은 쓰지 않는다
        final f = File('${root.path}/${e.key}');
        await f.parent.create(recursive: true);
        await f.writeAsString(body);
        n++;
      }
      await root.create(recursive: true);
      await localFile.writeAsString(json.encode(remote));
      activeVersion = rv;
      lastResult = '파일 $n개 갱신 ($rv)';
      revision.value++;
      return n > 0;
    } catch (e) {
      lastResult = '실패: $e';
      debugPrint('ContentStore.refresh: $e');
      return false;
    }
  }
}
