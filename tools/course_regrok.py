#!/usr/bin/env python3
"""「내 코스」 스크립트를 Grok 대사로 다시 쓴다(사용자 지시 2026-11-19 「1 2 3 모두 진행」, 회화 원칙 11-18: Claude 초안 → Grok 대사 그대로).
  python3 tools/course_regrok.py prompts            → data/review/course/<키>_prompt.md (뼈대만: 제목·장면 한 줄·인물·레벨·말투·턴 수·화자 순서·반전 턴/종류·문법 목표)
  python3 tools/course_regrok.py apply [키 ...]     → Grok 답(data/review/course/<키>_write.md)을 원본 scripts_src*.txt 의 턴 줄에 넣는다
                                                     (머리줄·> 줄은 그대로, 독음은 rd_th 로 새로, 화자 순서·턴 수가 뼈대와 다르면 그 편은 건너뜀)
뼈대에 원래 대사(태국어·한국어)를 옮겨 적지 않는다(uk 11-19: 옮겨 적으면 Grok 이 직역함). 문법 목표는 초급 노트의 「문법:」 항목 이름만."""
import io, json, os, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SE = ROOT / 'drafts/script_engine'
OUT = ROOT / 'data/review/course'
sys.path.insert(0, str(ROOT / 'tools'))
FILES = ['scripts_src.txt', 'scripts_src_beginner.txt']
LV = {'beg': ('초급(R1)', '짧은 공손형 문장, 한 턴 독음 20음절 이하'), 'mid': ('중급(R2)', '자연스러운 구어, 한두 문장'), 'adv': ('고급(R3)', '구어·관용 표현, 두세 문장까지')}
TT = {'chaos': '카오스(상황이 엉뚱하게 꼬임)', 'slip': '말실수(학습자 태국어 실수로 오해)', 'reveal': '밝혀짐(숨은 사실이 드러남)', 'emotion': '감정 반전(마음이 드러남)', 'ignore': '무시·엇갈림'}
RULES = ("형식: 한 턴 = 한 줄 `번호 화자: 태국어 / 한국어 뜻 / 노트` (칸 사이 ` / `, 칸 3개). 노트 = {note}. "
         "규칙: 방콕 표준 구어 · 기본판은 남자 학습자(ผม/ครับ) · 상대 이름·역할은 위 그대로 · 화자 순서·턴 수 그대로 · 반전은 지정한 턴에 · 태국어 칸은 태국 글자만(영어 단어 금지) · 수위 12+ · 실존 인물·브랜드·작품 이름 금지 · 대사는 전부 새로 쓸 것. 다른 말 없이 턴 줄만.")


def parse():
    eps = []
    for fn in FILES:
        lines = io.open(SE / fn, encoding='utf-8').read().split('\n')
        cur = None
        for i, line in enumerate(lines):
            if line.startswith('###'):
                p = [x.strip() for x in line[3:].split('|')]
                tags = dict(t.split(':', 1) for t in p[7].split('=', 1)[1].split(',') if t)
                cur = {'file': fn, 'key': p[0], 'title': p[3], 'A': p[4].split('=', 1)[1], 'B': p[5].split('=', 1)[1],
                       'level': tags.get('level', 'mid'), 'reg': tags.get('reg', ''), 'twist': int(tags.get('twist', 0)), 'tt': tags.get('tt', ''),
                       'hook': '', 'turns': []}
                eps.append(cur)
            elif cur and line.startswith('>'):
                cur['hook'] = line[1:].strip()
            elif cur and line[:2] in ('A|', 'B|'):
                p = line.split('|')
                cur['turns'].append({'ln': i, 'sp': p[0], 'note': p[4].strip() if len(p) > 4 else ''})
    return eps


def safe(key):
    return key.replace('#', '_')


def grammar_targets(ep):
    g = []
    for t in ep['turns']:
        m = re.match(r'문법:\s*(.*)', t['note'])
        if m:
            for x in m.group(1).split('·'):
                x = re.sub(r'\s*\(.*?\)', '', x).strip()
                if x and x not in g:
                    g.append(x)
    return g


def prompts():
    OUT.mkdir(parents=True, exist_ok=True)
    eps = parse()
    for ep in eps:
        lv, style = LV[ep['level']]
        order = ''.join(t['sp'] for t in ep['turns'])
        g = grammar_targets(ep)
        note = ('「문법: 항목 · 항목」(이 턴에 쓴 문법을 짧게)' if ep['level'] == 'beg' else '이 턴의 새 표현 1~2개 「태국어 = 한국어 뜻」')
        s = (f"[{safe(ep['key'])}] 태국어 학습 앱 「내 코스」 회화를 새로 써 주세요. 제목 「{ep['title']}」. 장면: {ep['hook']} "
             f"| A = 학습자 {ep['A']} · B = {ep['B']} | {lv} — {style} | 말투 {ep['reg'] or 'polite'} "
             f"| {len(ep['turns'])}턴, 화자 순서 {'-'.join(order)} | 반전 {ep['twist']}턴: {TT.get(ep['tt'], ep['tt'])} "
             + (f"| 문법 목표(골고루): {' · '.join(g[:12])} " if g else '')
             + '| ' + RULES.format(note=note))
        (OUT / f"{safe(ep['key'])}_prompt.md").write_text(s + '\n', encoding='utf-8')
    print('요청문', len(eps), '→', OUT)


TURN = re.compile(r'^\s*\**(\d+)\s*\**\s*([AB])\s*[:：]\s*(.+)$')


def apply(keys):
    import rd_th
    eps = parse()
    want = set(keys)
    texts = {fn: io.open(SE / fn, encoding='utf-8').read().split('\n') for fn in FILES}
    done = skip = 0
    for ep in eps:
        k = safe(ep['key'])
        if want and k not in want and ep['key'] not in want:
            continue
        f = OUT / f'{k}_write.md'
        if not f.exists():
            continue
        rows = []
        for line in f.read_text(encoding='utf-8').split('\n'):
            m = TURN.match(line.strip())
            if m:
                parts = [x.strip() for x in m.group(3).split(' / ')]
                rows.append((m.group(2), parts))
        order = [t['sp'] for t in ep['turns']]
        bad = [len(p) for _, p in rows if len(p) != 3]
        if [r[0] for r in rows] != order or bad:
            print('건너뜀', k, '— 화자 순서/턴 수', ''.join(r[0] for r in rows), 'vs', ''.join(order), ('칸 수 ' + str(bad)) if bad else '')
            skip += 1
            continue
        L = texts[ep['file']]
        for t, (sp, (th, ko, note)) in zip(ep['turns'], rows):
            th = th.replace('|', ' ').strip()
            q = re.findall(r'「([^」]+)」', note)
            if q:  # Grok 이 「…」「…」 로 묶어 오면 기존 꼴 「A = 뜻 · B = 뜻」 으로(형식만)
                note = ' · '.join(x.strip() for x in q)
            L[t['ln']] = '|'.join([sp, th, rd_th.rd(th), ko.replace('|', ' '), note.replace('|', ' ')])
        done += 1
    for fn, L in texts.items():
        io.open(SE / fn, 'w', encoding='utf-8').write('\n'.join(L))
    print('넣음', done, '건너뜀', skip)


if __name__ == '__main__':
    if sys.argv[1:2] == ['prompts']:
        prompts()
    elif sys.argv[1:2] == ['apply']:
        apply(sys.argv[2:])
    else:
        print(__doc__)
