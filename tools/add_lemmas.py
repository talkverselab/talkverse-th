#!/usr/bin/env python3
"""편 JSON 의 턴마다 `lemmas`(내용어 [표면형, 기본형, 한글 독음]) 를 채운다 — 문장 레마 ↔ 단어장 연결(사용자 지시 2026-11-04, 모든 언어앱 공통).
태국어는 어형 변화가 없어 기본형 = 표면형. 분석기 = pythainlp newmm(검사기 words_of 와 같은 토큰). 문장 끝 어조사·감탄·기능어는 뺀다.
단어장(th_vocab.json 표제어 + 교육부 표준 th_obec_basic.json)에 없는 레마는 빈도순 data/review/write/missing_lemmas.csv 로(uk 세션에 넘겨 단어·그림 제작).
  thvenv/bin/python tools/add_lemmas.py [편.json ...]   (인자 없으면 assets/data/dialogues/R*/*/*.json 전부)"""
import csv, glob, json, re, sys
from collections import Counter
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
import rd_th  # noqa: E402
from check_dialogues import words_of  # noqa: E402

# 어조사·감탄·웃음·기능어(단어장 칩으로 띄울 가치가 없는 것)
SKIP = set('''ครับ ค่ะ คะ ค่า คับ นะ น่ะ นะคะ นะครับ จ้ะ จ๊ะ จ้า จ๋า ล่ะ ละ สิ ซิ ซะ เถอะ เถิด เหอะ หรอ เหรอ หรือ ไหม มั้ย มั๊ย หรือเปล่า
อ่ะ อะ อ่า เอ่อ อืม อื้ม เอ๊ะ เอ๋ โอ้ โอ๊ย โอ้โห ว้าว เฮ้ย เฮ้ เห้ย ฮะ ฮ่า ฮ่าๆ แหม อุ๊ย เอ้า อ้าว แฮ่ เฮือก ๆ
ก็ ที่ ว่า และ แต่ กับ ของ ให้ ได้ จะ แล้ว ๆ ล่ะ เลย อะไร ไง ยังไง น่า หรอก งั้น เนี่ย นี่ นั่น โน่น มั้ง ดิ ป่ะ ปะ ฟ้า ต้น'''.split())
LAUGH = re.compile(r'^5{3,}$')


def lemmas_of(text):
    out = []
    for w in words_of(text):
        if w in SKIP or LAUGH.match(w) or len(w) < 2 and w not in ('ดี', 'ไป', 'มา'):
            continue
        out.append([w, w, rd_th.rd(w)])
    return out


def load_db():
    db = set()
    v = json.load(open(ROOT / 'assets/data/vocab/th_vocab.json', encoding='utf-8'))
    for e in v['entries']:
        for x in str(e.get('th', '')).split('/'):
            x = x.strip()
            if x: db.add(x)
    try:
        o = json.load(open(ROOT / 'assets/data/wordsets/th_obec_basic.json', encoding='utf-8'))
        for m in o.get('standard', []):
            if str(m.get('th', '')).strip() and str(m.get('ko', '')).strip(): db.add(str(m['th']).strip())
    except OSError:
        pass
    return db


def main():
    files = sys.argv[1:] or sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/*/*.json')))
    db = load_db()
    miss = Counter(); ex = {}; tot = hit = 0
    for f in files:
        d = json.load(open(f, encoding='utf-8')); ch = False
        for t in d['turns']:
            out = lemmas_of(t['th'])
            for s, b, r in out:
                tot += 1
                if b in db: hit += 1
                else:
                    miss[b] += 1; ex.setdefault(b, (r, t['th'], t['ko']))
            if t.get('lemmas') != out:
                t['lemmas'] = out; ch = True
        if ch:
            open(f, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
    outp = ROOT / 'data/review/write/missing_lemmas.csv'
    outp.parent.mkdir(parents=True, exist_ok=True)
    with open(outp, 'w', encoding='utf-8', newline='') as fo:
        w = csv.writer(fo); w.writerow(['lemma', 'reading', 'count', 'example_th', 'example_ko'])
        for b, n in miss.most_common(): w.writerow([b, ex[b][0], n, ex[b][1], ex[b][2]])
    print(f'내용어 {tot} · 단어장 있음 {hit / max(tot, 1):.0%} · 없는 레마 {len(miss)} → {outp.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
