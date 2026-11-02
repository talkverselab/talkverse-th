#!/usr/bin/env python3
"""Grok 집필 답 → 편 JSON. python3 tools/build_from_write.py data/plans/<묶음>.json <편id> data/review/<id>_write.md"""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
plans = {p['id']: p for p in json.load(open(sys.argv[1], encoding='utf-8'))}
p = plans[sys.argv[2]]
ans = open(sys.argv[3], encoding='utf-8').read()
region = p['id'].split('_')[0].upper()
island = p['id'].split('_')[1]
# 한 턴이 여러 줄로 오면(줄 머리가 '/') 앞 줄에 이어 붙인다
_lines = []
for raw in ans.splitlines():
    if raw.strip().startswith('/') and _lines:
        _lines[-1] += ' ' + raw.strip()
    elif raw.strip():
        _lines.append(raw.strip())
turns = []
for line in _lines:
    m = re.match(r'^\s*\**(\d+)\**\.?\s*([A-D])\s*[:：]\s*(.+)$', line.strip())
    if not m:
        continue
    parts = [x.strip() for x in m.group(3).split(' / ')]
    if len(parts) < 2:
        continue
    th, ko = parts[0], parts[1]
    note = parts[2] if len(parts) > 2 else ''
    new = [w.strip() for w in re.split(r'[,，、]', parts[3])] if len(parts) > 3 else []
    t = {'num': int(m.group(1)), 'speaker': m.group(2), 'th': th.replace('❓', '').strip(), 'rd': '', 'ko': ko, 'note': note, 'tags': [], 'new': [w for w in new if w][:3]}
    if '❓' in th:
        t['check'] = True
    if p['kind'] == 'chat':
        t['ui'] = 'bubble'
    turns.append(t)
if not turns:
    sys.exit(f'SKIP {p["id"]}: 줄을 못 읽음')
tw = min(p['twist'], len(turns))
turns[tw - 1]['tags'].append('twist')
ep = {'id': p['id'], 'region': region, 'island': island, 'kind': p['kind'], 'draft': True, 'purpose': [island], 'domain': [island],
      'title': p['title'], 'emoji': p['emoji'], 'scene': p['scene'], 'where': p['where'], 'speakers': p['speakers'], 'register': p['register'],
      'twist': tw, 'twist_type': p['twist_type'], 'flags': p.get('flags', []), 'goal': '', 'expressions': p['targets'], 'turns': turns,
      'review': {'grok_write': f'data/review/{p["id"]}_write.md'}}
rec = re.search(r'추천 표현\s*[:：]\s*(.+)', ans, re.S)
if rec:
    ep['review']['recommended'] = rec.group(1).strip()[:300]
out = ROOT / f'assets/data/dialogues/{region}/{island}/{p["id"]}.json'
out.parent.mkdir(parents=True, exist_ok=True)
json.dump(ep, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('OK', out.relative_to(ROOT), len(turns), '턴', sum(1 for t in turns if t.get('check')), '❓')
