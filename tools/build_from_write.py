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
# 답 형식이 흔들려도 읽는다: ① 한 줄 `번호 화자: 태국어 / 한국어 / 해설 / 새 단어` ② 번호 없는 `화자: …`
# ③ 다음 줄들이 '/' 로 시작 ④ `한국어:`·`해설:`·`새 단어:` 라벨 줄
recs = []
for raw in ans.splitlines():
    x = raw.strip()
    if not x:
        continue
    m = re.match(r'^\**(\d+)?\**\.?\s*([A-D])\s*[:：]\s*(.+)$', x)
    if m:
        recs.append({'num': int(m.group(1)) if m.group(1) else None, 'sp': m.group(2), 'parts': [y.strip() for y in m.group(3).split(' / ')]})
        continue
    if not recs:
        continue
    lab = re.match(r'^(한국어|해설|새\s*단어)\s*[:：]\s*(.*)$', x)
    if lab:
        recs[-1]['parts'].append(lab.group(2).strip())
    elif x.startswith('/'):
        recs[-1]['parts'] += [y.strip() for y in x.lstrip('/').split(' / ')]
turns = []
for i, r in enumerate(recs, 1):
    parts = [y for y in r['parts'] if y != '']
    if len(parts) < 2 or re.match(r'^추천', parts[0]):
        continue
    th, ko = parts[0], parts[1]
    # Grok 이 태국어 단어마다 띄어 쓴 줄(공백이 태국 글자 4자당 1개 이상)은 붙인다 — 555·숫자·{name} 앞뒤 공백은 둔다
    thai_chars = len(re.findall(r'[\u0E00-\u0E7F]', th))
    if thai_chars and th.count(' ') * 6 >= thai_chars:
        th = re.sub(r'(?<=[\u0E00-\u0E7F]) (?=[\u0E00-\u0E7F])', '', th)
    note = re.sub(r'^해설\s*\((.*)\)$|^해설\s*', r'\1', parts[2]).strip() if len(parts) > 2 else ''  # 뜻풀이 끝 괄호는 두고 「해설 (…)」 껍질만 벗긴다
    new = [w.strip() for w in re.split(r'[,，、]', re.sub(r'^새\s*단어\s*[:：]?', '', parts[3]))] if len(parts) > 3 else []
    t = {'num': len(turns) + 1, 'speaker': r['sp'], 'th': th.replace('❓', '').strip(), 'rd': '', 'ko': ko, 'note': note, 'tags': [], 'new': [w for w in new if w][:3]}
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
