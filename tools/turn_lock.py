#!/usr/bin/env python3
"""회화 편 id·턴 번호 잠금 — 학습 기록(숙련도 `s:<편 id>:<턴 번호>`)이 출시 뒤에도 끊기지 않게(2026-11-11).

규칙: 출시 뒤에는 편 id·턴 번호를 다시 매기지 않는다. 줄을 빼면 그 번호는 비워 두고, 끼워 넣는 줄은 새(큰) 번호.
대사를 고치는 것은 괜찮다(같은 번호에 기록이 이어짐).

  python3 tools/turn_lock.py            # 검사: 기준표와 견주어 경고(종료 코드 1 = 경고 있음)
  python3 tools/turn_lock.py --write    # 지금 상태를 기준표로 찍기(출시 빌드 때만)

경고하는 것: 잠긴 편 파일이 사라짐(편 id 변경) · 한 편 안에 같은 번호가 둘 · 잠긴 줄의 대사가 같은 편의 다른 번호로 옮겨 감(번호 다시 매김).
알림만(경고 아님): 잠긴 번호가 비어 있음(줄 뺌) · 새 번호(줄 추가).
"""
import glob
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / 'data/review/turn_lock_th.json'


def current():
    eps = {}
    for p in sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/**/*.json'), recursive=True)):
        ep = json.load(open(p, encoding='utf-8'))
        eps[ep['id']] = [(t.get('num'), t.get('th', '')) for t in ep.get('turns', [])]
    return eps


def check(lock, eps):
    warns, notes = [], []
    for eid, turns in eps.items():
        nums = [n for n, _ in turns]
        dup = sorted({n for n in nums if nums.count(n) > 1})
        if dup:
            warns.append(f'{eid}: 같은 턴 번호 {dup}')
    for eid, old in lock.items():
        if eid not in eps:
            warns.append(f'{eid}: 잠긴 편이 없음 — 편 id 를 바꿨거나 지웠으면 그 편 기록이 끊긴다')
            continue
        now = {n: ja for n, ja in eps[eid]}
        where = {}
        for n, ja in eps[eid]:
            where.setdefault(ja, n)
        for n_str, ja in old.items():
            n = int(n_str)
            if n not in now:
                if ja in where:
                    warns.append(f'{eid}: 턴 {n} 의 줄이 턴 {where[ja]} 로 옮겨 감 — 번호를 다시 매기지 말 것')
                else:
                    notes.append(f'{eid}: 턴 {n} 비움(줄 뺌)')
            elif now[n] != ja and ja in where and where[ja] != n:
                warns.append(f'{eid}: 턴 {n} 의 줄이 턴 {where[ja]} 로 옮겨 감 — 번호를 다시 매기지 말 것')
        new = sorted(set(now) - {int(k) for k in old})
        if new:
            notes.append(f'{eid}: 새 턴 {new}')
    return warns, notes


def main():
    eps = current()
    if '--write' in sys.argv:
        LOCK.parent.mkdir(parents=True, exist_ok=True)
        json.dump({e: {str(n): ja for n, ja in t} for e, t in eps.items()}, open(LOCK, 'w', encoding='utf-8'), ensure_ascii=False, indent=0, sort_keys=True)
        print(f'기준표 {LOCK.relative_to(ROOT)} — 편 {len(eps)} 턴 {sum(map(len, eps.values()))}')
        return
    if not LOCK.exists():
        print('기준표 없음 — 출시 빌드 때 --write')
        return
    warns, notes = check(json.load(open(LOCK, encoding='utf-8')), eps)
    for n in notes:
        print('  note', n)
    for w in warns:
        print('  WARN', w)
    print(f'턴 번호 잠금: 경고 {len(warns)} 알림 {len(notes)}')
    sys.exit(1 if warns else 0)


if __name__ == '__main__':
    main()
