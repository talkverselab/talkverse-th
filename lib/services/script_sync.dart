import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/embed_env.dart';

/// 원고 덮어쓰기(사용자 지시 2026-11-17 「정식 출시 뒤에도 심사 없이 원고를 고치게」).
///
/// 앱 안 원고(`assets/data/…`)가 바탕이고, 서버에 그보다 새 판이 있으면 바뀐 파일만 받아 기기에 두고 그것을 먼저 읽는다.
/// - 서버: `GET <root>/index.json` → `{"rev": 7, "files": {"dialogues/R0/friends/r0_friends_a2.json": "<sha1 앞 12자리>", …}}`,
///   파일은 `GET <root>/<경로>?v=<sha>`. 경로는 `assets/data/` 아래 상대 경로.
/// - 앱 안 기준표 `assets/data/script_rev.json` — 이 빌드를 만들 때의 `rev`·파일별 sha(올리는 도구 `tools/script_publish.py` 가 쓴다).
/// - 서버 rev 가 앱 안 rev 보다 **클 때만** 받는다. 새 빌드(rev 가 같거나 큼)를 깔면 기기의 덮어쓴 파일은 지운다 — 앱 안 원고가 더 새것.
/// - **앱을 켤 때마다 무조건** 확인해 받는다(사용자 지시 2026-11-17) — 그림·음성 내려받기(`ContentSync`)의 선택·「나중에」와 상관없이 따로 돈다.
///   시작 화면은 [startupWait] 까지만 기다리고, 그때까지 못 끝내면 앱을 열고 뒤에서 마저 받는다.
/// - 전부 받아 확인(sha·JSON)한 뒤에만 바꾼다. 실패하면 지금 것 그대로. 서버가 없어도(404·오프라인) 앱 안 원고로 돈다.
/// - 회화: 서버 목록에 없는 편은 숨기고(`removed`), 앱에 없는 새 편은 더한다(`added`).
/// 규격 = `docs/CONTENT_SYNC.md` §6.
class ScriptSync {
  ScriptSync._();
  static ScriptSync instance = ScriptSync._();

  /// 시험용 — 폴더·요청·기준표를 바꿔 끼운다.
  @visibleForTesting
  ScriptSync.forTest({required Directory dir, required Future<String?> Function(String url) fetch, required Map<String, dynamic> baseline})
      : _testDir = dir,
        _fetch = fetch,
        _testBaseline = baseline;

  static const root = 'https://auth.talkverse.uk/art/script/th';
  static const _kBaseline = 'assets/data/script_rev.json';
  static const startupWait = Duration(seconds: 15);

  Directory? _testDir;
  Map<String, dynamic>? _testBaseline;
  Future<String?> Function(String url)? _fetch;

  Directory? _dir;
  bool _ready = false;
  int baseRev = 0;
  Map<String, String> _base = {};

  /// 기기에 적용된 서버 판(없으면 0)과 덮어쓴 파일(경로 → sha).
  int rev = 0;
  Map<String, String> _over = {};
  Set<String> _removed = {};

  /// 지금 쓰는 원고 번호(화면 표시용).
  int get shownRev => rev > baseRev ? rev : baseRev;
  int get overlayCount => _over.length;

  /// 서버 판에서 빠진 앱 안 파일(회화 편을 숨길 때).
  Set<String> get removed => _removed;

  /// 앱 안에 없는 새 파일(새 회화 편).
  Iterable<String> get added => _over.keys.where((p) => !_base.containsKey(p));

  /// 기기 상태만 읽는다(네트워크 없음). 여러 번 불러도 한 번만.
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      final b = _testBaseline ?? json.decode(utf8.decode((await rootBundle.load(assetPath(_kBaseline))).buffer.asUint8List())) as Map<String, dynamic>;
      baseRev = (b['rev'] as int?) ?? 0;
      _base = ((b['files'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
    } catch (_) {}
    try {
      _dir = _testDir ?? Directory('${await dataDir()}/script');
      final f = File('${_dir!.path}/state.json');
      if (!await f.exists()) return;
      final s = json.decode(await f.readAsString()) as Map<String, dynamic>;
      final r = (s['rev'] as int?) ?? 0;
      if (r <= baseRev) {
        // 새 빌드가 더 새 원고를 싣고 왔다 — 받아 둔 것은 버린다
        await _dir!.delete(recursive: true);
        return;
      }
      rev = r;
      _over = ((s['files'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
      _removed = {...((s['removed'] as List?) ?? const []).map((e) => '$e')};
    } catch (e) {
      debugPrint('ScriptSync: 상태 읽기 실패 $e');
      rev = 0;
      _over = {};
      _removed = {};
    }
  }

  /// 원고 한 파일 — 덮어쓴 것이 있으면 그것, 없으면 앱 안 것. [rel] = `assets/data/` 아래 경로.
  Future<String> load(String rel) async {
    await init();
    if (_over.containsKey(rel) && _dir != null) {
      try {
        return await File('${_dir!.path}/files/$rel').readAsString();
      } catch (_) {}
    }
    return utf8.decode((await rootBundle.load(assetPath('assets/data/$rel'))).buffer.asUint8List());
  }

  /// 서버에서 받은 덮어쓴 판이 있는 파일인지.
  bool has(String rel) => _over.containsKey(rel);

  /// 문법 파일처럼 서버 원고와 GitHub 무선 갱신(`ContentStore`) 둘 다 받는 파일 — 서버 원고가 있으면 그것, 없으면 [fallback].
  /// (사용자 지시 2026-11-23 「문법 파트는 DB 업데이트하면서 업뎃되게」)
  Future<String> loadOr(String assetPath, Future<String> Function() fallback) async {
    await init();
    final rel = assetPath.startsWith('assets/data/') ? assetPath.substring('assets/data/'.length) : assetPath;
    return has(rel) ? load(rel) : fallback();
  }

  /// 서버 판을 확인하고 바뀐 파일을 받는다. 무엇이든 바뀌었으면 true(읽어 둔 원고를 다시 읽을 것).
  /// 동시에 두 번 불러도 한 번만 돈다(앱 시작 때 기다리는 호출 + 회화를 읽은 뒤의 호출).
  /// 이번 실행에서 서버 목록을 한 번 확인했으면 다시 묻지 않는다.
  Future<bool> refresh() => _checked ? Future.value(false) : (_running ??= _refresh().whenComplete(() => _running = null));
  bool _checked = false;
  Future<bool>? _running;

  Future<bool> _refresh() async {
    await init();
    if (_dir == null) return false;
    try {
      final body = await (_fetch ?? _get)('$root/index.json');
      if (body == null) return false;
      final j = json.decode(body) as Map<String, dynamic>;
      final r = (j['rev'] as int?) ?? 0;
      if (r <= baseRev || r == rev) {
        _checked = true;
        return false;
      }
      final files = ((j['files'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
      if (files.keys.any((p) => !RegExp(r'^[\w./-]+\.json$').hasMatch(p) || p.contains('..'))) return false;
      final over = <String, String>{};
      final need = <MapEntry<String, String>>[];
      for (final e in files.entries) {
        if (_base[e.key] == e.value) continue; // 앱 안 것과 같다
        if (_over[e.key] == e.value && await File('${_dir!.path}/files/${e.key}').exists()) {
          over[e.key] = e.value; // 이미 받은 판
        } else {
          need.add(e);
        }
      }
      Future<bool> one(MapEntry<String, String> e) async {
        final text = await (_fetch ?? _get)('$root/${e.key}?v=${e.value}');
        if (text == null || !sha1.convert(utf8.encode(text)).toString().startsWith(e.value)) return false;
        json.decode(text);
        final f = File('${_dir!.path}/files/${e.key}');
        await f.parent.create(recursive: true);
        final tmp = File('${f.path}.tmp');
        await tmp.writeAsString(text, flush: true);
        await tmp.rename(f.path);
        return true;
      }

      for (var i = 0; i < need.length; i += 8) {
        final part = need.sublist(i, i + 8 > need.length ? need.length : i + 8);
        if ((await Future.wait(part.map(one))).contains(false)) return false;
        for (final e in part) {
          over[e.key] = e.value;
        }
      }
      final removed = {for (final p in _base.keys) if (!files.containsKey(p)) p};
      await File('${_dir!.path}/state.json').writeAsString(json.encode({'rev': r, 'files': over, 'removed': removed.toList()}), flush: true);
      for (final p in _over.keys.where((p) => !over.containsKey(p))) {
        try {
          await File('${_dir!.path}/files/$p').delete();
        } catch (_) {}
      }
      rev = r;
      _over = over;
      _removed = removed;
      _checked = true;
      return true;
    } catch (e) {
      debugPrint('ScriptSync: 받기 실패 $e');
      return false;
    }
  }

  Future<String?> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.userAgentHeader, 'talkverse-th/0.1');
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
