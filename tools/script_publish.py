#!/usr/bin/env python3
"""원고를 서버에 올려 깔린 앱이 심사·새 빌드 없이 받게 한다(사용자 지시 2026-11-17). 규격 = docs/CONTENT_SYNC.md §6.

대상: 회화 편 `assets/data/dialogues/R0~R4/**.json` + 언어감각 `assets/data/grammar/sense_course.json`.
앱 안 기준표 `assets/data/script_rev.json`(rev·파일별 sha1 앞 12자리)과 지금 파일을 견주어 바뀐 것만 올린다.

  python3 tools/script_publish.py             # 무엇이 바뀌었는지만 본다(아무것도 안 올림)
  python3 tools/script_publish.py --publish   # 턴 번호 잠금 검사 → 바뀐 파일을 R2 에 → index.json → 기준표 rev+1 (기준표는 커밋할 것)
  python3 tools/script_publish.py --init      # 처음 한 번: 지금 상태를 rev 1 기준표로 찍고 index.json 만 올림

서버: R2 `talkverse-art` 의 `script/th/<경로>` · 앱이 읽는 주소 `https://auth.talkverse.uk/art/script/th/<경로>`.
앱은 서버 rev 가 앱 안 rev 보다 클 때만 받는다 — 올린 뒤에 만든 빌드는 같은 rev 를 싣고 나가므로 다시 받지 않는다.
편을 지우면 index 에서 빠져 앱에서 숨는다. 턴 번호·편 id 는 다시 매기지 말 것(tools/turn_lock.py).
"""
import glob
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'assets/data'
BASE = DATA / 'script_rev.json'
BUCKET = 'talkverse-art'
PREFIX = 'script/th'


def current():
    paths = sorted(glob.glob(str(DATA / 'dialogues/R[0-4]/*/*.json'))) + [str(DATA / 'grammar/sense_course.json')]  # 언어감각 과정도 원고처럼(일본어앱 §1-3 셋째, 2026-11-19)
    out = {}
    for p in paths:
        b = Path(p).read_bytes()
        json.loads(b)  # 깨진 JSON 은 올리지 않는다
        out[str(Path(p).relative_to(DATA))] = hashlib.sha1(b).hexdigest()[:12]
    return out


def put(rel, src):
    r = subprocess.run(['npx', '-y', 'wrangler@4', 'r2', 'object', 'put', f'{BUCKET}/{PREFIX}/{rel}', '--file', str(src),
                        '--content-type', 'application/json; charset=utf-8', '--remote'], cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f'올리기 실패 {rel}\n{r.stdout[-400:]}{r.stderr[-400:]}')


def put_index(rev, files):
    with tempfile.NamedTemporaryFile('w', suffix='.json', delete=False, encoding='utf-8') as f:
        json.dump({'rev': rev, 'files': files}, f, ensure_ascii=False, sort_keys=True)
    put('index.json', f.name)
    Path(f.name).unlink()


def write_base(rev, files):
    BASE.write_text(json.dumps({'rev': rev, 'files': files}, ensure_ascii=False, indent=0, sort_keys=True) + '\n', encoding='utf-8')


def main():
    now = current()
    if '--init' in sys.argv:
        if BASE.exists():
            sys.exit('기준표가 이미 있음 — --publish 를 쓸 것')
        write_base(1, now)
        put_index(1, now)
        print(f'기준표 rev 1 — 파일 {len(now)} · index.json 올림')
        return
    base = json.loads(BASE.read_text(encoding='utf-8'))
    old = base['files']
    chg = sorted(p for p in now if p in old and old[p] != now[p])
    add = sorted(p for p in now if p not in old)
    rem = sorted(p for p in old if p not in now)
    for tag, ps in (('바뀜', chg), ('새로', add), ('빠짐', rem)):
        for p in ps:
            print(f'  {tag} {p}')
    print(f'기준 rev {base["rev"]} — 바뀜 {len(chg)} 새로 {len(add)} 빠짐 {len(rem)}')
    if '--publish' not in sys.argv or not (chg or add or rem):
        return
    if subprocess.run([sys.executable, str(ROOT / 'tools/turn_lock.py')], cwd=ROOT).returncode != 0:
        sys.exit('턴 번호 잠금 경고 — 번호를 다시 매기지 말고 고친 뒤 다시')
    for p in chg + add:
        put(p, DATA / p)
        print(f'  올림 {p}')
    rev = base['rev'] + 1
    put_index(rev, now)  # 파일을 다 올린 뒤에 목록 — 앱이 없는 파일을 찾지 않게
    write_base(rev, now)
    print(f'rev {rev} 올림 — assets/data/script_rev.json 을 커밋할 것')


if __name__ == '__main__':
    main()
