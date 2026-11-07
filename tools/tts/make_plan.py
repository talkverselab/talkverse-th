#!/usr/bin/env python3
"""회화 JSON 의 감정 열 → 감정 계획 자동 생성(사용자 지시 2026-11-07 "음성 만들 때 본 감정을 고려하도록" — 감정을 손으로 다시 적지 않는다).
  python3 tools/tts/make_plan.py <편id>... [--force]     → data/tts/plan/<편id>.json (있으면 건너뜀, --force 면 덮어씀)
- segs: 턴에 `segs`([감정, 본문]) 가 있으면 그대로. 없으면 본문을 문장부호(? ! … 。)로 나누고 `emotions`(둘 이상) 또는 `emotion` 을 차례로 준다.
  감정이 없는 옛 편은 화자·문장부호로 어림(점원 polite, ! → excited/shout, ? → surprised, … → shy, 555 → amused, 그 밖 neutral).
- 읽기: 괄호 지문 제거, 555 → ฮ่าๆ, LINE → ไลน์, 문장 끝에 부호가 없으면 `.` 를 붙여 끊어 읽게 한다.
- cast: 화자 이름 → 목소리(PLAN_GUIDE 표). 모르는 이름은 man_m/woman_m 으로 두고 경고.
- 여성판(f): A(학습자) 턴에 ผม·ครับ 이 있으면 ฉัน·ค่ะ(의문문 คะ) 판을 만든다(`female_ok` 턴은 그대로). 독음도 폼→찬, 크랍→카.
만든 뒤 `check_plan.py` 로 검사하고, 어색한 곳만 손으로 고친다."""
import json, os, re, sys
import ttslib as L
R = L.R
CAST = {'ฟ้า': 'fah', 'ต้น': 'ton', 'พี่หัวหน้า': 'huana', 'หัวหน้า': 'huana', 'เพื่อนร่วมงาน': 'colleague', 'เพื่อนร่วมงานอีกคน': 'man_y',
        'พนักงาน': 'staff', 'พนักงานโรงแรม': 'staff', 'เจ้าหน้าที่': 'staff', 'เภสัช': 'staff', 'แม่ค้า': 'vendor', 'ป้าแม่ค้า': 'vendor', 'พี่วิน': 'win', 'คนขับ': 'win', 'คนขับรถ': 'win', 'ไรเดอร์': 'win', 'คนขับเรือ': 'win',
        'แม่ฟ้า': 'mom', 'แม่ต้น': 'mom', 'แม่': 'mom', 'พ่อฟ้า': 'dad', 'พ่อ': 'dad', 'ครู': 'ajarn', 'อาจารย์': 'ajarn', 'ครูมวย': 'man_m', 'พระ': 'monk', 'คนเมา': 'drunk',
        'นิติ': 'woman_m', 'รปภ.': 'man_m', 'คุณลุง': 'man_o', 'คุณป้า': 'woman_o', 'อาม่า': 'woman_o', 'ป้าชั้นบน': 'woman_m', 'ป้าเจ้าของห้อง': 'woman_m', 'ป้าแม่บ้าน': 'woman_m', 'แม่บ้าน': 'woman_m',
        'เพื่อนร่วมห้อง': 'man_y', 'เพื่อนบ้าน': 'woman_m', 'เพื่อนในกลุ่ม': 'man_y', 'คนแถวนั้น': 'man_y', 'คนโต๊ะข้างๆ': 'woman_y', 'ลูกค้า': 'woman_y', 'ช่างตัดผม': 'man_m',
        'นักศึกษา': 'man_y', 'ผู้บริหาร': 'man_m', 'ผู้ช่วยผู้กำกับ': 'man_y', 'นักร้อง': 'woman_y', 'สตาฟ': 'man_y', 'มิจฉาชีพ': 'man_m', 'เจ้าของร้าน': 'woman_m'}
POLITE = {'staff', 'announce'}
SPLIT = re.compile(r'(?<=[?!…。])\s*')


def reading(s):
    s = re.sub(r'\([^)]*\)|（[^）]*）', '', s)
    s = re.sub(r'5{3,}', 'ฮ่าๆ', s).replace('LINE', 'ไลน์').replace('chill', 'ชิล')
    s = re.sub(r'[\U0001F300-\U0001FAFF☀-➿]', '', s).strip()
    if s and s[-1] not in '?!….': s += '.'
    return s


def guess(sp, voice, text):
    if voice in POLITE: return 'polite'
    if re.search(r'5{3,}|ฮ่า', text): return 'amused'
    if text.rstrip().endswith('!'): return 'shout' if sp != 'A' else 'excited'
    if text.rstrip().endswith('?'): return 'surprised'
    if '…' in text: return 'shy'
    return 'neutral'


def segs_of(t, voice):
    if t.get('segs'):
        return [[s[0], s[1], reading(s[1])] for s in t['segs']]
    parts = [p for p in SPLIT.split(t['th']) if p.strip()] or [t['th']]
    merged = []                                   # 태국 글자가 없는 조각('…'·'?'·'!')은 앞 조각에 붙인다
    for p in parts:
        if merged and not re.search(r'[\u0E00-\u0E7F]', p):
            merged[-1] += p
        else:
            merged.append(p)
    if merged and not re.search(r'[\u0E00-\u0E7F]', merged[0]) and len(merged) > 1:   # 맨 앞 '…' 는 다음 조각 앞에
        merged[1] = merged[0] + merged[1]; merged.pop(0)
    parts = merged
    emos = t.get('emotions') or ([t['emotion']] if t.get('emotion') else [])
    if not emos:
        emos = [guess(t['speaker'], voice, t['th'])]
    if len(emos) == 1 or len(parts) == 1:          # 감정 하나 = 조각 하나(끊어 읽기는 읽기 칸의 부호로)
        return [[emos[0], t['th'], reading(t['th'])]]
    n = len(parts); k = len(emos)
    out = []
    for i, p in enumerate(parts):
        out.append([emos[min(i * k // n, k - 1)], p, reading(p)])
    return out


def female(text):
    f = re.sub(r'ผม(?![ั-ฺ็-๎])', 'ฉัน', text)
    f = re.sub(r'ครับผม', 'ค่ะ', f)
    f = re.sub(r'ครับ(\s*[?？])', r'คะ\1', f)
    return f.replace('ครับ', 'ค่ะ')


def female_rd(rd):
    return re.sub(r'\b폼\b', '찬', rd).replace('크랍', '카')


def main():
    a = [x for x in sys.argv[1:] if x != '--force']; force = '--force' in sys.argv
    for ep in a:
        out = f'{R}/data/tts/plan/{ep}.json'
        if os.path.exists(out) and not force:
            print('있음', ep); continue
        d = json.load(open(L.EP[ep], encoding='utf-8'))
        cast = {}
        for k, v in d['speakers'].items():
            if k == 'A': continue
            cast[k] = CAST.get(v)
            if cast[k] is None:
                cast[k] = 'man_m'; print('  목소리 모름', ep, k, v, '→ man_m')
        turns = {}
        for t in d['turns']:
            voice = 'am' if t['speaker'] == 'A' else cast[t['speaker']]
            T = {'segs': segs_of(t, voice)}
            if t['speaker'] == 'A' and not t.get('female_ok') and re.search(r'ผม|ครับ', t['th']):
                ft = female(t['th'])
                if ft != t['th']:
                    T['f'] = {'text': ft, 'rd': female_rd(t.get('rd', '')), 'ko': t['ko'],
                              'segs': [[s[0], female(s[1]), female(s[2])] for s in T['segs']]}
            turns[str(t['num'])] = T
        json.dump({'ep': ep, 'cast': cast, 'turns': turns}, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        print('OK', ep, len(turns), '턴', sum(1 for T in turns.values() if 'f' in T), '여성판')


if __name__ == '__main__':
    main()
