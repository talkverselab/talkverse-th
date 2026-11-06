#!/usr/bin/env python3
"""태국어 문장 → 한글 독음(rd) — 성조 파이프라인(tools/tone_pipeline/thai_phon.py)을 그대로 쓴다. 2026-11-03.
  rd_th.rd("สวัสดีครับ") → "싸왓디 크랍"   (음절은 붙이고 띄어쓰기·구두점 자리는 띄움, 성조 기호 없음)
변수 {name}·숫자·라틴·이모지는 그대로 둔다. 실행은 pythainlp 가 있는 파이썬(thvenv)으로.
"""
import csv
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / 'tone_pipeline'))
import thai_phon  # noqa: E402
from pythainlp.corpus import thai_words  # noqa: E402
from pythainlp.tokenize import syllable_tokenize, word_tokenize  # noqa: E402
from pythainlp.util import dict_trie  # noqa: E402

THAI = re.compile(r'[฀-๿]')
ROOT = Path(__file__).resolve().parents[1]
# 규칙으로 안 되는 낱말(불규칙 읽기) — 표기는 내 코스 스크립트의 손 독음에 맞춘다
WORD_RD = {'บริษัท': '버리쌋', 'เกาหลี': '까올리', 'อวยพร': '우어이펀', 'สุขภาพ': '쑥카팝', 'เหรอ': '러', 'หรอ': '러', 'เนอะ': '너', 'เอ้ย': '어이',
           'หรือ': '르', 'ก็': '꺼', 'ค่ะ': '카', 'คะ': '카', 'ครับ': '크랍', 'จ้ะ': '짜', 'จ้า': '짜', 'นะคะ': '나 카',
           'เงิน': '응언', 'โอ๊ย': '오이', 'ห่วง': '후앙', 'ข่าว': '카우', 'ปกติ': '뽁까띠', 'รูม': '룸', 'ตลอด': '딸럿', 'สไลด์': '쌀라이', 'สรุป': '싸룹', 'ผล': '폰',
           'สตาร์ท': '싸땃', 'โน้ตบุ๊ก': '놋북', 'มอร์ส': '멋', 'ผลไม้': '폰라마이', 'ล็อบสเตอร์': '럽싸떠', 'ผงชูรส': '퐁추롯', 'ลูกอม': '룩옴', 'ธรรมเนียม': '탐니암',
           'หาร': '한', 'พร': '펀', 'ขอพร': '커펀', 'มังกร': '망껀', 'พิธีกร': '피티껀', 'ชาติ': '찻', 'คนต่างชาติ': '콘땅찻', 'พจนานุกรม': '폿짜나누끄롬', 'บริบท': '버리봇',
           'กวี': '까위', 'บทกวี': '봇까위', 'กังวล': '깡원', 'ยืม': '이음', 'ขอยืม': '커이음'}


def _trie():
    """newmm 사전에서 드문 2~3글자 낱말을 뺀다 — 안 빼면 บอกว่า 가 บอ+กว่า, จากร้าน 이 จา+กร้าน 으로 잘못 끊긴다.
    단어장·빈도표에 있는 낱말은 남긴다."""
    keep = set()
    v = json.load(open(ROOT / 'assets/data/vocab/th_vocab.json', encoding='utf-8'))
    for e in v['entries']:
        keep.update(x.strip() for x in str(e.get('th', '')).split('/'))
    with open(ROOT / 'assets/data/wordsets/th_top1000.csv', encoding='utf-8') as f:
        keep.update(r[1].strip() for r in csv.reader(f) if len(r) > 1)
    drop = {'บอ', 'จา', 'อี', 'ไห', 'พุ', 'เพ'}  # 빈도표에 섞인 토큰 조각
    return dict_trie(({w for w in thai_words() if len(w) > 3 or w in keep} | {w for w in keep if THAI.search(w) and ' ' not in w}) - drop)


TRIE = _trie()


def tok(text):
    """낱말 끊기 — rd·검사기·레마가 모두 이것을 쓴다."""
    return word_tokenize(text, engine='newmm', custom_dict=TRIE)


def _syllables(word):
    try:
        out = syllable_tokenize(word, engine='han_solo')
    except ImportError:
        out = syllable_tokenize(word, engine='dict')
    merged = []
    for s in out:  # หาร → หา+ร 처럼 홀로 떨어진 자음은 앞 음절의 받침이다
        if merged and len(s) == 1 and s in thai_phon.CONS:
            merged[-1] += s
        else:
            merged.append(s)
    return merged


def rd(text):
    out = []
    for chunk in re.split(r'(\s+|[,.!?…/()\[\]"“”]+|\{[a-z_]+\})', text):
        if not chunk:
            continue
        if not THAI.search(chunk):
            out.append(' ' if chunk.isspace() else chunk)
            continue
        words = []
        for w in tok(chunk):
            if not THAI.search(w):
                words.append(w)
                continue
            if set(w) == {'ๆ'} and words:
                words.append(words[-1])  # 반복 기호(따로 토큰이 된 경우)
                continue
            rep = w.endswith('ๆ')
            w0 = w.rstrip('ๆ') or w
            kos = [s['ko'] for s in thai_phon.transcribe(_syllables(w0), tone=False) if s['ko']]
            ko = WORD_RD.get(w0) or (''.join(kos) if kos else w0)
            if w0.endswith('เหรอ') and w0 != 'เหรอ':  # จริงเหรอ — 사전이 한 낱말로 묶은 끝말
                ko = rd(w0[:-4]) + ' 러'
            words.append(ko)
            if rep:
                words.append(ko)  # ช้าๆ → 차 차
        out.append(' '.join(x for x in words if x.strip()))
    s = re.sub(r'(\S+)(?: ๆ)+', r'\1 \1', ''.join(out))  # ชิลๆ ๆ — 띄어 쓴 반복 기호
    s = re.sub(r'([가-힣])(\{[a-z_]+\})', r'\1 \2', s)  # 츠{name} → 츠 {name}
    s = re.sub(r'(\{[a-z_]+\})([가-힣])', r'\1 \2', s)
    s = re.sub(r'\s+([,.!?…])', r'\1', s)
    return re.sub(r'\s{2,}', ' ', s).strip()


def syllable_count(rd_text):
    """한글 음절 수(길이 검사용)."""
    return len(re.findall(r'[가-힣]', rd_text))


if __name__ == '__main__':
    for a in sys.argv[1:] or ['สวัสดีครับ ผมชื่อ{name}ครับ', 'พูดช้าๆ หน่อยได้ไหมครับ', 'ชาเย็นไม่หวานไม่มีค่ะ 555']:
        print(a, '→', rd(a), syllable_count(rd(a)))
