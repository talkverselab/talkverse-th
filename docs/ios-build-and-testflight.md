# Flutter 앱 iOS 빌드 → TestFlight (맥 없이, GitHub Actions만으로)

> 다른 언어 앱 리포에 그대로 옮겨 붙이는 안내서. 실제 동작 중인 구현: `talkverselab/talkverse-th`
> (`.github/workflows/ios-build.yml`, `.github/workflows/ios-testflight.yml`, `tools/ios/make_ios_cert.py`).
>
> **결과**: master 푸시 → GitHub의 macOS 러너가 Xcode로 빌드·서명 → TestFlight 업로드 → 아이폰의 TestFlight 앱에서 받음.
> 안드로이드의 「푸시 → 릴리스 APK → 앱 내 업데이트」에 해당하는 iOS 경로다.

---

## 0. 왜 맥미니를 안 쓰나

iOS 빌드는 Xcode(macOS)가 필요하지만 **GitHub Actions `macos-latest` 러너에 Xcode·CocoaPods·fastlane이 다 들어 있고,
공개 리포는 무료**다. 로컬 맥을 쓰려면 관리자 권한으로 `sudo xcodebuild -license accept` 를 한 번 해야 하고
(그전엔 `xcodebuild` 가 아예 안 돈다), Flutter·CocoaPods 설치, Apple ID 로그인(GUI), 아이폰 케이블 연결이 필요하다.
러너를 쓰면 이 전부가 필요 없다. 아이폰에는 앱을 직접 깔 수 없으니(사이드로딩 불가) **TestFlight가 앱 내 업데이트 역할**을 한다.

## 1. 전제

| 항목 | 내용 |
|---|---|
| Apple Developer Program | **유료 멤버십(연 99달러) 활성화** 필수. 활성화 전에는 App Store Connect 에 "Your Apple Account isn't enabled for App Store Connect" 가 뜬다 — 결제 후 24~48시간, 메일이 오면 됨. 일반 Apple ID(무료)로는 TestFlight 불가. |
| 리포 | 공개(PUBLIC)면 macOS 러너 무료. 비공개면 분당 요금(리눅스의 10배). |
| 번들 ID | `ios/Runner.xcodeproj/project.pbxproj` 의 `PRODUCT_BUNDLE_IDENTIFIER` (예: `com.talkverse.thaiUniverse`). 앱마다 고유. |

## 2. 프로젝트 쪽 준비 (한 번)

### 2-1. `ios/Runner/Info.plist` 권한 문구

말하기 연습(speech_to_text)이 있으면 **둘 다 없으면 앱이 죽는다**(심사도 거절):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>문장 말하기 연습에서 발음을 녹음해 판정합니다.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>말한 문장을 인식해 빠진 단어를 알려 줍니다.</string>
```

`CFBundleDisplayName` 이 홈 화면 이름이다(예: 태국어유니버스).

### 2-2. 안드로이드 워크플로가 iOS 변경에 돌지 않게

`release.yml` 의 `paths-ignore` 에 추가 (iOS 파일만 고쳐도 안드로이드가 다시 빌드돼 폰에 헛된 업데이트 알림이 뜨는 것 방지):

```yaml
    paths-ignore:
      - '**.md'
      - '.gitignore'
      - 'ios/**'
      - '.github/workflows/ios-*.yml'
```

## 3. 1단계 — 무서명 빌드 (계정 없이도 됨)

`.github/workflows/ios-build.yml` 을 그대로 복사. iOS 프로젝트가 러너에서 컴파일되는지 확인하는 용도이고,
결과물(무서명 `.ipa`)은 아티팩트로 14일 보관된다. 사이드로딩 도구(Sideloadly 등)로 무료 Apple ID 7일 서명 설치도 가능.

핵심 줄:

```yaml
runs-on: macos-latest
- uses: subosito/flutter-action@v2
  with: { channel: stable, cache: true }
- run: flutter pub get
- run: flutter build ios --release --no-codesign --build-number=${{ github.run_number }}
- run: |
    cd build/ios/iphoneos && mkdir -p Payload && cp -R Runner.app Payload/ && zip -qr app-unsigned.ipa Payload
- uses: actions/upload-artifact@v4
  with: { name: ios-unsigned-${{ github.run_number }}, path: build/ios/iphoneos/app-unsigned.ipa }
```

`ios/Podfile` 이 없어도 `flutter build ios` 가 만들어 준다. 태국어 앱은 이 단계가 첫 시도에 성공했다(6분).

## 4. 2단계 — 서명 + TestFlight

### 4-1. 사용자가 한 번 할 일 (App Store Connect)

1. **API 키**: appstoreconnect.apple.com → Users and Access → Integrations → App Store Connect API → Team Keys ⊕
   → 이름 `github-ci`, Access **Admin** → Generate. **Key ID**(10자)·**Issuer ID**(UUID)·`AuthKey_XXXX.p8` 다운로드(한 번만 가능).
2. **앱 레코드**: Apps → ⊕ New App → iOS · 이름 · 기본 언어 · 번들 ID(아래 도구가 등록한 뒤 목록에 뜸) · SKU.
   이건 API 로 못 만든다. 번들 ID 등록이 먼저다.

### 4-2. 인증서·번들 ID 발급 (Windows 에서, 맥 불필요)

`tools/ios/make_ios_cert.py` — API 키로 다음을 자동으로 한다:
번들 ID 등록 → openssl 로 개인키·CSR → Apple 에 배포 인증서(IOS_DISTRIBUTION) 발급 → `.p12` 묶기 → GitHub 시크릿용 `secrets.txt`.

```bash
python -m pip install PyJWT cryptography requests
python -X utf8 tools/ios/make_ios_cert.py --key-id XXXXXXXXXX --issuer-id <UUID> --p8 AuthKey_XXXXXXXXXX.p8 \
    --bundle-id com.talkverse.thaiUniverse --app-name "태국어유니버스" --out ./ios_secrets
```

- 배포 인증서는 계정당 **최대 2~3개**. 앱마다 새로 만들지 말고 **한 팀에 하나 만들어 모든 앱 리포가 같은 `.p12` 를 쓴다.**
  두 번째 앱부터는 `--bundle-id` 만 다르게 해서 번들 ID 등록만 하고, `.p12`·비밀번호 시크릿은 첫 앱 것을 복사한다.
- `private_key.pem`·`dist.p12` 는 리포에 넣지 말고 보관(OneDrive 등). `secrets.txt` 도 쓰고 나면 지운다.

### 4-3. GitHub 시크릿·변수

리포 Settings → Secrets and variables → Actions:

| 시크릿 | 값 |
|---|---|
| `ASC_KEY_ID` | API 키 ID |
| `ASC_ISSUER_ID` | Issuer ID |
| `ASC_KEY_P8_BASE64` | `.p8` 파일 base64 |
| `IOS_DIST_P12_BASE64` | `dist.p12` base64 |
| `IOS_DIST_P12_PASSWORD` | p12 비밀번호 |
| `APPLE_TEAM_ID` | 팀 ID(10자, 도구가 출력) |

Variables: `IOS_TESTFLIGHT_ENABLED` = `true` (이게 없으면 워크플로가 실행되지 않는다 — 시크릿 준비 전 실패 방지).

`gh` 로 한 번에:
```bash
while IFS='=' read -r k v; do gh secret set "$k" -R talkverselab/<repo> --body "$v"; done < ios_secrets/secrets.txt
gh variable set IOS_TESTFLIGHT_ENABLED -R talkverselab/<repo> --body true
```

### 4-4. 워크플로 (`ios-testflight.yml`) 가 하는 일

1. `.p12` 를 임시 키체인에 import (`security create-keychain` → `import` → `set-key-partition-list`)
2. `.p8` 를 `~/.appstoreconnect/private_keys/` 와 fastlane 용 JSON 으로
3. **fastlane sigh**(`get_provisioning_profiles`, API 키 인증)로 App Store 프로파일 발급·설치 → 이름을 `PROFILE_NAME` 으로
4. `flutter build ipa --export-options-plist` — **수동 서명**. Flutter 는 `FLUTTER_XCODE_*` 환경변수를 Xcode 빌드 설정으로 넘긴다:
   `FLUTTER_XCODE_CODE_SIGN_STYLE=Manual`, `FLUTTER_XCODE_DEVELOPMENT_TEAM`, `FLUTTER_XCODE_CODE_SIGN_IDENTITY="Apple Distribution"`,
   `FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER=$PROFILE_NAME`
5. `xcrun altool --upload-app --apiKey --apiIssuer` 로 TestFlight 업로드
6. `.ipa` 아티팩트 보관

빌드 번호는 안드로이드처럼 `github.run_number`(단조 증가 — TestFlight 도 같은 버전의 빌드 번호 중복을 거부한다).
버전은 `pubspec.yaml` 의 `version:` 앞부분.

### 4-5. 아이폰에서 받기

App Store Connect → 해당 앱 → TestFlight → Internal Testing 그룹 만들고 본인 Apple ID 추가 → 아이폰에 **TestFlight 앱** 설치 → 초대 수락.
이후 푸시마다 TestFlight 에 새 빌드 알림이 온다. 내부 테스터 배포는 심사 없음.

## 5. 이식 체크리스트

- [ ] Apple Developer Program 활성화 확인 (developer.apple.com/account → Membership)
- [ ] `Info.plist` 권한 문구, `CFBundleDisplayName`
- [ ] `release.yml` paths-ignore 에 `ios/**`
- [ ] `ios-build.yml` 복사 → 푸시 → 무서명 빌드 성공 확인
- [ ] API 키 발급, `make_ios_cert.py` 로 번들 ID·인증서 (팀 공용 인증서 재사용)
- [ ] App Store Connect 에 앱 레코드 생성
- [ ] 시크릿 6개 + 변수 1개 → `ios-testflight.yml` 복사 → 푸시 → 업로드 확인
- [ ] TestFlight 내부 테스터 등록

## 6. 자주 걸리는 곳

| 증상 | 원인 |
|---|---|
| "Your Apple Account isn't enabled for App Store Connect" | 유료 멤버십 미활성(처리 중) 또는 다른 Apple ID 로그인 |
| 맥에서 `xcodebuild` 가 라이선스 오류 | `sudo xcodebuild -license accept` 필요(관리자). 러너를 쓰면 무관 |
| 앱이 마이크 켤 때 즉시 종료 | `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` 누락 |
| 인증서 발급 실패 "maximum number of certificates" | 계정 한도 — 기존 인증서 재사용(`.p12` 공유)하거나 App Store Connect 에서 안 쓰는 것 폐기 |
| 프로파일 발급 실패 | 번들 ID 미등록, 또는 키체인의 인증서와 계정의 인증서가 다름 |
| altool 업로드 실패 "no suitable application records" | App Store Connect 에 앱 레코드가 아직 없음 (4-1의 2번) |
| 같은 빌드 번호 거부 | `github.run_number` 가 줄어들 일은 없지만, 워크플로를 새로 만들면 1부터 다시 시작 — 버전을 올리면 됨 |
| 안드로이드가 iOS 커밋마다 재빌드 | `release.yml` paths-ignore 누락 |
