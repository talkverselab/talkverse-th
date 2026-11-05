#!/bin/zsh
# art_push.sh <그림 저장소 복제본 폴더> — 커밋을 만든 뒤 실행. 다른 세션과 겹치면 rebase 후 재시도. 토큰은 화면에 찍지 않는다(eval 금지).
cd "$1" || exit 1
T=$(gh auth token --user talkverselab)
g() { git -c credential.helper= -c "credential.helper=!f(){ echo username=x-access-token; echo password=$T; };f" "$@"; }
for i in 1 2 3 4 5 6; do
  g fetch -q origin main || { echo fetch-fail; sleep 5; continue; }
  git rebase -q origin/main >/dev/null 2>&1 || { git rebase --abort; echo rebase-fail; break; }
  if g push -q origin HEAD:main 2>/dev/null; then echo "pushed try $i"; break; fi
  sleep 3
done
g fetch -q origin main
git log --oneline origin/main -2 | cut -c1-70
