#!/usr/bin/env python3
"""문장 끝 어조사로 감정을 나타내는 턴에 어울리는 이모지(`emoji`)를 붙인다(사용자 지시 2026-11-07, 한·중·일·태·베 공통, 기존 회화 포함).
  python3 tools/add_emoji.py [--force] [편.json ...]   (없으면 전편) — 이미 있으면 두고, --force 면 다시 고른다.
어조사(นะ สิ เถอะ เหรอ ล่ะ อะ ว่ะ จ้า เนี่ย ไง แหละ น่า ไหม/มั้ย, นะคะ/นะครับ)가 **마지막 문장 끝**에 있을 때만. 감정 열(`emotion`)이 있으면 그에 맞추고, 없으면 어조사·문장부호·555 로 고른다.
이모지는 `th` 본문에 넣지 않고 따로 둔다 — 음성 본문(읽기)에 들어가지 않게. 앱·리뷰 페이지가 태국어 줄 끝에 보여 준다."""
import glob, json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
PART = re.compile(r'(นะคะ|นะครับ|นะ|น่า|สิ|ซิ|เถอะ|เหอะ|เหรอ|หรอ|เรอะ|ล่ะ|อ่ะ|อะ|ว่ะ|วะ|โว้ย|จ้ะ|จ้า|จ๊ะ|เนี่ย|ไง|แหละ|มั้ย|ไหม)\s*[?!…。.~]*\s*$')
BASE = {'นะ': '🙂', 'นะคะ': '🙂', 'นะครับ': '🙂', 'น่า': '🥺', 'สิ': '👉', 'ซิ': '👉', 'เถอะ': '🙌', 'เหอะ': '🙌', 'เหรอ': '😮', 'หรอ': '😮', 'เรอะ': '😮',
        'ล่ะ': '🤷', 'อะ': '😅', 'อ่ะ': '😅', 'ว่ะ': '😤', 'วะ': '😤', 'โว้ย': '😤', 'จ้ะ': '😊', 'จ้า': '😊', 'จ๊ะ': '😊', 'เนี่ย': '😑', 'ไง': '😉', 'แหละ': '😌', 'มั้ย': '🤔', 'ไหม': '🤔'}
EMO = {'gentle': '🥰', 'shy': '☺️', 'worried': '😟', 'teasing': '😏', 'annoyed': '😒', 'amused': '😆', 'excited': '🤩', 'surprised': '😲', 'shout': '😱',
       'tsukkomi': '🙄', 'sad': '😢', 'flustered': '😳', 'cheerful': '😄', 'stiff': '😬', 'polite': '🙏', 'neutral': None}


def pick(t):
    th = t['th']
    m = PART.search(th)
    if not m:
        return None
    p = m.group(1)
    e = (t.get('emotions') or [None])[-1] or t.get('emotion')
    if e and EMO.get(e):
        return EMO[e]
    if re.search(r'5{3,}', th):
        return '😂'
    body = th.rstrip()
    if body.endswith('!') and p in ('นะ', 'นะคะ', 'นะครับ', 'จ้า', 'จ้ะ'):
        return '😊'
    if body.endswith('!') and p in ('สิ', 'ซิ', 'เนี่ย'):
        return '😤'
    if '…' in body[-6:]:
        return '🥺'
    return BASE[p]


def main():
    force = '--force' in sys.argv
    files = [a for a in sys.argv[1:] if not a.startswith('--')] or sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/*/*.json')))
    n = tot = 0
    for f in files:
        raw = open(f, encoding='utf-8').read(); d = json.loads(raw); ch = False
        for t in d['turns']:
            tot += 1
            if t.get('emoji') and not force:
                continue
            e = pick(t)
            if e and t.get('emoji') != e:
                t['emoji'] = e; ch = True; n += 1
            elif not e and 'emoji' in t and force:
                del t['emoji']; ch = True
        if ch:
            o = json.dumps(d, ensure_ascii=False, indent=1)
            open(f, 'w', encoding='utf-8').write(o + ('\n' if raw.endswith('\n') else ''))
    print(f'턴 {tot} 이모지 {n}')


if __name__ == '__main__':
    main()
