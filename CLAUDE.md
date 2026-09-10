# CLAUDE.md — talkverselab/talkverse-th

이 폴더에서 작업하는 모든 세션이 먼저 읽는 규칙. **빌드·배포를 건드리기 전에 반드시 확인할 것.**

## 1. 서명 (가장 자주 사고 나는 곳)

이 앱은 GitHub 릴리스로 **앱 안에서 스스로 업데이트**한다.
폰에 이미 깔린 앱과 **서명 키가 같아야만** 덮어쓰기 설치가 된다.

### 쓰는 키 — 새로 만들지 말 것

- 이 앱은 자체 업로드 키를 쓴다. 로컬 `android/app/upload-keystore.jks` + `android/key.properties`(둘 다 gitignore),
  CI는 리포 시크릿 `KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` / `KEY_PASSWORD` / `KEY_ALIAS`로 복원한다.

### 절대 하지 말 것

- **새 키스토어를 만들지 말 것.** 서명이 바뀌면 폰에서 앱을 지웠다 다시 깔아야 하고, **학습 기록이 전부 사라진다.**
- CI의 `Restore signing key` 단계를 지우거나, `build.gradle.kts`의 release 서명을
  `signingConfigs.getByName("debug")` 로 되돌리지 말 것.
  GitHub 러너는 빌드할 때마다 debug 키를 **새로 만들어** 서명이 매번 달라진다.
  (2026-09-10에 실제로 겪은 문제 — 17개 앱 설치가 전부 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`로 실패했다.)
- `android/key.properties`, `android/app/signing-key.jks`를 커밋하지 말 것 (`.gitignore`에 있음).

### 설치가 실패하면

```
INSTALL_FAILED_UPDATE_INCOMPATIBLE: signatures do not match
```

→ 앱을 지우지 말고 **서명부터 확인**한다:

```bash
apksigner verify --print-certs <apk> | grep SHA-1   # 9cc4bc932638be43a3982df20b71c4750288476b 여야 한다
```

## 2. 배포 흐름

- `master`(또는 기본 브랜치) 푸시 → GitHub Actions(`.github/workflows/release.yml`)가
  서명된 APK와 `latest.json`을 `latest` 릴리스에 올린다.
- **빌드 번호 = 워크플로 실행 번호**(`--build-number=${{ github.run_number }}`).
  앱은 자기 빌드 번호와 `latest.json`의 `build`를 견주어 새 빌드를 판단한다.
  로컬 `flutter build apk`로 만든 APK는 pubspec의 작은 번호를 써서 앱이 늘 "새 빌드 있음"으로 보인다 — 정상.
- `**.md`만 고친 푸시는 빌드하지 않는다(`paths-ignore`). 헛된 업데이트 알림 방지.
- **폰 업데이트**: 앱 → 설정(프로필) 화면 → **「앱 업데이트」** → 내려받아 설치. 케이블·adb 불필요.
  첫 설치 때 「출처를 알 수 없는 앱 설치」 허용이 한 번 필요하다(안드로이드 강제).

관련 파일: `lib/services/update_service.dart`, `lib/screens/update_screen.dart`,
`android/app/src/main/kotlin/**/MainActivity.kt`(설치 메서드 채널),
`android/app/src/main/res/xml/file_paths.xml`, `.github/workflows/release.yml`

구현 안내서: https://github.com/talkverselab/talkverse-th/blob/master/docs/in-app-update-via-github.md

## 3. 리포

- 이름은 **`talkverselab/talkverse-<언어코드>`** 로 통일(2026-09-10). 옛 이름(`th-universe` 등)은 리다이렉트되지만
  remote는 새 이름으로 바꿔 둘 것: `git remote set-url origin https://github.com/talkverselab/talkverse-th.git`
- **공개(PUBLIC) 저장소**다. 앱이 토큰 없이 APK를 받으려면 공개여야 한다.
- 다운로드 허브: https://github.com/talkverselab/talkverse-releases

## 4. 공개 저장소라서 지킬 것

- **출처를 드러내지 말 것.** 자막·말뭉치 제공처 이름(스트리밍 서비스, 공개 자막 데이터셋 등), 책 이름·쪽수,
  드라마·영화 제목을 코드·에셋·문서·파일명·화면 문구 어디에도 남기지 않는다.
- 저작권 있는 원문(자막 대본, 원서 전사)을 리포에 넣지 않는다. 단어·빈도 통계만 쓰고 문장은 자체 제작한다.
- 새 파일을 추가할 때 위 두 가지를 먼저 확인할 것. 한 번 공개 커밋되면 히스토리에 남는다.
