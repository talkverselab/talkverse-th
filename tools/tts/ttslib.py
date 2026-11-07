"""회화 음성 공통(태국어): 감정 계획 + 편 JSON → 턴별 남성판·여성판(본문 넷 + 읽을 조각). 일본어·한국어앱 tools/tts/ttslib.py 와 같은 구조.
D1 audio_lines 열에 맞춘 이름: text = 태국어 본문, reading = (태국어는 없음, 빈 값), rd = 한글 독음, ko = 한국어 뜻.
모든 턴에 m·f 두 판, 판마다 본문과 mp4 하나. 소리 낼 글이 없는 턴(지문·「……」·스탬프)만 뺀다. 태국어는 조사가 없어 자리 채움은 단순 치환."""
import glob, json, os, re
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
V = json.load(open(f'{R}/data/tts/voices.json', encoding='utf-8'))
EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/assets/data/dialogues/*/*/*.json')}
SIL = re.compile(r'[\s…。、！？!?.,~♪5ๆ]|\([^)]*\)')


def fills(P, g):
    out = {}
    for k, x in V['fill'].items():
        out[k] = x.get(g) or x
    out.update(P.get('fill', {}))
    return out


def fill(s, F, key):
    """자리 채우기. key = text(태국어) · rd(한글 독음) · ko(한국어 뜻)."""
    if '{' not in s:
        return s
    for k, x in F.items():
        s = s.replace(k, x.get(key) or x['text'])
    return s


def turns(ep):
    """[{num, speaker, m:{voice,text,reading,rd,ko,segs:[(감정,읽기)]}, f:{…}, same:bool}] — 소리 없는 턴은 뺀다."""
    P = json.load(open(f'{R}/data/tts/plan/{ep}.json', encoding='utf-8')); d = json.load(open(EP[ep], encoding='utf-8'))
    out = []
    for t in d['turns']:
        T = P['turns'][str(t['num'])]; row = {'num': t['num'], 'speaker': t['speaker']}
        for g in 'mf':
            X = T.get(g) or {}; F = fills(P, g)
            segs = [(s[0], fill(s[-1], F, 'text').strip()) for s in (X.get('segs') or T['segs'])]
            segs = [s for s in segs if SIL.sub('', s[1])]
            row[g] = {'voice': ('am' if g == 'm' else 'af') if t['speaker'] == 'A' else P['cast'][t['speaker']],
                      'text': fill(X.get('text') or t['th'], F, 'text'), 'reading': '',
                      'rd': fill(X.get('rd') or t.get('rd', ''), F, 'rd'), 'ko': fill(X.get('ko') or t.get('ko', ''), F, 'ko'), 'segs': segs}
        if not row['m']['segs'] or not row['f']['segs']:
            continue
        row['same'] = row['m']['voice'] == row['f']['voice'] and row['m']['segs'] == row['f']['segs']
        out.append(row)
    return out


def seg_files(ep):
    """생성할 조각 [(파일이름, 목소리, 감정, 읽기)] — 두 판이 같으면 c 하나, 다르면 m·f."""
    out = []
    for r in turns(ep):
        for tag in (['c'] if r['same'] else ['m', 'f']):
            x = r['m' if tag == 'c' else tag]
            for i, (emo, text) in enumerate(x['segs']):
                out.append((f"{r['num']:02d}_{i}_{tag}.wav", x['voice'], emo, text))
    return out


def planned():
    """감정 계획이 있는 편 id(정렬)."""
    return sorted(os.path.basename(p)[:-5] for p in glob.glob(f'{R}/data/tts/plan/*.json') if os.path.basename(p)[:-5] in EP)
