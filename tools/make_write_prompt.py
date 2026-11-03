#!/usr/bin/env python3
"""기획표 → Grok 집필 요청문. python3 tools/make_write_prompt.py data/plans/<묶음>.json [편id...] → data/review/<id>_write_prompt.md"""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
tpl = re.search(r'```\n(.*?)\n```', (ROOT / 'tools/prompts/write_grok.md').read_text(encoding='utf-8'), re.S).group(1)
LEVEL = {'R0': '왕초보(턴당 아주 짧게, 1문장·2~5단어)', 'R1': '초보(턴당 1~2문장, 쉬운 말)', 'R2': '중급(턴당 1~2문장, 자연스러운 구어)', 'R3': '고급(턴당 1~3문장, 감정·뉘앙스)'}
LEN = {'R0': '1문장, 2~5단어', 'R1': '1~2문장(독음 20음절 안팎)', 'R2': '1~2문장', 'R3': '1~3문장'}
TURNS = {'R0': 8, 'R1': 8, 'R2': 10, 'R3': 13}
REG = {'polite': '존댓말(ครับ/ค่ะ)', 'casual': '반말(친구·연인)', 'mixed': '존댓말로 시작해 반말로 넘어감', 'chat': '채팅(LINE 말투, 짧게)'}
TT = {'chaos': '일이 걷잡을 수 없이 커지는 장면 — 끝으로 갈수록 사람·물건·오해가 늘어나게, 줄이지 말고 더 세게.',
      'slip': '말실수(성조·어미·직역) 하나가 판을 뒤집는 장면 — 실수를 상대가 받아치며 웃음이 커지게.',
      'reveal': '숨기던 마음·사실이 들키는 장면 — 들키는 순간을 짧고 세게.',
      'emotion': '심쿵 — 상대가 마음을 들키는 한 줄(말끝 흐리기·여운)이 핵심, 설명하지 말 것.',
      'ignore': '한쪽이 완전히 엉뚱하게 반응(무시·딴소리)해서 웃긴 장면.'}
plans = json.load(open(sys.argv[1], encoding='utf-8'))
want = set(sys.argv[2:])
for p in plans:
    if want and p['id'] not in want:
        continue
    region = p['id'].split('_')[0].upper()
    roles = ', '.join(f"{k} = {'학습자(외국인, 이름 {name}, 남성 기준)' if v == '{name}' else v}" for k, v in p['speakers'].items())
    n = p.get('turns') or TURNS[region]
    text = (tpl.replace('{code}', p['id']).replace('{roles}', roles).replace('{where}', p['where']).replace('{scene}', p['scene'])
            .replace('{register}', REG.get(p['register'], p['register'])).replace('{level}', LEVEL[region]).replace('{twist_type}', p['twist_type'])
            .replace('{twist_rule}', TT[p['twist_type']]).replace('{twist}', str(p['twist'])).replace('{chaos}', p['chaos']).replace('{heart}', p['heart'])
            .replace('{n}', str(n)).replace('{targets}', '·'.join(p['targets'])).replace('{length}', LEN[region]))
    out = ROOT / f"data/review/{p['id']}_write_prompt.md"
    out.write_text(text, encoding='utf-8')
    print(out)
