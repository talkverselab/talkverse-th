#!/usr/bin/python3
"""감정 계획 → PC 작업 파일(D:\\tts_test\\job 에 넣는다). 태국어 = language 'Thai'.
  python3 tools/tts/make_jobs.py <출력폴더> --refs [편id...]   쓰이는 (목소리, 감정) 참고 음성 → vox_jobs.json (편을 주면 그 편들만)
  PC 출력은 out/th/<편>/, 참고 음성은 out/ref_th/ 에 둔다(편 id·목소리 이름이 다른 언어와 같아 한 폴더를 쓰면 생성기가 건너뛰어 버림).
  python3 tools/tts/make_jobs.py <출력폴더> <편id>...          문장 조각 → moss_jobs.json (out/th/<편>/<턴>_<조각>_<c|m|f>.wav)"""
import json, sys
import ttslib as L


def main():
    out, eps = sys.argv[1], sys.argv[2:]
    if eps and eps[0] == '--refs':
        ids = eps[1:] or L.planned()
        need = sorted({(v, e) for ep in ids for _, v, e, _ in L.seg_files(ep)})
        vox = [{'out': f'ref_th/{v}_base.wav', 'text': L.V['base_text'], 'instruct': L.V['voices'][v]['desc']} for v in sorted({v for v, _ in need})]
        for v, e in need:
            x, E = L.V['voices'][v], L.V['emotions'][e]
            vox.append({'out': f'ref_th/{v}_{e}.wav', 'text': E['ref'], 'instruct': f"{x['desc']}, {E['instruct']}", 'reference': f'out/ref_th/{v}_base.wav'})
        json.dump(vox, open(f'{out}/vox_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0); print(len(vox), 'vox'); return
    moss = [{'out': f'th/{ep}/{f}', 'text': text, 'language': 'Thai', 'reference': f'out/ref_th/{v}_{e}.wav'} for ep in eps for f, v, e, text in L.seg_files(ep)]
    json.dump(moss, open(f'{out}/moss_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0); print(len(moss), 'moss')


if __name__ == '__main__':
    main()
