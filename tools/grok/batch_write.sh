#!/bin/zsh
# batch_write.sh <plan.json> <id...> — Grok 집필 → 편 JSON
cd ~/talkverse/th
plan=$1; shift
for id in "$@"; do
  r=$(/usr/bin/python3 tools/grok/gk.py data/review/${id}_write_prompt.md data/review/${id}_write.md 2>&1 | tail -1)
  echo "$id $r"
  case "$r" in OK*) python3 tools/build_from_write.py $plan $id data/review/${id}_write.md;; LIMIT*|NOTEXPERT*) break;; esac
done
echo ALLDONE
