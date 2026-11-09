#!/usr/bin/env python3
"""기획표 → Grok 집필 요청문. python3 tools/make_write_prompt.py data/plans/<묶음>.json [편id...] → data/review/<id>_write_prompt.md"""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
tpl = re.search(r'```\n(.*?)\n```', (ROOT / 'tools/prompts/write_grok.md').read_text(encoding='utf-8'), re.S).group(1)
LEVEL = {'R0': '왕초보(턴당 1문장, 가끔 2문장 · 4~8단어 — 쉬운 단어로 너무 짧지 않게)', 'R1': '초보(턴당 1~2문장, 쉬운 말)', 'R2': '중급(턴당 1~2문장, 자연스러운 구어)', 'R3': '고급(턴당 1~3문장, 감정·뉘앙스)', 'R4': '최상급(턴당 1~3문장, 복문·완곡 표현·말끝 흐리기 — 태국 사람끼리 하는 말 그대로, 관용구·속담·줄임말까지)'}
LEN = {'R0': '1문장(가끔 2문장), 4~8단어, 독음 8~14음절 — 단어 하나짜리 대답 금지', 'R1': '1~2문장(독음 20음절 안팎)', 'R2': '1~2문장', 'R3': '1~3문장', 'R4': '1~3문장(긴 턴은 복문으로)'}
TURNS = {'R0': 8, 'R1': 8, 'R2': 10, 'R3': 13, 'R4': 14}
REG = {'polite': '존댓말(ครับ/ค่ะ)', 'casual': '반말(친구·연인)', 'mixed': '존댓말로 시작해 반말로 넘어감', 'chat': '채팅(LINE 말투, 짧게)'}
TT = {'chaos': '현실에서 있을 법한 꼬임 하나(주문이 바뀜·약속 장소를 서로 다르게 앎·단톡방에 잘못 보냄 정도) — 과장된 소동·우연의 연속·비현실적 사건 금지.',
      'slip': '말실수(성조·어미·직역) 하나와 상대의 정정 — 일상 대화 흐름 안에서 가볍게.',
      'reveal': '작은 의외 사실이 드러남(알고 보니 같은 동네·이미 계산함 정도) — 짧게.',
      'emotion': '심쿵 — 상대가 마음을 들키는 한 줄(말끝 흐리기·여운)이 핵심, 설명하지 말 것.',
      'ignore': '예상 밖의 무심한 대답·읽씹 정도의 엇갈림.'}
SHORT = '--short' in sys.argv  # 한 줄 기획(규칙은 방에 한 번 — tools/prompts/write_rules_grok.md, 2026-11-09 프롬프트 최소화)
plans = json.load(open(sys.argv[1], encoding='utf-8'))
want = {a for a in sys.argv[2:] if not a.startswith('--')}
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
    if SHORT:
        sp = ', '.join(f"{k}={'학습자 {name}' if v == '{name}' else v}" for k, v in p['speakers'].items())
        text = (f"[{p['id']}] {sp} | {p['where']} | {p['scene']} | {REG.get(p['register'], p['register'])} | {region} | {p['twist_type']}@{p['twist']} | "
                f"카오스: {p['chaos']} | 심쿵: {p['heart']} | 목표: {'·'.join(p['targets'])} | {n}턴")
    out = ROOT / f"data/review/{p['id']}_write_prompt.md"
    out.write_text(text, encoding='utf-8')
    print(out)
