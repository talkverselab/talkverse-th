#!/usr/bin/python3
"""감정 계획 검사(태국어). python3 tools/tts/check_plan.py [편id...]  (없으면 계획이 있는 편 전부) — 문제 있는 편만 출력하고 끝에 합계."""
import json, sys, os, re
import ttslib as L
V, EP = L.V, L.EP
norm = lambda s: re.sub(r'[\s…。、！？!?.,~♪「」\'"]|（[^）]*）|\([^)]*\)', '', s).replace('ฮ่าๆ', '').replace('555', '').replace('5555', '')
ids = sys.argv[1:] or L.planned()
bad = miss = 0
for ep in ids:
    f = f'{L.R}/data/tts/plan/{ep}.json'
    if not os.path.exists(f):
        miss += 1; print('없음', ep); continue
    errs = []
    try:
        P = json.load(open(f, encoding='utf-8'))
    except Exception as e:
        bad += 1; print(ep, 'JSON 오류', e); continue
    d = json.load(open(EP[ep], encoding='utf-8'))
    for k in d['speakers']:
        if k != 'A' and P.get('cast', {}).get(k) not in V['voices']:
            errs.append(f'cast {k}={P.get("cast", {}).get(k)}')
    used = set()
    for t in d['turns']:
        T = P.get('turns', {}).get(str(t['num']))
        if not T or not T.get('segs'):
            errs.append(f"턴 {t['num']} 없음"); continue
        for g in ('base', 'm', 'f'):
            X = T if g == 'base' else T.get(g)
            if not X:
                continue
            if g != 'base':
                miss_k = [k for k in ('text', 'rd', 'ko', 'segs') if not X.get(k)]
                if miss_k:
                    errs.append(f"턴 {t['num']} {g} 빠짐 {miss_k}"); continue
            want = t['th'] if g == 'base' else X['text']
            got = ''.join(s[1] for s in X['segs'])
            if norm(got) != norm(want):
                errs.append(f"턴 {t['num']} {g} 본문 다름: {got} / {want}")
            for s in X['segs']:
                if s[0] not in V['emotions']:
                    errs.append(f"턴 {t['num']} 감정 {s[0]}")
                if len(re.sub(r'[^\u0E00-\u0E7F]', '', s[-1])) < 2 and len(X['segs']) > 1:
                    errs.append(f"턴 {t['num']} 너무 짧은 조각 {s[-1]!r}")
                used |= set(re.findall(r'\{\w+\}', s[-1]))
    for ph in used - set(V['fill']) - set(P.get('fill', {})):
        errs.append('자리 채움 없음 ' + ph)
    if errs:
        bad += 1; print(ep, *errs[:8], sep='\n  ')
print('검사', len(ids), '문제', bad, '없음', miss)
