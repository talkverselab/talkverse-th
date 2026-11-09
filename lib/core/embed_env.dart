
import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 통합 앱(Talkverse, com.talkverse.app) 안에 패키지로 들어갔는지 — `embedInit()` 이 정한다(2026-11-09, ~/talkverse/talkverse-app/EMBED_GUIDE.md).
/// 단독 앱(태국어유니버스)에서는 false 이고 모든 동작이 예전과 같다.
bool embedded = false;

/// 이 언어의 저장 이름 접두(설정 키·기기 폴더·DB). 다른 언어 패키지와 겹치지 않게.
const storePrefix = 'th_';
const packageName = 'thai_universe';

/// 에셋 경로 — 패키지로 들어가면 Flutter 가 `packages/<패키지>/` 아래에 둔다.
String assetPath(String p) => embedded && p.startsWith('assets/') ? 'packages/$packageName/$p' : p;

/// AssetManifest 의 키 → 앱 안 상대 경로(`assets/...`). 패키지 접두가 있으면 뗀다.
String stripAssetPrefix(String p) => p.startsWith('packages/$packageName/') ? p.substring('packages/$packageName/'.length) : p;

/// 글꼴 이름 — 패키지 글꼴은 `packages/<패키지>/<family>`.
String? fontFamilyOf(String? f) => f == null || !embedded ? f : 'packages/$packageName/$f';

/// 이 앱이 쓰는 에셋 번들 — `assets/...` 키에 패키지 접두를 붙여 rootBundle 로 넘긴다(단독 앱이면 그대로).
/// 화면·서비스는 rootBundle 대신 이것을 쓴다(파일마다 경로를 고치지 않으려고).
final AssetBundle tvBundle = _PrefixBundle(rootBundle);

class _PrefixBundle extends AssetBundle {
  _PrefixBundle(this._b);
  final AssetBundle _b;
  @override
  Future<ByteData> load(String key) => _b.load(assetPath(key));
  @override
  Future<ImmutableBuffer> loadBuffer(String key) => _b.loadBuffer(assetPath(key));
  @override
  Future<String> loadString(String key, {bool cache = true}) => _b.loadString(assetPath(key), cache: cache);
  @override
  Future<T> loadStructuredData<T>(String key, Future<T> Function(String value) parser) => _b.loadStructuredData(assetPath(key), parser);
  @override
  Future<T> loadStructuredBinaryData<T>(String key, FutureOr<T> Function(ByteData data) parser) => _b.loadStructuredBinaryData(assetPath(key), parser);
  @override
  void evict(String key) => _b.evict(assetPath(key));
  @override
  void clear() => _b.clear();
}

String? _dir;

/// 이 언어 전용 기기 저장 폴더(Application Support/th). 통합 앱일 때만 쓴다 — 단독 앱은 예전 위치 그대로(옮기지 않음).
Future<String> dataDir() async {
  if (_dir != null) return _dir!;
  final d = Directory('${(await getApplicationSupportDirectory()).path}/th');
  if (!d.existsSync()) d.createSync(recursive: true);
  return _dir = d.path;
}

/// 기기 폴더 고르기: 통합 앱이면 Application Support/th/(name), 단독 앱이면 [legacy].
Future<String> storeDir(String name, Future<String> Function() legacy) async => embedded ? '${await dataDir()}/$name' : await legacy();

