#!/usr/bin/env python3
"""생성된 문장 조각을 받아쓰기로 검사하고, 나쁜 조각의 재생성 작업을 만든다(mlx-whisper 필요).
  python qa.py <wav폴더> <편id>... [--jobs <moss_jobs.json>]   결과는 <wav폴더>/qa.json 에 쌓인다(조각 → sim·dur·tries·ok)
태국 문자만 남겨 견준다(띄어쓰기·문장부호 무시). 품질 기준(일본어앱 DIALOGUE_AUDIO.md §5, b189b0c): 유사도 ≥ 0.90 · 첫/끝 낱말 누락 불합격 · whisper 언어 판정 th(12글자 이상) · 거의 무음·폭주 불합격.
잡음(무음 구간만, ≤ -55dB)·속도(참고 음성 중앙값의 0.75~1.15배)·클리핑은 **재생성 근거가 아니라 들어 볼 조각을 고르는 체** — qa.json 의 why 에만 적는다(받아쓰기 1.0 인 조각을 수치로 다시 만들지 않는다).
재생성본은 PC 의 out/retake/<편>/<조각>.t<N>.wav — 받아 온 뒤 다시 돌리면 가장 잘 나온 판을 본 파일로 고른다. 세 번 해도 나쁘면 가장 나은 판을 쓰고 qa.json 에 ok=false 로 남긴다."""
import difflib, glob, json, os, re, shutil, subprocess, sys
import mlx_whisper
import ttslib as L
from pythainlp.tokenize import word_tokenize
M = 'mlx-community/whisper-large-v3-turbo'
SIM, NOISE = 0.90, -55.0
REF_RATE = 12.0                      # 태국어 참고 음성(VoxCPM2) 속도 중앙값(글자/초, 2026-11-07 25개 측정) — 말 속도 범위 = 0.75~1.15배
RATE_LO, RATE_HI = REF_RATE * 0.75, REF_RATE * 1.15
TRIM = 'silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.03,areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.03,areverse'
# 태국어 정규화: 태국 문자만 · 성조 기호·ไม้ไต่คู้·การันต์ 제거(whisper 가 자주 틀림) · 같은 뜻의 표기 통일 · 이름(자리 채움)은 뺀다
_SYN = [('อย่างนั้น', 'งั้น'), ('อย่างไร', 'ยังไง'), ('ไง', 'ยังไง'), ('ดิ', 'ดี'), ('อ่ะ', 'อะ'), ('ค่ะ', 'คะ'), ('ลาย', 'ไลน์'), ('คับ', 'ครับ'), ('ชิว', 'ชิล')]
_NAMES = sorted({x.get(g, x)['text'] if isinstance(x.get(g, x), dict) else x['text'] for x in L.V['fill'].values() for g in ('m', 'f')}, key=len, reverse=True)


def norm(s):
    for n in _NAMES:
        s = s.replace(n, '')
    s = re.sub(r'[^\u0E00-\u0E7F]', '', s)
    s = re.sub(r'[\u0E48-\u0E4B\u0E47\u0E4C\u0E46]', '', s)     # ่ ้ ๊ ๋ ็ ์ ๆ
    for a, b in _SYN:
        s = s.replace(re.sub(r'[\u0E48-\u0E4B\u0E47\u0E4C]', '', a), re.sub(r'[\u0E48-\u0E4B\u0E47\u0E4C]', '', b))
    return s


def dur(f):
    return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f], capture_output=True, text=True).stdout or 0)


def peak(f):
    o = subprocess.run(['ffmpeg', '-hide_banner', '-i', f, '-af', 'volumedetect', '-f', 'null', '-'], capture_output=True, text=True).stderr
    m = re.search(r'max_volume: (-?[\d.]+) dB', o)
    return float(m.group(1)) if m else -99.0


def stats(f):
    """(트림 뒤 길이, 잡음 바닥 dB, 클리핑 표본 수) — astats 로 한 번에."""
    # 잡음 바닥은 **무음 구간만**(-40dB 아래가 0.3초 이상 이어진 곳의 RMS). 그런 구간이 없으면 None(검사 건너뜀).
    o = subprocess.run(['ffmpeg', '-hide_banner', '-i', f, '-af', 'silencedetect=n=-40dB:d=0.3,astats=measure_perchannel=none:measure_overall=Peak_level+Peak_count', '-f', 'null', '-'], capture_output=True, text=True).stderr
    pk = re.search(r'Peak level dB: (-?[\d.]+)', o); pc = re.search(r'Peak count: ([\d.]+)', o)
    clip = float(pc.group(1)) if (pk and float(pk.group(1)) >= -0.1 and pc) else 0.0   # 0dBFS 에 닿은 표본 수 = 클리핑
    nf = None
    spans = list(zip(re.findall(r'silence_start: ([\d.]+)', o), re.findall(r'silence_end: ([\d.]+)', o)))
    if spans:
        a, b = max(spans, key=lambda x: float(x[1]) - float(x[0]))
        oo = subprocess.run(['ffmpeg', '-hide_banner', '-ss', a, '-to', b, '-i', f, '-af', 'astats=measure_perchannel=none:measure_overall=RMS_level', '-f', 'null', '-'], capture_output=True, text=True).stderr
        m = re.search(r'RMS level dB: (-?[\d.]+|-inf)', oo)
        nf = -99.0 if (m and m.group(1) == '-inf') else (float(m.group(1)) if m else None)
    d = subprocess.run(['ffmpeg', '-hide_banner', '-i', f, '-af', TRIM, '-f', 'null', '-'], capture_output=True, text=True).stderr
    t = re.findall(r'time=(\d+):(\d+):([\d.]+)', d)
    td = (int(t[-1][0]) * 3600 + int(t[-1][1]) * 60 + float(t[-1][2])) if t else dur(f)
    return td, nf, clip


LAUGH = re.compile(r'ฮ่าๆ|ฮะๆ|ฮ่า+|ฮะ+|555+')


def edge_ok(w, g):
    """첫 낱말·끝 낱말이 받아쓰기에 있어야 한다(태국어는 띄어쓰기가 없어 newmm 으로 낱말을 뗀다). 문장부호·웃음은 뗀 뒤 비교."""
    w = LAUGH.sub(' ', re.sub(r'[^\u0E00-\u0E7F\s]', ' ', w))
    for n in _NAMES:
        w = w.replace(n, ' ')
    toks = [norm(x) for x in word_tokenize(w, keep_whitespace=False) if re.search(r'[\u0E00-\u0E7F]', x)]
    toks = [x for x in toks if x]
    if len(toks) < 2:
        return True
    return g.startswith(toks[0][:2]) and toks[-1][-2:] in g[-6:]


def score(f, text):
    """(점수, 길이, 사유). 점수 1.0 = 합격 기준(유사도 ≥ 0.90 이고 다른 검사 통과), 0.0 = 불합격 사유 있음."""
    w = norm(LAUGH.sub('', text)); d = dur(f)   # 웃음(ฮ่าๆ)은 받아쓰기·속도에서 뺀다
    if d <= 0 or peak(f) < -30:            # 거의 무음으로 나온 조각(생성 실패)
        return 0.0, d, 'silent'
    td, nf, flat = stats(f)
    rate = len(w) / td if td > 0 else 0
    if LAUGH.search(text):                     # 웃음이 든 조각은 길어지므로 속도 하한을 보지 않는다
        rate = max(rate, RATE_LO)
    flags = []
    if rate > RATE_HI * 1.6 or rate < RATE_LO * 0.5:        # 폭주·늘어짐(속도 보정으로도 못 맞추는 범위) — 이것만 불합격
        return 0.0, d, f'rate {rate:.1f}'
    if rate > RATE_HI or (rate < RATE_LO and not LAUGH.search(text)):
        flags.append(f'rate {rate:.1f}')
    if nf is not None and nf > NOISE:
        flags.append(f'noise {nf:.0f}dB')
    if flat > 4:
        flags.append(f'clip {flat:.0f}')
    why = ' '.join(flags)
    if len(w) <= 4:                       # 글자 몇 개는 받아쓰기를 믿을 수 없다 — 길이만 본다
        return (1.0 if td <= 2.0 else 0.0), d, (why or 'short')
    r = mlx_whisper.transcribe(f, path_or_hf_repo=M, language='th', condition_on_previous_text=False)
    g = norm(LAUGH.sub('', r['text']))
    if len(w) >= 12:                           # 긴 조각은 언어 판정도 본다(짧은 웃음은 vi 로 오판한다)
        det = mlx_whisper.transcribe(f, path_or_hf_repo=M, condition_on_previous_text=False).get('language')
        if det not in (None, 'th'):
            return 0.0, d, f'lang {det}'
    sim = difflib.SequenceMatcher(None, w, g).ratio()
    if not edge_ok(text, g):
        return min(sim, SIM - 0.01), d, ('edge ' + why).strip()
    return sim, d, why


def main():
    a = sys.argv[1:]; jobs_out = None
    if '--jobs' in a:
        i = a.index('--jobs'); jobs_out = a[i + 1]; a = a[:i] + a[i + 2:]
    wav, eps = a[0], a[1:]
    qf = f'{wav}/qa.json'; Q = json.load(open(qf, encoding='utf-8')) if os.path.exists(qf) else {}
    jobs = []; bad = 0
    for ep in eps:
        for name, voice, emo, text in L.seg_files(ep):
            k = f'{ep}/{name}'; f = f'{wav}/{k}'; q = Q.setdefault(k, {'tries': 0})
            if not os.path.exists(f):
                q.pop('sim', None); q['ok'] = False; bad += 1; continue   # 아직 없는 조각 — 생기면 다시 잰다
            if 'sim' not in q:
                q['sim'], q['dur'], q['why'] = score(f, text)
            for c in sorted(glob.glob(f'{wav}/retake/{k[:-4]}.t*.wav')):          # 받아 온 재생성본 중 더 나은 것을 본 파일로
                s, d, why = score(c, text)
                if s > q['sim']:
                    shutil.copy(c, f); q['sim'], q['dur'], q['why'] = s, d, why
                os.remove(c)
            q['ok'] = q['sim'] >= SIM
            if not q['ok']:
                bad += 1
                if q['tries'] < 3:
                    q['tries'] += 1
                    jobs.append({'out': f"th/retake/{k[:-4]}.t{q['tries']}.wav", 'text': text, 'language': 'Thai', 'reference': f'out/ref_th/{voice}_{emo}.wav', 'seed': 42 + 97 * q['tries']})
    json.dump(Q, open(qf, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    if jobs_out:
        json.dump(jobs, open(jobs_out, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print(f'QA 편 {len(eps)} 나쁨 {bad} 재생성 {len(jobs)}')


if __name__ == '__main__':
    main()
