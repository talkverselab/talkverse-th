#!/usr/bin/env python3
"""참고 음성 검사(§5 품질 기준): 잡음 바닥(무음 구간) ≤ -60dB 만 재생성 근거. 같은 목소리의 감정별 음색 상관(장기 평균 스펙트럼)은 **표시만** 한다 —
문장이 달라 LTAS 상관이 낮게 나와 2026-11-09 190개 중 143개가 미달로 잡혔다(측정 오류). 재생성은 기본(base) 음성을 지우지 않고 감정 음성만.
  <thvenv>/bin/python tools/tts/check_refs.py <ref_th 폴더> [--jobs <vox_jobs.json>]   미달분 재생성 작업(seed 바꿈)을 --jobs 로 쓴다."""
import glob, json, os, re, subprocess, sys
import numpy as np
import ttslib as L
NOISE, CORR = -60.0, 0.90


def pcm(f):
    o = subprocess.run(['ffmpeg', '-v', 'error', '-i', f, '-f', 'f32le', '-ac', '1', '-ar', '16000', '-'], capture_output=True).stdout
    return np.frombuffer(o, dtype=np.float32)


def ltas(x):
    n = 1024; frames = [x[i:i + n] for i in range(0, len(x) - n, n // 2)]
    frames = [fr for fr in frames if np.sqrt(np.mean(fr ** 2)) > 0.01]   # 소리 나는 구간만
    if not frames:
        return None
    sp = np.mean([np.abs(np.fft.rfft(fr * np.hanning(n))) for fr in frames], axis=0)
    return np.log(sp[2:200] + 1e-6)                                     # ~30Hz~3.1kHz 대역


def noise(f):
    """무음 구간(-40dB 아래 0.3초 이상)만의 RMS. 그런 구간이 없으면 None(검사 건너뜀) — §5 b189b0c."""
    o = subprocess.run(['ffmpeg', '-hide_banner', '-i', f, '-af', 'silencedetect=n=-40dB:d=0.3', '-f', 'null', '-'], capture_output=True, text=True).stderr
    spans = list(zip(re.findall(r'silence_start: ([\d.]+)', o), re.findall(r'silence_end: ([\d.]+)', o)))
    if not spans:
        return None
    a, b = max(spans, key=lambda x: float(x[1]) - float(x[0]))
    oo = subprocess.run(['ffmpeg', '-hide_banner', '-ss', a, '-to', b, '-i', f, '-af', 'astats=measure_perchannel=none:measure_overall=RMS_level', '-f', 'null', '-'], capture_output=True, text=True).stderr
    m = re.search(r'RMS level dB: (-?[\d.]+|-inf)', oo)
    return -99.0 if (m and m.group(1) == '-inf') else (float(m.group(1)) if m else None)


def main():
    a = sys.argv[1:]; jobs_out = None
    if '--jobs' in a:
        i = a.index('--jobs'); jobs_out = a[i + 1]; a = a[:i] + a[i + 2:]
    d = a[0]; bad = {}
    files = sorted(glob.glob(f'{d}/*.wav'))
    base = {}
    for f in files:
        n = os.path.basename(f)[:-4]; v, e = n.rsplit('_', 1)
        nf = noise(f)
        if nf is not None and nf > NOISE:
            bad[n] = f'noise {nf:.0f}dB'
        if e == 'base':
            base[v] = ltas(pcm(f))
    for f in files:
        n = os.path.basename(f)[:-4]; v, e = n.rsplit('_', 1)
        if e == 'base' or v not in base or base[v] is None:
            continue
        s = ltas(pcm(f))
        c = float(np.corrcoef(base[v], s)[0, 1]) if s is not None else 0.0
        if c < CORR:
            print(n, f'(표시만) timbre {c:.2f}')
    bad = {n: w for n, w in bad.items() if not n.endswith('_base')}   # 기본 음성은 다시 만들지 않는다(감정 음성이 참조함)
    for n, why in sorted(bad.items()):
        print(n, why)
    print(f'참고 음성 {len(files)} 미달 {len(bad)}')
    if jobs_out:
        vox = []
        for n in bad:
            v, e = n.rsplit('_', 1); x = L.V['voices'][v]
            if e == 'base':
                vox.append({'out': f'ref_th/{n}.wav', 'text': L.V['base_text'], 'instruct': x['desc'], 'seed': 7})
            else:
                E = L.V['emotions'][e]
                vox.append({'out': f'ref_th/{n}.wav', 'text': E['ref'], 'instruct': f"{x['desc']}, {E['instruct']}", 'reference': f'out/ref_th/{v}_base.wav', 'seed': 7})
        json.dump(vox, open(jobs_out, 'w', encoding='utf-8'), ensure_ascii=False, indent=0); print('재생성', len(vox))


if __name__ == '__main__':
    main()
