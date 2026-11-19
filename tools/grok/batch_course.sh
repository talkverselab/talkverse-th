#!/bin/zsh
# batch_course.sh <키...> — 「내 코스」 스크립트 Grok 대사(빠른 모드). 25편마다 새 방(uk 11-19: 대사는 20~30편마다 새 방, 장면 방과 따로).
# 방 id = tools/grok/room_th_course.txt. 새 방 첫 편은 --new --keep 으로 보내고 그 탭 주소에서 방 id 를 읽어 둔다.
cd ~/talkverse/th
D=data/review/course; n=0
for k in "$@"; do
  [ -s $D/${k}_write.md ] && { echo "$k skip"; continue; }
  if (( n % 25 == 0 )); then
    r=$(GROK_ROOM_FILE=room_th_course.txt /usr/bin/python3 tools/grok/gk.py $D/${k}_prompt.md $D/${k}_write.md --new --keep 2>&1 | tail -2 | tr '\n' ' ')
    tab=$(echo "$r" | grep -o 'KEPT [0-9A-F]*' | cut -d' ' -f2)
    room=$(curl -s 127.0.0.1:9259/json | /usr/bin/python3 -c "import json,sys,re;print(next((re.search(r'/c/([0-9a-f-]+)',t['url']) or [None,''])[1] for t in json.load(sys.stdin) if t['id']=='$tab'))" 2>/dev/null)
    [ -n "$room" ] && echo $room > tools/grok/room_th_course.txt && echo "새 방 $room"
    [ -n "$tab" ] && curl -s 127.0.0.1:9259/json/close/$tab >/dev/null
  else
    r=$(GROK_ROOM_FILE=room_th_course.txt /usr/bin/python3 tools/grok/gk.py $D/${k}_prompt.md $D/${k}_write.md 2>&1 | tail -1)
  fi
  n=$((n+1))
  echo "$k $r"
  case "$r" in *LIMIT*|*NOTFAST*) break;; esac
done
echo ALLDONE
