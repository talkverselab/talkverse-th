#!/usr/bin/env python3
"""언어감각 외울 대화 — Grok 답(data/review/sense/<급>_write.md)을 assets/data/grammar/sense_course.json 의 memorize 회차에 넣는다(2026-11-19).
  ~/venvs/th/bin/python tools/sense_import.py [L1 ...]   (없으면 답이 있는 급 전부)
Grok 문장은 그대로 넣는다(회화 원칙 2026-11-18). 손대는 것 = 형식(줄 나누기·{말|번호} 짝 검사)·독음(rd_th)뿐.
태국어·한국어의 {…|n} 번호가 어긋나면 경고만 한다(고칠 곳은 Grok 에 다시 요청)."""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import rd_th  # noqa: E402

P = ROOT / 'assets/data/grammar/sense_course.json'
MARK = re.compile(r'\{([^|}]+)\|(\d+)\}')
LINE = re.compile(r'^\s*\**(\d+)[.)]?\s*\**\s*([^:：/]{1,20}?)\s*[:：]\s*(.+)$')


def plain(s):
    return MARK.sub(lambda m: m.group(1), s)


def parse(text):
    note, rows, foot, in_foot = '', [], [], False
    for raw in text.split('\n'):
        line = raw.strip().strip('`')
        if not line:
            continue
        if re.match(r'^(안내)\s*[:：]', line):
            note = re.split(r'[:：]', line, 1)[1].strip()
            continue
        if re.match(r'^(참고)\s*[:：]?', line):
            in_foot = True
            rest = re.sub(r'^참고\s*[:：]?\s*', '', line)
            if rest:
                foot.append(rest.lstrip('·-• ').strip())
            continue
        if in_foot:
            foot.append(line.lstrip('·-•0123456789.) ').strip())
            continue
        m = LINE.match(line)
        if m and ' / ' in m.group(3):
            th, ko = [x.strip() for x in m.group(3).split(' / ', 1)]
            rows.append({'who': m.group(2).strip(), 'th': th, 'ko': ko})
    return note, rows, [f for f in foot if f]


def main():
    want = set(sys.argv[1:])
    d = json.loads(P.read_text(encoding='utf-8'))
    for lv in d['levels']:
        if want and lv['id'] not in want:
            continue
        f = ROOT / f"data/review/sense/{lv['id']}_write.md"
        if not f.exists():
            continue
        note, rows, foot = parse(f.read_text(encoding='utf-8'))
        if len(rows) < 8:
            print(lv['id'], '건너뜀 — 대화 줄', len(rows))
            continue
        for r in rows:
            a = sorted(n for _, n in MARK.findall(r['th']))
            b = sorted(n for _, n in MARK.findall(r['ko']))
            if not set(b) <= set(a):
                print('  ⚠', lv['id'], '번호 어긋남', a, b, r['th'][:40])
            r['rd'] = rd_th.rd(plain(r['th']))
        ls = next(x for x in lv['lessons'] if x['kind'] == 'memorize')
        ls['note'], ls['sentences'], ls['footnotes'] = note, [{'who': r['who'], 'th': r['th'], 'rd': r['rd'], 'ko': r['ko']} for r in rows], foot
        print(lv['id'], '대화', len(rows), '참고', len(foot), '안내', bool(note))
    P.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding='utf-8')


if __name__ == '__main__':
    main()
