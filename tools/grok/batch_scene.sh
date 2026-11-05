#!/bin/zsh
# batch_scene.sh <편id...> — Grok 장면 컷 4장씩(이미 있으면 건너뜀, 한도면 멈춤). 터널: ssh -fN -o ExitOnForwardFailure=yes -L 19222:127.0.0.1:9222 macmini4
cd ~/talkverse/th
for id in "$@"; do
  [ -f data/review/scene/$id/img4.jpg ] && { echo "$id skip"; continue; }
  att=/tmp/grok_att/th/char_th_03_cast.jpg
  [ -f data/review/${id}_scene_prompt.att ] && att=$(cat data/review/${id}_scene_prompt.att)
  r=$(/usr/bin/python3 tools/grok/gk.py data/review/${id}_scene_prompt.md data/review/scene/${id}.md --attach "$att" --img data/review/scene/$id 2>&1 | tail -1)
  echo "$id $r $(ls data/review/scene/$id 2>/dev/null | wc -l)"
  case "$r" in LIMIT*) break;; esac
done
echo ALLDONE
