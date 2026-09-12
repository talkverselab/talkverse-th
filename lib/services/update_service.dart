import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/l10n.dart';
import '../core/platform.dart';

/// GitHub 릴리스로 앱을 업데이트한다.
/// master에 푸시하면 CI가 서명된 APK와 `latest.json`을 `latest` 태그에 올린다.
/// 앱은 자기 빌드 번호와 `latest.json`의 빌드 번호를 견주어 새 빌드를 받는다.
class UpdateInfo {
  final String version; // 0.2.0
  final int build; // CI 실행 번호 (커질수록 최신)
  final String sha;
  final String notes; // 마지막 커밋 제목
  final DateTime? builtAt;
  final int size; // APK 바이트

  const UpdateInfo({
    required this.version,
    required this.build,
    this.sha = '',
    this.notes = '',
    this.builtAt,
    this.size = 0,
  });

  static UpdateInfo parse(String raw) {
    final j = json.decode(raw) as Map<String, dynamic>;
    return UpdateInfo(
      version: '${j['version'] ?? ''}',
      build: (j['build'] as num?)?.toInt() ?? 0,
      sha: '${j['sha'] ?? ''}',
      notes: '${j['notes'] ?? ''}',
      builtAt: DateTime.tryParse('${j['date'] ?? ''}')?.toLocal(),
      size: (j['size'] as num?)?.toInt() ?? 0,
    );
  }

  String get sizeText =>
      size <= 0 ? '' : '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
}

enum InstallResult {
  /// 설치 화면을 띄웠다.
  started,

  /// 「출처를 알 수 없는 앱」 허용이 필요해 설정 화면을 열었다.
  needPermission,

  /// 내려받은 파일이 없다.
  missing,
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const repo = 'talkverselab/talkverse-th';
  static const _base = 'https://github.com/$repo/releases/download/latest';
  static const apkName = 'thai-universe-latest.apk';
  static const releasePage = 'https://github.com/$repo/releases/tag/latest';
  static const _channel = MethodChannel('thai_universe/installer');

  /// 릴리스가 앱보다 새 빌드인가.
  static bool isNewer({required int current, required int latest}) =>
      latest > current;

  int _currentBuild = 0;
  String _currentVersion = '';

  int get currentBuild => _currentBuild;
  String get currentVersion => _currentVersion;

  String get currentText => _currentVersion.isEmpty
      ? tr('확인 중')
      : trf('{0} · 빌드 {1}', [_currentVersion, _currentBuild]);

  Future<void> loadCurrent() async {
    final info = await PackageInfo.fromPlatform();
    _currentVersion = info.version;
    _currentBuild = int.tryParse(info.buildNumber) ?? 0;
  }

  /// 릴리스에 올라온 `latest.json`을 읽는다.
  Future<UpdateInfo> fetchLatest() async {
    final raw = await _get(Uri.parse('$_base/latest.json'));
    return UpdateInfo.parse(utf8.decode(raw));
  }

  Future<List<int>> _get(Uri url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(url);
      final res = await req.close();
      if (res.statusCode != HttpStatus.ok) {
        throw HttpException(trf('서버 응답 {0}', [res.statusCode]), uri: url);
      }
      final out = <int>[];
      await for (final chunk in res) {
        out.addAll(chunk);
      }
      return out;
    } finally {
      client.close(force: true);
    }
  }

  /// APK를 캐시 폴더로 내려받는다. [onProgress]는 (받은 바이트, 전체 바이트(-1이면 모름)).
  Future<File> download({void Function(int received, int total)? onProgress}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$apkName');
    if (await file.exists()) await file.delete();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse('$_base/$apkName'));
      final res = await req.close();
      if (res.statusCode != HttpStatus.ok) {
        throw HttpException(trf('내려받기 실패 ({0})', [res.statusCode]));
      }
      final total = res.contentLength;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in res) {
          received += chunk.length;
          sink.add(chunk);
          onProgress?.call(received, total);
        }
      } finally {
        await sink.close();
      }
      return file;
    } finally {
      client.close(force: true);
    }
  }

  /// 내려받은 APK의 설치 화면을 띄운다 (안드로이드 전용).
  Future<InstallResult> install(String path) async {
    if (!isAndroid) return InstallResult.missing; // iOS 는 TestFlight 로 배포
    final r = await _channel.invokeMethod<String>('installApk', {'path': path});
    switch (r) {
      case 'need_permission':
        return InstallResult.needPermission;
      case 'missing':
        return InstallResult.missing;
      default:
        return InstallResult.started;
    }
  }
}
