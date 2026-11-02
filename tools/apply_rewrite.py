#!/usr/bin/env python3
"""Grok 재작성 답(번호 화자: 태국어 / 한국어 [/ 이유] [❓])을 편 JSON 에 반영 — 태국어판. rd 는 비운다(검사기 --fix-rd 로 채움). ❓ 줄은 turn["check"]=True 로 표시(사람이 다시 봄).
python tools/apply_rewrite.py <편.json> <답.md> [--note "..."]"""
import json, re, sys
from pathlib import Path
def main():
    jp, mp = Path(sys.argv[1]), Path(sys.argv[2])
    note = sys.argv[sys.argv.index('--note') + 1] if '--note' in sys.argv else ''
    ep = json.load(open(jp, encoding='utf-8'))
    kick = ''
    got = {}
    line_tail = {}
    for line in open(mp, encoding='utf-8'):
        line = line.strip()
        m = re.match(r'^(\d+)\s+([A-D])\s*[:：]\s*(.+?)\s*/\s*(.+?)(?:\s*/\s*(.*))?$', line)
        if m:
            got[int(m.group(1))] = (m.group(2), m.group(3).strip(), m.group(4).strip())
            line_tail[int(m.group(1))] = m.group(5) or ''
        elif line.startswith('킥'):
            kick = line.split(':', 1)[-1].split('：', 1)[-1].strip()
    if len(got) < len(ep['turns']) * 0.8:
        print(f'SKIP {ep["id"]}: 답 줄 {len(got)}/{len(ep["turns"])}'); return 2
    changed = 0
    for t in ep['turns']:
        g = got.get(t['num'])
        if not g: continue
        sp, th, ko = g
        flag = '❓' in th or '❓' in ko or '❓' in (line_tail.get(t['num']) or '')
        th = th.replace('❓', '').strip(); ko = ko.replace('❓', '').strip()
        if sp != t['speaker']:
            print(f'  화자 불일치 턴 {t["num"]}: {t["speaker"]}→{sp} (유지)')
        if th != t['th']:
            t['th'] = th; t['rd'] = ''; changed += 1
        if flag:
            t['check'] = True
        if ko != t['ko']:
            t['ko'] = ko
    ep.setdefault('review', {})['enrich'] = f'{mp.name}: {changed}턴 교체' + (f' · 킥: {kick}' if kick else '') + (f' · {note}' if note else '')
    json.dump(ep, open(jp, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'OK {ep["id"]}: {changed}/{len(ep["turns"])}턴 교체')
    return 0
if __name__ == '__main__':
    sys.exit(main())
