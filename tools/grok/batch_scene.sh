#!/bin/zsh
# batch_scene.sh <편id...> — Grok 장면 컷 4장씩(이미 있으면 건너뜀, 한도면 멈춤). 터널: ssh -fN -L 9225:127.0.0.1:9225 macmini4. 고정 방에 시트가 있으므로 첨부는 GROK_ATTACH=1 일 때만
cd ~/talkverse/th
for id in "$@"; do
  [ -f data/review/scene/$id/img4.jpg ] && { echo "$id skip"; continue; }
  att=""
  [ -n "$GROK_ATTACH" ] && [ -f data/review/${id}_scene_prompt.att ] && att=$(cat data/review/${id}_scene_prompt.att)
  r=$(/usr/bin/python3 tools/grok/gk.py data/review/${id}_scene_prompt.md data/review/scene/${id}.md ${att:+--attach "$att"} --img data/review/scene/$id 2>&1 | tail -1)
  echo "$id $r $(ls data/review/scene/$id 2>/dev/null | wc -l)"
  case "$r" in LIMIT*) break;; esac
done
echo ALLDONE
