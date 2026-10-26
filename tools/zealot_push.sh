#!/bin/bash
# 가장 최근 release APK 를 Zealot(https://apps.talkverse.uk)에 올린다. 맥미니 전용.
#
#   tools/zealot_push.sh ["변경 내용 한 줄"]          # GitHub latest 릴리스의 APK(기본)
#   tools/zealot_push.sh --local ["변경 내용 한 줄"]  # 로컬 빌드 build/app/outputs/flutter-apk/app-release.apk
#
# 변경 내용을 주지 않으면 릴리스 메모(기본) 또는 최근 커밋 제목(--local)을 쓴다.
# 기본이 릴리스 APK 인 까닭: 빌드 번호 = 워크플로 실행 번호라서 폰에 깔린 앱보다 항상 크다.
# 로컬 빌드는 pubspec 의 작은 번호(+2)를 쓰므로 --build-number 를 릴리스보다 크게 주고 빌드해야 덮어 설치된다.
set -euo pipefail

APP_NAME="태국어유니버스"
REPO="talkverselab/talkverse-th"
REL="https://github.com/$REPO/releases/download/latest"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AAPT2="$(ls /opt/homebrew/share/android-commandlinetools/build-tools/*/aapt2 2>/dev/null | tail -1 || true)"

LOCAL=0
if [ "${1:-}" = "--local" ]; then LOCAL=1; shift; fi
NOTE="${1:-}"

META="$(curl -fsSL "$REL/latest.json")"
REL_BUILD="$(printf '%s' "$META" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)["build"])')"

if [ "$LOCAL" = 1 ]; then
  APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
  [ -f "$APK" ] || { echo "로컬 release APK 가 없습니다: $APK" >&2; exit 1; }
  [ -n "$NOTE" ] || NOTE="$(git -C "$ROOT" log -1 --pretty=%s)"
  if [ -n "$AAPT2" ]; then
    CODE="$("$AAPT2" dump badging "$APK" | sed -n "1s/.*versionCode='\([0-9]*\)'.*/\1/p")"
    if [ "$CODE" -le "$REL_BUILD" ]; then
      echo "버전 코드 $CODE 가 릴리스 빌드 $REL_BUILD 이하라 덮어 설치가 안 됩니다. --build-number 를 더 크게 주고 다시 빌드하세요." >&2
      exit 1
    fi
  fi
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  APK="$TMP/thai-universe-$REL_BUILD.apk"
  echo "릴리스 빌드 $REL_BUILD 내려받는 중…"
  curl -fsSL -o "$APK" "$REL/thai-universe-latest.apk"
  [ -n "$NOTE" ] || NOTE="$(printf '%s' "$META" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)["notes"])')"
fi

"$HOME/bin/zealot-upload" "$APK" "$APP_NAME" -c "$NOTE"
