#!/bin/bash
# iOS 배포(맥미니): 아카이브(서명 없음) → App Store 용 자동 서명 export → App Store Connect 업로드(Xcode 에 로그인된 Apple ID 사용)
#   → PC OneDrive(D:\OneDrive\app project\thai_universe\ios\)에 .ipa 백업.
#   bash tools/ios_release.sh [--no-build] [--no-upload] [--build <번호>]
# 빌드 번호(CFBundleVersion)는 업로드마다 커져야 한다 — 기본값은 KST 시각(yymmddHHMM, 예 2611011230).
# 전제: Xcode 에 Apple ID 로그인·팀 QP8QRMA9CC, App Store Connect 에 앱 레코드(번들 ID com.talkverse.thaiUniverse) 존재.
#   레코드가 없으면 업로드가 missingApp 으로 실패한다(export 까지는 된다 — 번들 ID 는 그때 포털에 자동 등록).
# 원본: ~/interval-camera/tools/ios_release.sh (언어앱 공통, 2026-11-01)
set -euo pipefail
PC="pc"  # ~/.ssh/config 별칭
TEAM="QP8QRMA9CC"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH=/opt/homebrew/bin:$PATH
APP="$(grep '^name:' pubspec.yaml | awk '{print $2}')"
ARCHIVE="build/ios/archive/Runner.xcarchive"
OUT="build/ios/ipa_appstore"
BUILD="$(TZ=Asia/Seoul date +%y%m%d%H%M)"
for ((i = 1; i <= $#; i++)); do [[ "${!i}" == "--build" ]] && { j=$((i + 1)); BUILD="${!j}"; }; done

if [[ " $* " != *" --no-build "* ]]; then
  flutter build ipa --release --export-method app-store --no-codesign --build-number="$BUILD"
  # --no-codesign 아카이브엔 entitlements 가 안 들어가 export 한 ipa 에서 Sign in with Apple 이 빠진다 → ad-hoc 서명으로 심어 둔다(APP_GUIDE §7, 한자 빌드 51 확인)
  codesign --force --deep -s - --entitlements ios/Runner/Runner.entitlements "$ARCHIVE/Products/Applications/Runner.app" && echo "ad-hoc 서명 + entitlements 적용"
fi
[ -d "$ARCHIVE" ] || { echo "아카이브 없음: $ARCHIVE" >&2; exit 1; }
# --no-build 때는 아카이브에 박힌 빌드 번호를 쓴다(백업 파일명·안내가 실제와 어긋나지 않게)
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' "$ARCHIVE/Info.plist" 2>/dev/null || echo "$BUILD")"

plist() {  # $1 = export|upload
  cat <<P
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$1</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$TEAM</string>
  <key>uploadSymbols</key><true/>
</dict></plist>
P
}
plist export > build/ios/ExportOptions_export.plist
xcodebuild -exportArchive -allowProvisioningUpdates -archivePath "$ARCHIVE" \
  -exportOptionsPlist build/ios/ExportOptions_export.plist -exportPath "$OUT" | grep -E "error|EXPORT" || true
# IPA 파일명은 pubspec name 이 아니라 Xcode PRODUCT_NAME(앱마다 다름) → 글롭으로 찾는다
IPA="$(ls "$OUT"/*.ipa 2>/dev/null | head -1)"
[ -n "$IPA" ] || { echo "export 실패($OUT 에 .ipa 없음)" >&2; exit 1; }

VER="$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)"
REV="$(git rev-parse --short HEAD)"
STAMP="$(TZ=Asia/Seoul date +%Y%m%d_%H%M)"
NAME="${APP}_${VER}_${BUILD}_${STAMP}_${REV}_appstore.ipa"
if ssh -o ConnectTimeout=10 "$PC" "powershell -NoProfile -Command \"New-Item -ItemType Directory -Force -Path 'D:\\OneDrive\\app project\\$APP\\ios' | Out-Null\"" \
   && scp -q "$IPA" "$PC:D:/OneDrive/app project/$APP/ios/$NAME"; then
  echo "백업 완료: OneDrive/app project/$APP/ios/$NAME"
else
  echo "PC 백업 실패(PC 꺼짐?) — $IPA 는 남아 있다. 나중에 다시 복사할 것." >&2
fi

if [[ " $* " != *" --no-upload "* ]]; then
  plist upload > build/ios/ExportOptions_upload.plist
  if xcodebuild -exportArchive -allowProvisioningUpdates -archivePath "$ARCHIVE" \
      -exportOptionsPlist build/ios/ExportOptions_upload.plist -exportPath build/ios/upload_log 2>&1 | grep -E "error|EXPORT|Upload"; then
    echo "App Store Connect 업로드 끝(빌드 $BUILD) — 처리(5~15분) 뒤 TestFlight 에 나타난다."
  else
    echo "업로드 실패 — App Store Connect 에 앱 레코드(번들 ID com.talkverse.thaiUniverse)가 있는지 확인. 상세: 최신 /var/folders/**/Runner_*.xcdistributionlogs/IDEDistribution.standard.log" >&2
    exit 1
  fi
fi
