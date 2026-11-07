#!/usr/bin/python3
"""문장 조각 wav → 턴별 mp4(AAC) → R2 `audio/th/<편>/<턴>_<m|f>.mp4` + D1 `audio_lines`(그 편의 줄을 지우고 다시 넣는다).
모든 턴에 남성판·여성판 두 파일·두 줄(본문 text(태국어)·reading(빈 값)·rd(한글 독음)·ko(한국어 뜻) 포함). 두 판의 소리가 같아도 따로 올린다 — 구조를 단순하게.
조각마다 앞뒤 무음을 자르고 0.25초 넘는 쉼을 줄인 뒤 0.18초 간격으로 잇고 소리 크기를 맞춘다(-18 LUFS). 말 속도가 참고 음성 중앙값(12 글자/초)의 0.75배 미만이면 음높이를 유지한 채 최대 1.15배로 맞춘다(§5 품질 기준 2026-11-07).
  python3 tools/tts/pack.py <wav폴더> <편id>... [--upload]
목록 = data/tts/audio_th.json(리뷰 페이지용). 주소에는 ?v=<sha1 앞 8자리>(서버 캐시가 1년)."""
import datetime, hashlib, json, os, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
import ttslib as L
R = L.R
TRIM = ('silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.03,areverse,'
        'silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,areverse,'
        'silenceremove=stop_periods=-1:stop_duration=0.25:stop_threshold=-45dB:stop_silence=0.25')
RATE_LO = 12.0 * 0.75   # 태국어 참고 음성 중앙값 12 글자/초의 0.75배 아래면 최대 1.15배(§5)
thai_len = lambda s: len(__import__('re').findall(r'[\u0E00-\u0E7F]', s))
W = ['npx', '-y', 'wrangler@4']


def run(*a):
    subprocess.run(a, check=True, capture_output=True)


def build(wav, ep, num, tag, n, out, tmp, texts=()):
    parts = []
    for i in range(n):
        o = f'{tmp}/{ep}_{num}_{i}_{tag}.wav'
        src = f'{wav}/{ep}/{num:02d}_{i}_{tag}.wav'
        run('ffmpeg', '-y', '-i', src, '-af', TRIM, '-ar', '24000', '-ac', '1', o)
        if os.path.getsize(o) < 1000:            # 소리가 작아 무음 자르기에 전부 잘려 나간 조각(ffmpeg 는 0 을 돌려준다) → 자르지 않고 쓴다
            run('ffmpeg', '-y', '-i', src, '-ar', '24000', '-ac', '1', o)
        if i < len(texts) and thai_len(texts[i]) >= 5:   # 느린 조각은 최대 1.15배(음높이 유지)
            d = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', o], capture_output=True, text=True).stdout or 0)
            rate = thai_len(texts[i]) / d if d else 99
            if rate < RATE_LO:
                k = min(1.15, RATE_LO / rate); o2 = o[:-4] + '_t.wav'
                run('ffmpeg', '-y', '-i', o, '-af', f'atempo={k:.3f}', o2); o = o2
        parts.append(o)
    gap = f'{tmp}/gap.wav'
    if not os.path.exists(gap):
        run('ffmpeg', '-y', '-f', 'lavfi', '-i', 'anullsrc=r=24000:cl=mono', '-t', '0.18', gap)
    lst = f'{tmp}/{ep}_{num}_{tag}.txt'; open(lst, 'w').write(''.join(f"file '{x}'\n" for p in parts for x in (p, gap))[:-len(f"file '{gap}'\n")])
    j = f'{tmp}/{ep}_{num}_{tag}_j.wav'; run('ffmpeg', '-y', '-f', 'concat', '-safe', '0', '-i', lst, '-c', 'copy', j)
    run('ffmpeg', '-y', '-i', j, '-af', 'apad=pad_dur=0.12,loudnorm=I=-18:TP=-1.5:LRA=11,aresample=44100', '-ac', '1',
        '-c:a', 'aac', '-b:a', '80k', '-movflags', '+faststart', '-f', 'mp4', '-map_metadata', '-1', out)
    return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', out], capture_output=True, text=True).stdout)


def put(r):
    for _ in range(3):
        x = subprocess.run(W + ['r2', 'object', 'put', f"talkverse-art/{r['key']}", '--file', r['f'], '--content-type', 'audio/mp4', '--remote'], cwd=R, capture_output=True, text=True)
        if x.returncode == 0:
            return None
    return r['key'] + ' ' + x.stderr[-200:]


def main():
    UP = '--upload' in sys.argv; a = [x for x in sys.argv[1:] if x != '--upload']; wav, eps = a[0], a[1:]
    tmp = tempfile.mkdtemp(); q = lambda s: "'" + s.replace("'", "''") + "'"
    mf = f'{R}/data/tts/audio_th.json'
    for ep in eps:
        rows = []
        for t in L.turns(ep):
            for g in 'mf':
                x = t[g]; tag = 'c' if t['same'] else g; f = f"{tmp}/{ep}_{t['num']:02d}_{g}.mp4"
                d = build(wav, ep, t['num'], tag, len(x['segs']), f, tmp, texts=[s[1] for s in x['segs']])
                rows.append(dict(turn=t['num'], voice=g, speaker=x['voice'], emotion='+'.join(s[0] for s in x['segs']), key=f"audio/th/{ep}/{t['num']:02d}_{g}.mp4",
                                 sha1=hashlib.sha1(open(f, 'rb').read()).hexdigest(), ms=int(d * 1000), text=x['text'], reading=x['reading'], rd=x['rd'], ko=x['ko'], f=f))
        if UP:
            with ThreadPoolExecutor(8) as ex:
                err = [e for e in ex.map(put, rows) if e]
            if err:
                sys.exit('R2 실패 ' + ' | '.join(err[:3]))
            now = datetime.datetime.now(datetime.UTC).strftime('%Y-%m-%d %H:%M:%S')
            sql = [f"DELETE FROM audio_lines WHERE lang='th' AND episode='{ep}';"] + [
                "INSERT INTO audio_lines (lang,episode,turn,voice,speaker,emotion,key,ms,sha1,text,reading,rd,ko,created_at) VALUES "
                f"('th','{ep}',{r['turn']},'{r['voice']}','{r['speaker']}','{r['emotion']}','{r['key']}',{r['ms']},'{r['sha1']}',{q(r['text'])},{q(r['reading'])},{q(r['rd'])},{q(r['ko'])},'{now}');" for r in rows]
            sf = f'{tmp}/{ep}.sql'; open(sf, 'w', encoding='utf-8').write('\n'.join(sql) + '\n')
            x = subprocess.run(W + ['d1', 'execute', 'talkverse-db', '--remote', '--file', sf, '-y'], cwd=R, capture_output=True, text=True)
            if x.returncode:
                sys.exit('D1 실패 ' + ep + x.stderr[-400:] + x.stdout[-300:])
        M = json.load(open(mf, encoding='utf-8')) if os.path.exists(mf) else {}
        M[ep] = [{k: v for k, v in r.items() if k not in ('f', 'text', 'reading', 'rd', 'ko')} for r in rows]
        json.dump(M, open(mf, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        print(ep, len(rows), '줄', sum(r['ms'] for r in rows) // 1000, '초', '올림' if UP else '안 올림', flush=True)


if __name__ == '__main__':
    main()
