#!/usr/bin/env python3
"""참고 음성 검사(§5 품질 기준 2026-11-07): 잡음 바닥 ≤ -60dB · 같은 목소리의 감정별 음색(장기 평균 스펙트럼) 상관 ≥ 0.90.
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
    o = subprocess.run(['ffmpeg', '-hide_banner', '-i', f, '-af', 'astats=measure_perchannel=none:measure_overall=Noise_floor', '-f', 'null', '-'], capture_output=True, text=True).stderr
    m = re.search(r'Noise floor dB: (-?[\d.]+|-inf)', o)
    return -99.0 if not m or m.group(1) == '-inf' else float(m.group(1))


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
        if nf > NOISE:
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
            bad[n] = (bad.get(n, '') + f' timbre {c:.2f}').strip()
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
