#!/usr/bin/python3
"""언어감각 외울 대화 → 음성용 편(2026-11-20, uk 배정 11-21 새벽 100조각).
  python3 tools/tts/sense_eps.py   → data/tts/sense_ep/sense_L<n>.json(회화 꼴, ttslib.EP 가 읽음) + data/tts/plan/sense_L<n>.json
- 한 줄 = 한 턴(num = 줄 번호 1부터). 앱은 DialogueAudio.play('sense_L<n>', 줄 번호) 로 재생하고 없으면 기기 TTS.
- 화면 글자가 남성 학습자(ผม/ครับ)판 하나라 성별판을 만들지 않는다 — 학습자 「나」도 고정 목소리(am), 두 판이 같아 조각은 c 하나.
- {말|번호} 색 표시는 지우고 읽는다. 감정은 make_plan 과 같은 어림(guess)."""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ttslib as L
import make_plan as MP

R = L.R
MARK = re.compile(r'\{([^|}]+)\|\d+\}')
WHO = {'나': 'am', 'ฟ้า': 'fah', 'ต้น': 'ton', '아주머니': 'woman_m', '친구': 'man_y', 'มิน': 'man_y', 'คุณ': 'man_m', 'น้อง': 'man_y',
       'พี่': 'woman_y', '관리인': 'man_m', '민': 'man_y', '유': 'woman_y', '찬': 'man_m', '이웃': 'man_m'}


def voice_of(who, lines):
    if who in WHO:
        return WHO[who]
    t = ' '.join(lines)
    print('  목소리 어림', who)
    return 'woman_m' if re.search('ค่ะ|คะ|ฉัน', t) else 'man_m'


def main():
    d = json.load(open(f'{R}/assets/data/grammar/sense_course.json', encoding='utf-8'))
    os.makedirs(f'{R}/data/tts/sense_ep', exist_ok=True)
    n_all = 0
    for lv in d['levels']:
        ls = next((x for x in lv['lessons'] if x['kind'] == 'memorize'), None)
        if not ls or not ls.get('sentences'):
            continue
        ep = f"sense_{lv['id']}"
        rows = [{'who': s['who'], 'th': MARK.sub(lambda m: m.group(1), s['th']), 'rd': s.get('rd', ''), 'ko': MARK.sub(lambda m: m.group(1), s.get('ko', ''))} for s in ls['sentences']]
        whos = list(dict.fromkeys(r['who'] for r in rows))
        letter = {w: chr(ord('B') + i) for i, w in enumerate(whos)}   # A 는 성별판을 만들므로 쓰지 않는다
        cast = {letter[w]: voice_of(w, [r['th'] for r in rows if r['who'] == w]) for w in whos}
        turns, plan = [], {}
        for i, r in enumerate(rows, 1):
            t = {'num': i, 'speaker': letter[r['who']], 'th': r['th'], 'rd': r['rd'], 'ko': r['ko']}
            turns.append(t)
            plan[str(i)] = {'segs': MP.segs_of(t, cast[t['speaker']])}
        json.dump({'id': ep, 'title': lv.get('title', ''), 'speakers': {letter[w]: w for w in whos}, 'turns': turns},
                  open(f'{R}/data/tts/sense_ep/{ep}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        json.dump({'ep': ep, 'cast': cast, 'turns': plan}, open(f'{R}/data/tts/plan/{ep}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        n_all += len(turns)
        print(ep, len(turns), '줄', cast)
    print('합계', n_all, '줄')


if __name__ == '__main__':
    main()
