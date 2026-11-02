#!/usr/bin/env python3
"""편 JSON → Grok 재작성 프롬프트 파일(data/review/<편id>_grok_rewrite_prompt.md). 2026-11-03.
  python tools/make_rewrite_prompt.py <편.json> [...]
틀은 tools/prompts/rewrite_grok.md 의 코드 블록. 전송은 tools/grok_send.py <프롬프트> <저장파일> --tab project/<태국어 방>."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TPL = ROOT / 'tools/prompts/rewrite_grok.md'
OUT = ROOT / 'data/review'
ROLE = {'survival': 'B = 점원·기사 등 현지인(여, 공손)', 'short': 'B = 태국 친구', 'long': 'B = 태국 친구', 'chat': 'B = 채팅 상대'}
REG = {'polite': '존댓말(ครับ/ค่ะ)', 'casual': '반말(친구 사이, 조사 นะ/อะ/ดิ)', 'chat': '채팅 반말+줄임·이모지·555', 'mixed': '처음 존댓말 → 친해지며 반말'}


def main():
    tpl = re.search(r'```\n(.*?)```', TPL.read_text(encoding='utf-8'), re.S).group(1)
    OUT.mkdir(parents=True, exist_ok=True)
    for a in sys.argv[1:]:
        ep = json.load(open(a, encoding='utf-8'))
        who = ep.get('speakers', {})
        roles = 'A = 학습자(외국인, 이름 비고정 {name}, 남성 기준), ' + (f"B = {who.get('B')}" if who.get('B') and who.get('B') != '{name}' else ROLE.get(ep.get('kind'), 'B = 태국 사람'))
        lines = '\n'.join(f"{t['num']} {t['speaker']}: {t['th']} / {t['ko']}" for t in ep['turns'])
        text = tpl.format(code=ep['id'], roles=roles, scene=ep.get('scene', ''), register=REG.get(ep.get('register'), ep.get('register', '')),
                          n=len(ep['turns']), targets='·'.join(ep.get('expressions', [])[:5]), twist=ep.get('twist', ''), lines=lines)
        p = OUT / f"{ep['id']}_grok_rewrite_prompt.md"
        p.write_text(text, encoding='utf-8')
        print(p)


if __name__ == '__main__':
    main()
