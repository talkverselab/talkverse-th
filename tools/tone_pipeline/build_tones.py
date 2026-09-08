r"""앱의 모든 태국어(단어·대화·바로 문장·영어유래·루트)에 대해 음절별 성조 DB 생성.

사용: python -X utf8 tools/tone_pipeline/build_tones.py
출력: assets/data/vocab/th_tones.json
  {"meta": {...},
   "entries": {"<태국어 문자열>": {"ko": "카우ˆ 남ˊ", "ro": "k{â}w nám",
                                 "syl": [{"s": "ข้าว", "t": "falling", "ko": "카우ˆ", "ro": "k{â}w"}, ...]}}}
  - ko: 한글 독음 + 성조 기호(평성 없음 · 저성 ˋ · 하성 ˆ · 고성 ˊ · 상성 ˇ), 음절은 공백으로 구분
  - ro: 우리 로마자(장음 {..} = 밑줄, 성조는 모음 위 악센트 à â á ǎ)
음절 분리: pythainlp syllable_tokenize(han_solo). 분석 실패 음절은 t="" 로 남긴다.
"""
import glob
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import thai_phon  # noqa: E402

from pythainlp.tokenize import syllable_tokenize  # noqa: E402

THAI = re.compile(r'[฀-๿]')


def collect():
    texts = set()

    def add(t):
        t = (t or '').strip()
        if t and THAI.search(t):
            texts.add(t)

    v = json.load(io.open(os.path.join(ROOT, 'assets/data/vocab/th_vocab.json'), encoding='utf-8'))
    for e in v['entries']:
        add(e['th'])
        for part in e['th'].split('/'):
            add(part)
    xp = os.path.join(ROOT, 'assets/data/vocab/th_expressions.json')
    if os.path.exists(xp):
        for e in json.load(io.open(xp, encoding='utf-8'))['entries']:
            add(e['th'])
            for part in e['th'].split('/'):
                add(part)
    r = json.load(io.open(os.path.join(ROOT, 'assets/data/vocab/th_roots.json'), encoding='utf-8'))
    for x in r['roots']:
        add(x['th'])
    for f in glob.glob(os.path.join(ROOT, 'assets/data/dialogues/L*.json')):
        d = json.load(io.open(f, encoding='utf-8'))
        for ep in (d.get('episodes') or d.get('dialogues') or []):
            for t in ep['turns']:
                add(t['th'])
    q = json.load(io.open(os.path.join(ROOT, 'assets/data/phrases/quick_phrases.json'), encoding='utf-8'))
    for c in q.get('categories', []):
        for p in c.get('phrases', []):
            add(p.get('th'))
    lw = json.load(io.open(os.path.join(ROOT, 'assets/data/wordsets/th_loanwords.json'), encoding='utf-8'))
    for w in lw['words']:
        add(w['th'])
    ob = os.path.join(ROOT, 'assets/data/wordsets/th_obec_basic.json')
    if os.path.exists(ob):
        for w in json.load(io.open(ob, encoding='utf-8'))['standard']:
            add(w['th'])
    a = json.load(io.open(os.path.join(ROOT, 'assets/data/alphabet/th_alphabet.json'), encoding='utf-8'))
    for c in a['consonants']:
        add(c.get('acrophonic', '').split(' ', 1)[-1])
    return sorted(texts)


def syllables_of(text):
    out = []
    for chunk in re.split(r'(\s+)', text):
        if not chunk:
            continue
        if chunk.isspace():
            out.append(' ')
            continue
        if not THAI.search(chunk):
            out.append(chunk)
            continue
        try:
            sy = syllable_tokenize(chunk, engine='han_solo')
        except Exception:  # noqa: BLE001
            sy = [chunk]
        out.extend(sy)
    return out


def main():
    texts = collect()
    entries = {}
    n_fail = 0
    n_syl = 0
    for t in texts:
        syls = syllables_of(t)
        rows = []
        ko_parts, ro_parts = [], []
        for s in syls:
            if s == ' ':
                ko_parts.append('|')
                ro_parts.append('|')
                continue
            if not THAI.search(s):
                rows.append(dict(s=s, t='', ko=s, ro=s))
                ko_parts.append(s)
                ro_parts.append(s)
                continue
            o = thai_phon.analyze(s)
            n_syl += 1
            if o is None:
                n_fail += 1
                rows.append(dict(s=s, t='', ko='', ro=''))
                continue
            ko = thai_phon.to_hangul(o)
            ro = thai_phon.to_roman(o)
            rows.append(dict(s=s, t=o.tone, ko=ko, ro=ro))
            ko_parts.append(ko)
            ro_parts.append(ro)
        ko = ' '.join(ko_parts).replace(' | ', '  ').strip()
        ro = ' '.join(ro_parts).replace(' | ', '  ').strip()
        entries[t] = dict(ko=ko, ro=ro, syl=rows)
    out = os.path.join(ROOT, 'assets/data/vocab/th_tones.json')
    doc = dict(meta=dict(
        note='음절별 성조 DB — 철자 규칙으로 자동 계산(tools/tone_pipeline). ko=한글+성조기호(ˋ저 ˆ하 ˊ고 ˇ상), ro=우리 로마자({}=장음 밑줄, 악센트=성조)',
        tones=dict(mid='평성', low='저성 ˋ', falling='하성 ˆ', high='고성 ˊ', rising='상성 ˇ'),
        count=len(entries)), entries=entries)
    io.open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(doc, ensure_ascii=False, separators=(',', ':')))
    print(f'texts {len(texts)}  syllables {n_syl}  unparsed {n_fail}  → {out} ({os.path.getsize(out):,} bytes)')
    for k in ['สวัสดีครับ ผมชื่อมินโฮครับ', 'น้ำแข็ง', 'แท็กซี่', 'ไม่เป็นไร', 'อร่อยมาก']:
        if k in entries:
            print(' ', k, '→', entries[k]['ko'], '|', entries[k]['ro'])


if __name__ == '__main__':
    main()
