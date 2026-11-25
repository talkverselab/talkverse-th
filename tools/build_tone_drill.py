#!/usr/bin/env python3
"""성조연습 자료 → assets/data/tone_drill.json (중국어앱 tools/build_tone_drill.py 를 태국어에 맞게 옮김, 2026-11-25).
  ~/venvs/th/bin/python tools/build_tone_drill.py
- 메뉴 = 성조 조합 5 × 5 = 25칸(평성·저성·하성·고성·상성). 칸마다 2음절 낱말 12개 = 묶음 3개(낱말 4 + 문장 1).
- 낱말: 단어장(th_vocab) → 기초 낱말(th_obec_basic) 순. 성조는 성조 DB(th_tones.json, 철자 규칙 계산)의 **소리 나는 성조**.
  규칙 계산이 실제 발음과 어긋나기 쉬운 낱말은 뺀다: 앞 음절이 모음 없는 자음 하나(ขนม·ตลาด — 말할 때 평성으로 약해짐),
  ์·ๆ·ฤ·รร 이 든 낱말, 쓰는 성조와 말하는 성조가 다른 낱말, 겉보기 2음절이지만 실제로는 3음절인 낱말(ผลไม้·เอกสาร),
  감탄사·외래어·거친 말(tools/tone_drill_skip.json — 뽑힌 낱말을 눈으로 보고 뺀 것).
- 문장: 회화에서 태국 글자 6~24자, 음성 조각이 하나(`_0_c`)이고 받아쓰기 0.90 이상이며 서버 음성 목록에 있는 줄 — 그 wav 에서 기준 곡선 50점."""
import collections, glob, json, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, f'{ROOT}/tools/tts')
import ttslib as L  # noqa: E402

WAV = os.path.expanduser('~/tts_work/th/wav')
PITCH = f'{ROOT}/packages/talkverse_pitch'
TONES = ['mid', 'low', 'falling', 'high', 'rising']
PER = 12
TH = re.compile(r'[฀-๿]')
VOWEL = re.compile(r'[ะ-ฺเ-ไ็]|[าำ]')
# 쓰는 성조와 말하는 성조가 다른 음절이 든 낱말(ไหม·เขา·ฉัน 은 말할 때 고성), 줄여 말하는 낱말
SKIP_PART = ('ไหม', 'เขา', 'ฉัน', 'มั้ย', 'ยังไง', 'อย่างไร')
SKIP = set(os.environ.get('TONE_SKIP', '').split()) | set(json.load(open(f'{ROOT}/tools/tone_drill_skip.json', encoding='utf-8')))


CLUSTER = set('กร กล กว ขร ขล ขว คร คล คว ตร ปร ปล พร พล ผล หง หญ หน หม หย หร หล หว อย จร สร ศร'.split())
CONS = 'ก-ฮ'


def initial(chunk):
    """음절 조각의 첫 자음 묶음(앞에 쓰는 모음은 건너뜀) · 모음 부호가 있는지."""
    c = re.sub(r'^[เแโใไ]', '', chunk)
    m = re.match(f'[{CONS}]+', c)
    head = m.group(0) if m else ''
    rest = c[len(head):]
    has_vowel = bool(re.search(r'[ะ-ฺ็]|[าำ]', rest)) or chunk[0] in 'เแโใไ'
    return head, has_vowel, rest


def ok_syl(chunk):
    head, has_vowel, rest = initial(chunk)
    if not head: return False
    if has_vowel:
        if rest and rest[0] in '่้๊๋' or rest[:1] and re.match(r'[ะ-ฺ็าำ่-๋]', rest[0]):
            return len(head) == 1 or (len(head) == 2 and head in CLUSTER)
        # 앞에 쓰는 모음만 있고 뒤에 부호가 없다(เลข·โรง·ไป): 자음 = 첫소리(+겹자음) + 받침
        return len(head) <= 2 or (len(head) == 3 and head[:2] in CLUSTER)
    # 모음 부호가 없다(คน·ผม·กรง): 첫소리 + 받침, 겹자음이면 셋
    if re.search(r'[่-๋]', rest):   # 부호 없이 성조 부호만(ต้น·ส้ม)
        tail = re.sub(r'[่-๋]', '', rest)
        return (len(head) == 1 or head in CLUSTER) and len(tail) <= 1
    return len(head) == 2 or (len(head) == 3 and head[:2] in CLUSTER)


def ok_word(th, syl):
    if len(syl) != 2 or ''.join(s['s'] for s in syl) != th or not all(s.get('t') in TONES for s in syl): return False
    if th in SKIP or any(p in th for p in SKIP_PART) or re.search(r'[์ๆฤฦ]|รร|[^\u0E00-\u0E7F]', th): return False
    if 'ก็' in th or syl[0]['s'].endswith('ะ'): return False      # ก็ 는 DB 성조가 틀림 · 앞 음절이 짧게 약해지는 낱말(กระ·ประ·ทะ·มะ)
    return all(ok_syl(s['s']) for s in syl)


def words():
    T = json.load(open(f'{ROOT}/assets/data/vocab/th_tones.json', encoding='utf-8'))['entries']
    out, seen = [], set()

    def add(th, ko, src, order):
        th = th.strip()
        if th in seen or th not in T: return
        e = T[th]; syl = e.get('syl', [])
        if not ok_word(th, syl): return
        seen.add(th)
        out.append({'th': th, 'syl': [s['s'] for s in syl], 't': [s['t'] for s in syl], 'rd': e.get('ko', ''), 'ro': e.get('ro', ''),
                    'ko': re.sub(r'\s+', ' ', ko).strip(), 'src': src, 'order': order})

    for w in json.load(open(f'{ROOT}/assets/data/vocab/th_vocab.json', encoding='utf-8'))['entries']:
        add(w['th'], w['ko'], 0, w.get('order', 9999))

    def walk(o, n=[0]):
        if isinstance(o, dict):
            if isinstance(o.get('th'), str) and isinstance(o.get('ko'), str):
                n[0] += 1; add(o['th'], o['ko'], 1, n[0])
            for v in o.values(): walk(v)
        elif isinstance(o, list):
            for v in o: walk(v)
    walk(json.load(open(f'{ROOT}/assets/data/wordsets/th_obec_basic.json', encoding='utf-8')))
    return out


def contour(wav):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', wav, '-f', 's16le', '-ar', '16000', '-ac', '1', '-'], capture_output=True).stdout
    r = subprocess.run(['dart', 'run', 'talkverse_pitch:contour', '50'], input=raw, capture_output=True, cwd=PITCH)
    s = r.stdout.decode().strip().splitlines()[-1] if r.stdout.strip() else 'null'
    return json.loads(s)


def candidates():
    Q = json.load(open(f'{WAV}/qa.json', encoding='utf-8'))
    M = json.load(open(f'{ROOT}/data/tts/audio_th.json', encoding='utf-8'))
    redo = set(json.load(open(f'{ROOT}/data/tts/redo_th_20261125.json', encoding='utf-8'))['segs'])
    out = []
    for p in sorted(glob.glob(f'{ROOT}/assets/data/dialogues/R[0-4]/*/*.json')):
        d = json.load(open(p, encoding='utf-8')); ep = d['id']
        if not os.path.isdir(f'{WAV}/{ep}'): continue
        segs = collections.defaultdict(list)
        for f, _, _, _ in L.seg_files(ep): segs[int(f[:2])].append(f)
        for t in d['turns']:
            th = t['th']; h = ''.join(TH.findall(th))
            if '{name}' in th or re.search(r'[0-9A-Za-z…]|555|\.\.', th) or not 6 <= len(h) <= 24: continue
            if segs[t['num']] != [f"{t['num']:02d}_0_c.wav"]: continue
            k = f"{ep}/{segs[t['num']][0]}"
            if k in redo or Q.get(k, {}).get('sim', 0) < 0.9 or not os.path.exists(f'{WAV}/{k}'): continue
            if sum(r['turn'] == t['num'] for r in M.get(ep, [])) != 2: continue      # 남·여 두 판 모두 서버 목록에 있는 줄만
            out.append({'ep': ep, 'turn': t['num'], 'th': th, 'h': h, 'rd': t.get('rd', ''), 'ko': t['ko'], 'wav': f'{WAV}/{k}', 'region': d['region']})
    return out


def pick_sentence(ws, cell, cands, used):
    """그 묶음 낱말이 든 줄 → 같은 칸 낱말이 든 줄 → 아무 줄. 쉬운 구간·짧은 것부터."""
    order = sorted(cands, key=lambda c: (c['region'], len(c['h'])))
    for pool in ([w['th'] for w in ws], [w['th'] for w in cell], None):
        for c in order:
            if (c['ep'], c['turn']) in used or (pool is not None and not any(z in c['h'] for z in pool)): continue
            r = contour(c['wav'])
            if r and r['dur'] >= 0.5: return c, r
    raise SystemExit('문장 후보가 모자란다')


def main():
    ws = words(); cands = candidates(); text = ''.join(c['h'] for c in cands)
    cells = collections.defaultdict(list)
    for w in sorted(ws, key=lambda w: (w['src'], w['th'] not in text, w['order'])):   # 단어장 먼저 · 회화에 나오는 낱말 먼저 · 자주 쓰는 순
        cells[f"{w['t'][0]}-{w['t'][1]}"].append(w)
    used, combos = set(), []
    for a in TONES:
        for b in TONES:
            k = f'{a}-{b}'; pick = cells[k][:PER]
            if len(pick) < PER: raise SystemExit(f'{k} 낱말 {len(pick)}개')
            rounds = []
            for j in range(0, PER, 4):
                g = pick[j:j + 4]
                c, r = pick_sentence(g, cells[k], cands, used); used.add((c['ep'], c['turn']))
                rounds.append({'words': [{x: w[x] for x in ('th', 'syl', 't', 'rd', 'ro', 'ko')} for w in g],
                               'sentence': {'ep': c['ep'], 'turn': c['turn'], 'th': c['th'], 'rd': c['rd'], 'ko': c['ko'], 'ref': r}})
            combos.append({'cell': k, 'rounds': rounds})
    out = {'_meta': '성조연습 자료 — tools/build_tone_drill.py 가 만든다(손으로 고치지 말 것)', 'combos': combos}
    json.dump(out, open(f'{ROOT}/assets/data/tone_drill.json', 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
    print('낱말 통과', len(ws), '| 문장 후보', len(cands), '| 칸별 낱말', sorted(len(v) for v in cells.values()))
    for cb in combos:
        print(cb['cell'], ' / '.join(' '.join(w['th'] for w in r['words']) + ' | ' + r['sentence']['th'] for r in cb['rounds']))


if __name__ == '__main__':
    main()
