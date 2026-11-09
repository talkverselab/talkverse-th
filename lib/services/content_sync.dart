import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import '../core/prefs.dart';
import '../core/embed_env.dart';

/// 그림(장면 컷·단어 그림) 기기 내려받기 + 버전 관리 — 일본어앱 content_sync.dart 이식(사용자 지시 2026-11-04, 모든 언어앱 공통)
/// "앱 시작할 때 로딩하면서 다운로드 받고, 업데이트 번호가 다르면 갱신".
///
/// - 시작 때 매니페스트 둘(단어 그림 `/art/th/manifest`, 장면 컷 `/art/th/scene/manifest`)을 받아
///   기기에 맞는 크기(폰 584·512, 태블릿 1168·512)의 파일 목록을 만들고, 그 목록의 `?v=` 해시로 **그림 버전**을 계산한다.
/// - 저장된 버전과 다르면(처음 설치 포함) 로딩 화면(`SyncScreen`)에서 바뀐 파일만 내려받는다(같은 `?v=` 는 건너뜀).
///   「나중에」를 누르면 앱을 먼저 열고 뒤에서 계속 받는다 — 아직 없는 그림은 네트워크로 바로 보인다.
/// - 파일은 앱 지원 폴더 `art/<키>` 에 두고, 색인 `art/index.json`(키 → v) 으로 관리한다.
/// - 그림을 그리는 쪽은 `artProvider(url)` 로 — 기기에 있으면 파일, 없으면 네트워크.
/// - 회화·단어 DB 버전은 번들 `assets/data/version.json` 의 `db` 번호(SeedLoader 가 비교).
/// - 회화 음성(mp4, `/art/th/audio/manifest`)도 같은 목록·버전에 들어가 같은 폴더에 받는다(2026-11-07, 일본어앱 구조). 재생은 `DialogueAudio`.

/// 회화 음성 한 줄 = 편·턴·판(m 남성판 / f 여성판). 모든 턴에 두 판이 다 있고, 그 음성이 읽는 본문 넷도 항상 들어 있다.
/// key 는 `?v=` 포함. text = 태국어 본문, reading = (태국어는 빈 값), rd = 한글 독음, ko = 한국어 뜻.
class AudioLine {
  final String key;
  final int ms;
  final String text, reading, rd, ko;
  const AudioLine(this.key, this.ms, this.text, this.reading, this.rd, this.ko);
}

class SyncProgress {
  final String phase; // idle | manifest | download | done | offline
  final int done, total;
  final bool running;
  const SyncProgress(this.phase, this.done, this.total, this.running);
  double get ratio => total == 0 ? 0 : done / total;
}

class ContentSync {
  ContentSync._();
  static final ContentSync instance = ContentSync._();

  static const wordsManifestUrl = 'https://auth.talkverse.uk/art/th/manifest';
  static const sceneManifestUrl = 'https://auth.talkverse.uk/art/th/scene/manifest';
  /// 회화 음성: `GET …/art/th/audio/manifest` → items[{episode,turn,voice(m·f),key,ms,text,reading,rd,ko}], 파일 = base+key(mp4).
  /// 아직 없거나 실패해도 그림 동기화는 그대로 간다.
  static const audioManifestUrl = 'https://auth.talkverse.uk/art/th/audio/manifest';
  static const _prefAudio = 'art_audio_manifest_v1';
  static const _prefVersion = 'art_version_v1';
  static const _prefScene = 'art_scene_manifest_v1';
  static const _concurrency = 6;
  static const _ua = 'talkverse-th/0.2';

  final ValueNotifier<SyncProgress> progress = ValueNotifier(const SyncProgress('idle', 0, 0, false));
  Directory? _dir;
  final Map<String, String> _index = {}; // 키(?v 뺀 것) → v
  final Map<String, String> _wanted = {}; // 키 → v (이번 버전 목록)
  String _base = 'https://auth.talkverse.uk/art';
  String? _wantedVersion;
  bool _large = false;
  bool _female = false;
  bool _cancel = false;
  Map<String, Map<int, Map<String, AudioLine>>> audioIndex = {}; // 편id → {턴 → {m|f → 음성}}
  Map<String, Map<int, String>> sceneIndex = {}; // 편id → {컷 → 키(?v 포함)} — ArtService 가 네트워크 전에 본다
  String get base => _base;

  /// 시작 때 한 번. 색인을 읽고 매니페스트를 받아 "받을 게 있는지"를 돌려준다(오프라인이면 false).
  Future<bool> init({bool large = false, bool female = false}) async {
    _large = large;
    _female = female;
    try {
      _dir = Directory(await storeDir('art', () async => '${(await getApplicationSupportDirectory()).path}/art'));
      if (!await _dir!.exists()) await _dir!.create(recursive: true);
      final f = File('${_dir!.path}/index.json');
      if (await f.exists()) _index.addAll((json.decode(await f.readAsString()) as Map).cast<String, String>());
    } catch (e) {
      debugPrint('ContentSync: 색인 읽기 실패 $e');
    }
    final prefs = await Prefs.getInstance();
    // 저장된 장면 매니페스트가 있으면 먼저 색인으로(오프라인 대비)
    final cachedScene = prefs.getString(_prefScene);
    if (cachedScene != null) _applyScene(cachedScene);
    final cachedAudio = prefs.getString(_prefAudio);
    if (cachedAudio != null) _applyAudio(cachedAudio);
    progress.value = const SyncProgress('manifest', 0, 0, true);
    final ok = await _fetchManifests(prefs);
    if (!ok) {
      progress.value = const SyncProgress('offline', 0, 0, false);
      return false;
    }
    final missing = _wanted.entries.where((e) => _index[e.key] != e.value).length;
    final stored = prefs.getString(_prefVersion);
    final need = missing > 0 && stored != _wantedVersion;
    progress.value = SyncProgress(need ? 'download' : 'done', _wanted.length - missing, _wanted.length, false);
    if (!need && stored != _wantedVersion) await prefs.setString(_prefVersion, _wantedVersion!);
    return need;
  }

  Future<bool> _fetchManifests(Prefs prefs) async {
    try {
      final w = await _get(wordsManifestUrl);
      final s = await _get(sceneManifestUrl);
      if (w == null || s == null) return false;
      _wanted.clear();
      final wj = json.decode(w) as Map<String, dynamic>;
      _base = (wj['base'] as String? ?? _base).replaceAll(RegExp(r'/$'), '');
      for (final it in (wj['items'] as List? ?? const [])) {
        final k = (it as Map)['key_512'] as String?;
        if (k != null) _put(k);
      }
      _applyScene(s);
      await prefs.setString(_prefScene, s);
      try {
        final a = await _get(audioManifestUrl);
        if (a != null && _applyAudio(a)) {
          await prefs.setString(_prefAudio, a);
        } else {
          final old = prefs.getString(_prefAudio);
          if (old != null) _applyAudio(old); // _wanted 를 비웠으니 저장본으로 다시 채운다
        }
      } catch (e) {
        debugPrint('ContentSync: 음성 매니페스트 없음 $e');
      }
      final keys = _wanted.entries.map((e) => '${e.key}@${e.value}').toList()..sort();
      _wantedVersion = sha1.convert(utf8.encode(keys.join('\n'))).toString().substring(0, 16);
      return true;
    } catch (e) {
      debugPrint('ContentSync: 매니페스트 실패 $e');
      return false;
    }
  }

  void _applyScene(String body) {
    try {
      final sj = json.decode(body) as Map<String, dynamic>;
      _base = (sj['base'] as String? ?? _base).replaceAll(RegExp(r'/$'), '');
      final idx = <String, Map<int, String>>{};
      for (final it in (sj['items'] as List? ?? const [])) {
        final m = it as Map<String, dynamic>;
        final k = (_large ? m['key_1168'] : m['key_584']) as String? ?? m['key_1168'] as String?;
        final ep = m['episode'] as String?;
        final cut = m['cut'];
        if (k == null || ep == null || cut is! int) continue;
        idx.putIfAbsent(ep, () => {})[cut] = k;
        _put(k);
      }
      sceneIndex = idx;
    } catch (e) {
      debugPrint('ContentSync: 장면 매니페스트 해석 실패 $e');
    }
  }

  /// 음성 매니페스트 → 색인 + 받을 목록(학습자 성별 판만 내려받는다 — 다른 판은 주소로 바로 재생).
  bool _applyAudio(String body) {
    try {
      final aj = json.decode(body) as Map<String, dynamic>;
      final items = aj['items'] as List? ?? const [];
      final mine = _female ? 'f' : 'm';
      final idx = <String, Map<int, Map<String, AudioLine>>>{};
      for (final it in items) {
        final m = it as Map<String, dynamic>;
        final ep = m['episode'] as String?, k = m['key'] as String?, voice = m['voice'] as String?;
        final turn = m['turn'];
        if (ep == null || k == null || voice == null || turn is! int) continue;
        String s(String f) => m[f] is String ? m[f] as String : '';
        idx.putIfAbsent(ep, () => {}).putIfAbsent(turn, () => {})[voice] =
            AudioLine(k, (m['ms'] as num?)?.toInt() ?? 0, s('text'), s('reading'), s('rd'), s('ko'));
        if (voice == mine) _put(k);
      }
      audioIndex = idx;
      return true;
    } catch (e) {
      debugPrint('ContentSync: 음성 매니페스트 해석 실패 $e');
      return false;
    }
  }

  void _put(String keyWithV) {
    final i = keyWithV.indexOf('?v=');
    final key = i < 0 ? keyWithV : keyWithV.substring(0, i);
    final v = i < 0 ? '0' : keyWithV.substring(i + 3);
    _wanted[key] = v;
  }

  /// 모자란 파일을 내려받는다(여러 번 불러도 한 번만 돈다). 끝나면 버전을 저장.
  Future<void>? _running;
  Future<void> download() => _running ??= _download().whenComplete(() => _running = null);

  Future<void> _download() async {
    _cancel = false;
    final todo = _wanted.entries.where((e) => _index[e.key] != e.value).toList();
    var done = _wanted.length - todo.length;
    progress.value = SyncProgress('download', done, _wanted.length, true);
    final q = List.of(todo);
    var since = 0;
    Future<void> worker() async {
      while (q.isNotEmpty && !_cancel) {
        final e = q.removeAt(0);
        if (await _fetchFile(e.key, e.value)) {
          _index[e.key] = e.value;
          since++;
        }
        done++;
        progress.value = SyncProgress('download', done, _wanted.length, true);
        if (since >= 20) {
          since = 0;
          await _saveIndex();
        }
      }
    }
    await Future.wait([for (var i = 0; i < _concurrency; i++) worker()]);
    await _saveIndex();
    final left = _wanted.entries.where((e) => _index[e.key] != e.value).length;
    if (left == 0 && _wantedVersion != null) {
      (await Prefs.getInstance()).setString(_prefVersion, _wantedVersion!);
    }
    progress.value = SyncProgress(left == 0 ? 'done' : 'download', _wanted.length - left, _wanted.length, false);
  }

  void cancel() => _cancel = true;

  Future<bool> _fetchFile(String key, String v) async {
    try {
      final f = File('${_dir!.path}/$key');
      await f.parent.create(recursive: true);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      try {
        final req = await client.getUrl(Uri.parse('$_base/$key${v == '0' ? '' : '?v=$v'}'));
        req.headers.set(HttpHeaders.userAgentHeader, _ua);
        final res = await req.close().timeout(const Duration(seconds: 40));
        if (res.statusCode != 200) return false;
        final tmp = File('${f.path}.part');
        final sink = tmp.openWrite();
        await res.pipe(sink);
        await tmp.rename(f.path);
        return true;
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      debugPrint('ContentSync: 받기 실패 $key $e');
      return false;
    }
  }

  Future<void> _saveIndex() async {
    try {
      await File('${_dir!.path}/index.json').writeAsString(json.encode(_index), flush: true);
    } catch (_) {}
  }

  /// 그림 주소(또는 키) → 기기 파일이 있으면 FileImage, 없으면 NetworkImage.
  ImageProvider provider(String url) {
    final f = localFile(url);
    return f != null ? FileImage(f) : NetworkImage(url);
  }

  File? localFile(String url) {
    if (_dir == null) return null;
    var key = url;
    if (key.startsWith(_base)) key = key.substring(_base.length);
    final i = key.indexOf('?v=');
    final v = i < 0 ? '0' : key.substring(i + 3);
    if (i >= 0) key = key.substring(0, i);
    key = key.replaceFirst(RegExp(r'^/'), '');
    if (_index[key] != v) return null;
    final f = File('${_dir!.path}/$key');
    return f.existsSync() ? f : null;
  }

  Future<String?> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.userAgentHeader, _ua);
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }

  /// 이번 버전 그림 수·대략 크기(MB) — 로딩 화면 안내용.
  (int, int) get estimate {
    final n = _wanted.length;
    final cuts = _wanted.keys.where((k) => k.startsWith('scene/')).length;
    final aud = _wanted.keys.where((k) => k.startsWith('audio/')).length;
    final mb = (cuts * (_large ? 120 : 44) + aud * 42 + (n - cuts - aud) * 27) ~/ 1024;
    return (n, mb);
  }
}

/// 그림 주소 → 기기 파일 우선 ImageProvider(모든 Image.network 자리에서 쓴다).
ImageProvider artProvider(String url) => ContentSync.instance.provider(url);
