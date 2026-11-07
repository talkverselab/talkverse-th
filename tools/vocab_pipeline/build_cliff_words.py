#!/usr/bin/env python3
"""절벽 단어 화면 데이터 → assets/data/wordsets/th_cliff_words.json (사용자 지시 2026-11-07, 모든 언어앱 공통).
  thvenv python tools/vocab_pipeline/build_cliff_words.py
입력: corpus/analysis_th_tiers.csv(로컬 전용, 단어·빈도 통계) · 단어장·뜻 모음 · cliff_meanings.json(keep=false 는 조각·인물 이름·비속어라 뺀다) · 회화 레마.
출력: words = 2,000위 안 단어 {r 순위, w, rd, ko, g 구간} · conv = 회화 전 편 레마 중 2,000위 밖이면서 단어장에 있는 것(등장 횟수순). 순위는 원래 순위를 그대로 둔다."""
import collections
import csv
import glob
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import rd_th  # noqa: E402

CLIFFS = [(109, 'R1'), (149, 'R2'), (295, 'R3'), (642, 'R4'), (2000, 'R5')]
NAMES = {'ฟ้า', 'ต้น', 'สุภา', 'วดี', 'ภรณ์'}
VP = ROOT / 'tools/vocab_pipeline'


def region(rank):
    return next(g for end, g in CLIFFS if rank <= end)


def main():
    rows = list(csv.DictReader(open(ROOT / 'corpus/analysis_th_tiers.csv', encoding='utf-8-sig')))[:2000]
    gloss = json.load(open(VP / 'cliff_meanings.json', encoding='utf-8'))
    M = {}
    for f in sorted(glob.glob(str(VP / '*meanings*.json')) + glob.glob(str(VP / 'obec/meanings*.json'))):
        if f.endswith('cliff_meanings.json'):
            continue
        for k, v in json.load(open(f, encoding='utf-8')).items():
            if v.get('ko'):
                M.setdefault(k, {'ko': v['ko'], 'rd': v.get('reading', '')})
    vocab = {}
    for e in json.load(open(ROOT / 'assets/data/vocab/th_vocab.json', encoding='utf-8'))['entries']:
        if e.get('ko'):
            vocab[e['th']] = {'ko': e['ko'], 'rd': e.get('reading', '')}
    M.update(vocab)
    drop = {w for w, g in gloss.items() if not g.get('keep')}
    words = []
    for x in rows:
        w, r = x['word'], int(x['rank'])
        if w in drop:
            continue
        m = M.get(w) or {'ko': gloss.get(w, {}).get('ko', ''), 'rd': ''}
        if not m['ko']:
            continue
        words.append({'r': r, 'w': w, 'rd': m['rd'] or rd_th.rd(w), 'ko': m['ko'].replace('❓', ''), 'g': region(r)})
    top = {x['word'] for x in rows}
    cnt = collections.Counter()
    for f in glob.glob(str(ROOT / 'assets/data/dialogues/R*/*/*.json')):
        for t in json.load(open(f, encoding='utf-8')).get('turns', []):
            for lem in t.get('lemmas', []):
                if len(lem) >= 2 and lem[1] not in top and lem[1] not in NAMES and lem[1] in vocab:
                    cnt[lem[1]] += 1
    conv = [{'w': w, 'rd': vocab[w]['rd'] or rd_th.rd(w), 'ko': vocab[w]['ko'], 'n': c} for w, c in cnt.most_common()]
    out = ROOT / 'assets/data/wordsets/th_cliff_words.json'
    json.dump({'_meta': '절벽 단어 화면용 · tools/vocab_pipeline/build_cliff_words.py', 'words': words, 'conv': conv},
              open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print(len(words), collections.Counter(w['g'] for w in words), 'conv', len(conv), out.stat().st_size)


if __name__ == '__main__':
    main()
