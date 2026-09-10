# GitHub 릴리스로 앱 자체 업데이트 만들기 (Flutter · Android)

> 다른 프로젝트에 그대로 옮겨 붙이는 용도의 안내서.
> **결과**: master에 푸시 → GitHub Actions가 서명된 APK를 릴리스에 올림 → 폰의 앱에서
> 「설정 → 앱 업데이트」를 누르면 새 빌드를 확인하고 **내려받아 설치**까지 한다. 케이블·adb 불필요.
>
> 실제로 동작 중인 구현: `talkverselab/talkverse-th` (커밋 `aa48320`).

---

## 0. 전제와 한계

| 항목 | 내용 |
|---|---|
| 플랫폼 | **안드로이드 전용**. iOS는 사이드로딩이 막혀 있어 같은 방식이 불가능(TestFlight를 써야 함). |
| 저장소 | **PUBLIC이어야 한다.** 앱이 토큰 없이 릴리스 파일을 받기 때문. private면 PAT를 앱에 심어야 하는데 그러면 안 된다. |
| 서명 | 릴리스 APK가 **같은 키로 서명**돼야 덮어쓰기 설치가 된다. 키가 바뀌면 기존 앱을 지우고 새로 깔아야 한다. |
| 사용자 조작 | 첫 설치 때 「출처를 알 수 없는 앱 설치」 허용이 **1회** 필요(안드로이드 강제, 우회 불가). |

---

## 1. 설계

굴러가는(rolling) `latest` 태그 하나에 두 파일을 올린다.

```
releases/tag/latest
├── app-latest.apk      ← 서명된 릴리스 APK
└── latest.json         ← 버전 메타데이터 (앱이 먼저 읽는다)
```

`latest.json`:

```json
{
  "version": "0.2.0",
  "build": 26,
  "sha": "aa48320",
  "date": "2026-09-10T10:44:08Z",
  "notes": "feat: 앱 안에서 GitHub 최신 빌드 확인·내려받기·설치",
  "size": 61950344
}
```

**핵심은 `build`.** 앱은 자기 빌드 번호(`PackageInfo.buildNumber`)와 `latest.json`의 `build`를
견주어 `latest > current`일 때만 새 빌드로 본다. 그래서 **빌드 번호가 반드시 단조 증가**해야 하고,
그 역할을 `github.run_number`(워크플로 실행 번호)가 맡는다. pubspec의 `version: x.y.z+N`은
그대로 두고 CI에서 `--build-number`로 덮어쓴다.

> 로컬에서 `flutter build apk`로 만든 APK는 pubspec의 `+N`(보통 작은 수)을 쓰므로
> 앱이 늘 "새 빌드 있음"으로 표시한다. **의도된 동작**이다(CI 빌드가 실제로 더 최신이므로).

---

## 2. CI — `.github/workflows/release.yml`

`<OWNER>/<REPO>`, 파일 이름만 바꾸면 된다.

```yaml
name: Release APK

on:
  push:
    branches: [master]
    # 문서만 고친 푸시는 빌드하지 않는다 (앱에 헛된 "새 빌드" 알림 방지)
    paths-ignore:
      - '**.md'
      - '.gitignore'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      # 릴리스 서명 키를 secrets에서 복원 (아래 3절 참고)
      - name: Restore signing key
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=upload-keystore.jks
          EOF

      - run: flutter pub get
      - run: flutter test

      # 빌드 번호 = 워크플로 실행 번호 → 앱이 자기 빌드와 견주어 새 빌드를 판단한다
      - name: Build APK
        run: flutter build apk --release --build-number=${{ github.run_number }}

      - name: Collect release files
        id: meta
        run: |
          cp build/app/outputs/flutter-apk/app-release.apk app-latest.apk
          VER=$(grep '^version:' pubspec.yaml | sed 's/version: *//' | cut -d+ -f1)
          NOTES=$(git log -1 --pretty=%s)
          SIZE=$(stat -c%s app-latest.apk)
          DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
          jq -n --arg version "$VER" --argjson build ${{ github.run_number }} --arg sha "${GITHUB_SHA:0:7}" --arg date "$DATE" --arg notes "$NOTES" --argjson size "$SIZE" '{version:$version, build:$build, sha:$sha, date:$date, notes:$notes, size:$size}' > latest.json
          cat latest.json
          echo "ver=$VER" >> "$GITHUB_OUTPUT"
          echo "notes=$NOTES" >> "$GITHUB_OUTPUT"

      - name: Update rolling "latest" release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: latest
          name: 최신 빌드
          body: |
            버전 ${{ steps.meta.outputs.ver }} · 빌드 ${{ github.run_number }}
            ${{ steps.meta.outputs.notes }}
          make_latest: true
          files: |
            app-latest.apk
            latest.json
```

**함정**

- `jq`는 ubuntu 러너에 기본 설치돼 있다. 커밋 제목에 따옴표·특수문자가 들어가도 `jq -n --arg`가
  안전하게 JSON 이스케이프한다. 직접 `cat > latest.json <<EOF`로 만들면 깨진다.
- `paths-ignore`가 없으면 README 한 줄 고쳐도 새 빌드가 올라가 폰에 업데이트 알림이 뜬다.
- `git log -1`은 `checkout@v4`의 기본 depth 1에서도 동작한다.

---

## 3. 서명 키를 secrets에 넣기 (한 번만)

```bash
# 키스토어가 없다면 만들고
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload

# base64로 바꿔서 secret에 붙여넣는다
base64 -w0 upload-keystore.jks > keystore.b64
```

리포 Settings → Secrets and variables → Actions 에 4개 등록:
`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`.

`android/app/build.gradle.kts`가 `android/key.properties`를 읽어 `signingConfigs.release`를
쓰도록 돼 있어야 한다(Flutter 공식 문서의 표준 설정). `key.properties`와 `*.jks`는 **반드시 gitignore**.

---

## 4. Flutter 쪽

### 4-1. `pubspec.yaml`

```yaml
dependencies:
  package_info_plus: ^8.1.1   # 현재 버전·빌드 번호 읽기
  path_provider: ^2.1.4       # APK를 받을 캐시 폴더
```

HTTP는 `dart:io`의 `HttpClient`로 충분해서 `http` 패키지가 필요 없다.

### 4-2. `lib/services/update_service.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final int build;      // CI 실행 번호 (커질수록 최신)
  final String sha;
  final String notes;
  final DateTime? builtAt;
  final int size;

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

enum InstallResult { started, needPermission, missing }

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const repo = '<OWNER>/<REPO>';
  static const _base = 'https://github.com/$repo/releases/download/latest';
  static const apkName = 'app-latest.apk';
  static const _channel = MethodChannel('<app>/installer');

  static bool isNewer({required int current, required int latest}) =>
      latest > current;

  int _currentBuild = 0;
  String _currentVersion = '';
  int get currentBuild => _currentBuild;
  String get currentText =>
      _currentVersion.isEmpty ? '확인 중' : '$_currentVersion · 빌드 $_currentBuild';

  Future<void> loadCurrent() async {
    final info = await PackageInfo.fromPlatform();
    _currentVersion = info.version;
    _currentBuild = int.tryParse(info.buildNumber) ?? 0;
  }

  Future<UpdateInfo> fetchLatest() async {
    final raw = await _get(Uri.parse('$_base/latest.json'));
    return UpdateInfo.parse(utf8.decode(raw));
  }

  Future<List<int>> _get(Uri url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final res = await (await client.getUrl(url)).close();
      if (res.statusCode != HttpStatus.ok) {
        throw HttpException('서버 응답 ${res.statusCode}', uri: url);
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

  /// APK를 캐시 폴더로 내려받는다. onProgress(받은 바이트, 전체(-1이면 모름)).
  Future<File> download({void Function(int received, int total)? onProgress}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$apkName');
    if (await file.exists()) await file.delete();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final res = await (await client.getUrl(Uri.parse('$_base/$apkName'))).close();
      if (res.statusCode != HttpStatus.ok) {
        throw HttpException('내려받기 실패 (${res.statusCode})');
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

  Future<InstallResult> install(String path) async {
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
```

> 릴리스 파일 URL은 `objects.githubusercontent.com`으로 302 리다이렉트된다.
> `HttpClient`는 기본으로 리다이렉트를 따라가므로 추가 처리가 필요 없다.

### 4-3. 화면 — 상태 기계만 옮기면 된다

UI는 각 앱 디자인에 맞추고, 다음 상태 전이만 지키면 된다.

```
idle ──check()──▶ checking ──▶ upToDate        (latest.build <= current)
                            └─▶ available      (latest.build >  current)
available ──download()──▶ downloading ──▶ ready ──install()──▶ 시스템 설치 화면
                       (실패 시 available로 되돌리고 오류 표시)
```

뼈대:

```dart
Future<void> _check() async {
  setState(() { _stage = _Stage.checking; _error = null; });
  try {
    final info = await _svc.fetchLatest();
    if (!mounted) return;
    setState(() {
      _latest = info;
      _stage = UpdateService.isNewer(
        current: _svc.currentBuild, latest: info.build,
      ) ? _Stage.available : _Stage.upToDate;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() { _stage = _Stage.idle; _error = _message(e); });
  }
}

Future<void> _download() async {
  setState(() { _stage = _Stage.downloading; _received = 0; _total = _latest?.size ?? -1; });
  try {
    final file = await _svc.download(onProgress: (r, t) {
      if (!mounted) return;
      setState(() { _received = r; if (t > 0) _total = t; });
    });
    if (!mounted) return;
    setState(() { _apkPath = file.path; _stage = _Stage.ready; });
    _install();                       // 받자마자 설치 화면으로
  } catch (e) {
    if (!mounted) return;
    setState(() { _stage = _Stage.available; _error = _message(e); });
  }
}

Future<void> _install() async {
  final r = await _svc.install(_apkPath!);
  if (r == InstallResult.needPermission) {
    setState(() => _error =
        '「출처를 알 수 없는 앱 설치」를 허용해 주세요. 방금 연 설정에서 이 앱을 켠 뒤 「설치」를 다시 누르면 됩니다.');
  }
}

String _message(Object e) {
  if (e is SocketException) return '네트워크에 연결하지 못했습니다.';
  if (e is HttpException) return '릴리스를 읽지 못했습니다 — ${e.message}';
  return '$e';
}
```

화면에 보여 주면 좋은 것: **지금 이 앱**(버전 · 빌드) / **최신 빌드**(버전 · 빌드 · 커밋 해시 ·
빌드 시각 · 용량 · 마지막 커밋 제목) / 진행률(%, MB) / 오류 문구.

설정 화면 진입점에서 `Navigator.push(... UpdateScreen())` 하나면 끝.
같은 김에 「앱 버전」 항목을 하드코딩 대신 `UpdateService.instance.currentText`로 바꿔 두면
지금 깔린 게 어느 빌드인지 늘 보인다.

---

## 5. Android 쪽 (4개 파일)

### 5-1. `android/app/src/main/AndroidManifest.xml`

```xml
<!-- 최상위 <manifest> 안 -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>

<!-- <application> 안 -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

> **`INTERNET` 권한을 빼먹기 쉽다.** 디버그 빌드는 Flutter가 자동으로 넣어 주지만
> 릴리스 빌드는 넣지 않는다. 네트워크를 안 쓰던 앱이라면 이게 첫 번째 실패 원인이 된다.

### 5-2. `android/app/src/main/res/xml/file_paths.xml` (새 파일)

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <cache-path name="cache" path="." />
    <files-path name="files" path="." />
</paths>
```

### 5-3. `MainActivity.kt`

```kotlin
package <YOUR.PACKAGE>

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.error("no_path", "APK 경로가 없습니다", null)
                        } else {
                            result.success(installApk(path))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installApk(path: String): String {
        val file = File(path)
        if (!file.exists()) return "missing"

        // Android 8+ : "출처를 알 수 없는 앱" 허용이 없으면 그 설정 화면을 연다
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            return "need_permission"
        }

        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        startActivity(
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )
        return "ok"
    }

    private companion object {
        const val CHANNEL = "<app>/installer"
    }
}
```

`androidx.core.content.FileProvider`는 Flutter 임베딩이 이미 `androidx.core`를 끌어오므로
gradle에 따로 추가할 게 없다.

> **authority 충돌 주의**: `image_picker`, `share_plus` 같은 플러그인이 이미
> `${applicationId}.fileprovider`를 쓰고 있으면 매니페스트 병합이 실패한다.
> 그럴 땐 authority를 `${applicationId}.updateprovider` 등으로 바꾸고 Kotlin 쪽도 같이 고친다.

---

## 6. 테스트

플러그인 없이 순수하게 검증할 수 있는 부분만 단위 테스트로 묶어 둔다.

```dart
test('latest.json 파싱', () {
  final info = UpdateInfo.parse(
    '{"version":"0.2.0","build":26,"sha":"aa48320",'
    '"date":"2026-09-10T10:44:08Z","notes":"메모","size":52428800}');
  expect(info.build, 26);
  expect(info.sizeText, '50.0 MB');
});

test('필드가 빠져도 견딘다', () {
  final info = UpdateInfo.parse('{"version":"0.2.0"}');
  expect(info.build, 0);
  expect(info.builtAt, isNull);
});

test('빌드 번호가 클 때만 새 버전', () {
  expect(UpdateService.isNewer(current: 2, latest: 26), isTrue);
  expect(UpdateService.isNewer(current: 26, latest: 26), isFalse);
  expect(UpdateService.isNewer(current: 27, latest: 26), isFalse);
});
```

---

## 7. 적용 체크리스트

- [ ] 리포가 PUBLIC인가
- [ ] 서명 키 4개 secret 등록, `key.properties`·`*.jks` gitignore 확인
- [ ] 워크플로: `--build-number=${{ github.run_number }}`, `latest.json` 생성, 두 파일 업로드, `paths-ignore`
- [ ] `pubspec.yaml`에 `package_info_plus`, `path_provider`
- [ ] `update_service.dart`의 `repo` · `apkName` · 채널 이름을 프로젝트에 맞게 수정
- [ ] 매니페스트에 `INTERNET` + `REQUEST_INSTALL_PACKAGES` + FileProvider, `res/xml/file_paths.xml`
- [ ] `MainActivity.kt`의 패키지명과 채널 이름 일치
- [ ] 설정 화면에 진입점 추가
- [ ] `flutter analyze` / `flutter test` / **`flutter build apk --release`**(매니페스트 병합·Kotlin 컴파일 확인)
- [ ] 푸시 → CI 성공 → `curl -sL https://github.com/<OWNER>/<REPO>/releases/download/latest/latest.json`으로 값 확인
- [ ] 폰에서 「설정 → 앱 업데이트」 → 새 빌드 표시 → 내려받기 → 설치 화면까지 확인

---

## 8. 자주 걸리는 곳

| 증상 | 원인 |
|---|---|
| 확인 누르면 네트워크 오류 | 릴리스 빌드에 `INTERNET` 권한 없음 |
| `latest.json`을 404로 못 읽음 | 아직 새 워크플로가 한 번도 안 돌았거나, 파일 이름·태그 불일치 |
| 늘 "새 빌드 있음" | 정상. 로컬 빌드는 pubspec의 작은 빌드 번호를 쓴다 |
| 설치 화면이 안 뜸 | 「출처를 알 수 없는 앱 설치」 미허용 → 설정 화면을 연 뒤 다시 「설치」 |
| 설치 중 "앱이 설치되지 않음" | 기존 앱과 **서명 키가 다름**. 지우고 새로 설치해야 한다 |
| 매니페스트 병합 실패 | FileProvider authority가 다른 플러그인과 겹침 |
| 문서만 고쳤는데 업데이트 알림 | `paths-ignore` 누락 |
