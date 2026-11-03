#!/usr/bin/env python3
"""새 회화(편 JSON) 검사기 — 태국어판 (2026-11-03, 일본어앱 check_dialogues.py 를 태국어 규칙으로).
  python tools/check_dialogues.py [--fix-rd] [--dump-vocab] [assets/data/dialogues/R1/**.json ...]
검사: 턴 수(구간·종류) · 턴 길이(단어 수·독음 음절 ≤20, R1 1단어 단답 금지) · 표현 풀 노출 ≥2 · 반전 1회 · 변수 ·
새 단어/턴 ≤3 · 채팅 편 규칙 · 금지어(출처·브랜드) · rd 채우기(--fix-rd). 구간 어휘(절벽 순위) 초과는 경고(통계)로만.
오류가 있으면 종료 코드 1. 실행은 pythainlp 가 있는 파이썬(thvenv)으로, 저장소 루트에서.
"""
import csv
import glob
import json
import re
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import rd_th  # noqa: E402
from pythainlp.tokenize import word_tokenize  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
EXPR_CSV = ROOT / 'data/expressions/top_expressions.csv'
TOP_CSV = ROOT / 'assets/data/wordsets/th_top1000.csv'
FORBIDDEN = ROOT / 'data/expressions/forbidden.txt'
COVER = {'R0': 55, 'R1': 55, 'R2': 60, 'R3': 70, 'R4': 80}  # 절벽 정의 = 대사 덮는 비율
NAMES = {'ฟ้า', 'ต้น', 'สุภา', 'วดี', 'ภรณ์'}  # 고유명사(통계 제외)
CLIFF = {'R1': 109, 'R2': 149, 'R3': 295, 'R4': 642}  # 절벽 구간 = 빈도 순위 상한(2026-10-03 확정)
TURNS = {('R1', 'survival'): (6, 8), ('R1', 'short'): (6, 8), ('R1', 'long'): (6, 8), ('R1', 'chat'): (6, 8),
         ('R0', None): (4, 8), ('R2', None): (8, 12), ('R3', None): (12, 16), ('R4', None): (12, 16)}
WORDS = {'survival': (2, 9), 'short': (2, 9), 'long': (2, 12), 'chat': (1, 8)}
THAI = re.compile(r'[฀-๿]')
VAR = re.compile(r'\{(name|country|city|lang)\}')
PUNCT = re.compile(r'^[\s,.!?…/()\[\]"“”~\-–—]+$')


def load_expr():
    with open(EXPR_CSV, encoding='utf-8') as f:
        return [r['expr'] for r in csv.DictReader(f)]


def load_rank():
    rank = {}
    try:
        with open(TOP_CSV, encoding='utf-8') as f:
            next(f)
            for line in f:
                p = line.rstrip('\n').split(',')
                if len(p) >= 2 and p[0].isdigit():
                    rank.setdefault(p[1].strip(), int(p[0]))
    except OSError:
        pass
    return rank


def words_of(text):
    t = VAR.sub(' ', text)
    return [w for w in word_tokenize(t, engine='newmm') if THAI.search(w) and not PUNCT.match(w) and w != 'ๆ']


def check_file(path, exprs, rank, cum_vocab, fix_rd, forbidden):
    errs, warns = [], []
    ep = json.load(open(path, encoding='utf-8'))
    eid = ep.get('id', path.stem)
    E = lambda m: errs.append(f'{eid}: {m}')  # noqa: E731
    W = lambda m: warns.append(f'{eid}: {m}')  # noqa: E731
    region, kind = ep.get('region', 'R1'), ep.get('kind', 'short')
    turns = ep.get('turns', [])
    lo, hi = TURNS.get((region, kind)) or TURNS.get((region, None)) or (6, 8)
    if not lo <= len(turns) <= hi:
        E(f'턴 수 {len(turns)} (허용 {lo}~{hi})')
    for k in ('id', 'region', 'island', 'kind', 'title', 'scene', 'speakers', 'register', 'twist', 'expressions'):
        if k not in ep:
            E(f'필드 없음: {k}')
    if ep.get('twist') and not any(t.get('num') == ep['twist'] for t in turns):
        E(f'twist 턴 {ep["twist"]} 없음')
    if not ep.get('twist'):
        E('반전(twist) 없음')
    if ep.get('twist_type') not in TWIST_TYPES:
        E(f'twist_type 없음/잘못됨: {ep.get("twist_type")} (허용 {"·".join(TWIST_TYPES)})')
    text_all = ' '.join(t.get('th', '') for t in turns)
    hit = [e for e in exprs if e.replace('…', '') and (e in text_all if '…' not in e else all(p in text_all for p in e.split('…') if p.strip()))]
    if len(set(hit)) < 2:
        E(f'표현 풀 노출 {len(set(hit))}개 (<2)')
    for fw in forbidden:
        if fw and fw in json.dumps(ep, ensure_ascii=False):
            E(f'금지어: {fw}')
    seen_ep = set()
    wlo, whi = WORDS.get(kind, (2, 9))
    over_rank = Counter()
    in_tok, tot_tok = [0], [0]
    names = set(w for v in ep.get('speakers', {}).values() for w in words_of(v))
    free = set(exprs) | names | NAMES | {w for e in exprs for w in words_of(e)}
    for t in turns:
        n = t.get('num')
        th = t.get('th', '')
        if t.get('speaker') not in ('A', 'B', 'C', 'D'):
            E(f'턴 {n}: 화자 {t.get("speaker")}')
        if not th or not t.get('ko'):
            E(f'턴 {n}: th/ko 비어 있음')
            continue
        if t.get('speaker') == 'A' and re.search(r'ฉัน|ดิฉัน|ค่ะ|คะ', th) and not t.get('female_ok'):
            W(f'턴 {n}: A 는 남성 기준(ผม/ครับ)으로 — 여성판은 규칙 치환: {th}')
        ws = words_of(th)
        if len(ws) == 1 and kind != 'chat' and region == 'R1' and n not in (ep.get('twist'), len(turns)) and not t.get('one_word_ok'):
            E(f'턴 {n}: R1 1단어 단답 금지: {th}')
        if not wlo <= len(ws) <= whi and not t.get('len_ok'):
            W(f'턴 {n}: 단어 수 {len(ws)} (권장 {wlo}~{whi}): {th}')
        if fix_rd and not t.get('rd_manual') and (fix_rd == 'force' or not t.get('rd')):
            t['rd'] = rd_th.rd(th)
        syl = rd_th.syllable_count(t.get('rd', ''))
        if region in ('R0', 'R1') and syl > 20 and not t.get('len_ok'):
            W(f'턴 {n}: 독음 {syl}음절 (>20)')
        new = [w for w in dict.fromkeys(ws) if w not in cum_vocab and w not in seen_ep and w not in exprs]
        seen_ep.update(ws)
        if len(new) > 3 and not t.get('new_ok'):
            W(f'턴 {n}: 새 단어 {len(new)}개 (>3): {new}')
        for w in ws:
            if w in free and w not in rank:  # 순위 목록에 없는 구어 표현·이름만 통계에서 뺀다
                continue
            tot_tok[0] += 1
            r = rank.get(w)
            if r is not None and r <= CLIFF.get(region, 642):
                in_tok[0] += 1
            else:
                over_rank[w] += 1
        if kind == 'chat' and t.get('ui') != 'bubble':
            E(f'턴 {n}: 채팅 편은 "ui":"bubble"')
    if tot_tok[0]:
        cov = in_tok[0] * 100 // tot_tok[0]
        target = COVER.get(region, 0)
        msg = f'{region} 절벽 안 단어 {cov}% (기준 {target}%)'
        (W if cov < target - 10 else (lambda m: None))(msg + ' — 너무 어려움')
        ep.setdefault('stats', {})['cliff_cover'] = cov
    if over_rank:
        W(f'{region} 절벽 밖 단어 {len(over_rank)}종(통계): {", ".join(list(over_rank)[:12])}')
    cum_vocab.update(seen_ep)
    if fix_rd:
        json.dump(ep, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    return errs, warns


# 반전 종류(모든 언어앱 공통, 사용자 지시 2026-11-03 한국어앱 경유): chaos 30% 이상 목표
TWIST_TYPES = ('chaos', 'slip', 'reveal', 'emotion', 'ignore')
CHAOS_MIN = 0.30


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    fix = 'force' if '--fix-rd=force' in sys.argv else ('--fix-rd' in sys.argv)
    files = [Path(a).resolve() for a in args] or sorted(Path(p) for p in glob.glob(str(ROOT / 'assets/data/dialogues/R*/**/*.json'), recursive=True))
    exprs = load_expr()
    rank = load_rank()
    forbidden = [l.strip() for l in open(FORBIDDEN, encoding='utf-8')] if FORBIDDEN.exists() else []
    cum = set()
    total_e = 0
    for f in files:
        errs, warns = check_file(f, exprs, rank, cum, fix, forbidden)
        for w in warns:
            print('  warn', w)
        for e in errs:
            print('  ERR ', e)
        print(f'{f.relative_to(ROOT)}: 오류 {len(errs)} 경고 {len(warns)}')
        total_e += len(errs)
    # 반전 비율(묶음 전체)
    from collections import Counter
    tt = Counter(json.load(open(f, encoding='utf-8')).get('twist_type', '?') for f in files)
    n = sum(tt.values())
    if n:
        print('반전 비율:', ' · '.join(f'{k} {v}({v * 100 // n}%)' for k, v in tt.most_common()))
        if n >= 5 and tt.get('chaos', 0) / n < CHAOS_MIN:
            print(f'  warn 카오스 {tt.get("chaos", 0) * 100 // n}% < {int(CHAOS_MIN * 100)}% — 끝 2~4턴을 카오스로 고칠 편을 고를 것')
    if '--dump-vocab' in sys.argv:
        print('누적 어휘', len(cum), sorted(cum)[:50])
    return 1 if total_e else 0


if __name__ == '__main__':
    sys.exit(main())
