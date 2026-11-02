#!/usr/bin/env python3
"""태국어 문장 → 한글 독음(rd) — 성조 파이프라인(tools/tone_pipeline/thai_phon.py)을 그대로 쓴다. 2026-11-03.
  rd_th.rd("สวัสดีครับ") → "싸왓디 크랍"   (음절은 붙이고 띄어쓰기·구두점 자리는 띄움, 성조 기호 없음)
변수 {name}·숫자·라틴·이모지는 그대로 둔다. 실행은 pythainlp 가 있는 파이썬(thvenv)으로.
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / 'tone_pipeline'))
import thai_phon  # noqa: E402
from pythainlp.tokenize import syllable_tokenize, word_tokenize  # noqa: E402

THAI = re.compile(r'[฀-๿]')


def _syllables(word):
    try:
        return syllable_tokenize(word, engine='han_solo')
    except ImportError:
        return syllable_tokenize(word, engine='dict')


def rd(text):
    out = []
    for chunk in re.split(r'(\s+|[,.!?…/()\[\]"“”]+|\{[a-z_]+\})', text):
        if not chunk:
            continue
        if not THAI.search(chunk):
            out.append(' ' if chunk.isspace() else chunk)
            continue
        words = []
        for w in word_tokenize(chunk, engine='newmm'):
            if not THAI.search(w):
                words.append(w)
                continue
            if w == 'ๆ' and words:
                words.append(words[-1])  # 반복 기호(따로 토큰이 된 경우)
                continue
            rep = w.endswith('ๆ')
            w0 = w.rstrip('ๆ') or w
            kos = [s['ko'] for s in thai_phon.transcribe(_syllables(w0), tone=False) if s['ko']]
            ko = ''.join(kos) if kos else w0
            words.append(ko)
            if rep:
                words.append(ko)  # ช้าๆ → 차 차
        out.append(' '.join(x for x in words if x.strip()))
    s = ''.join(out)
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
