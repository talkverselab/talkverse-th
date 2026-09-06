r"""단어 파이프라인 체크포인트 상태 확인.

사용:  python -X utf8 tools/vocab_pipeline/status.py
- captures/  : Desktop\태국어단어\*.jpg 캡처 → 이미지별 JSON (비전 추출)
- book/      : 나혼자끝내는태국어단어장_개정판 MD → 일차별 JSON
- pages/     : Desktop\태국어단어\20260906_*.jpg 본문 캡처 → 이미지별 MD (비전 전사)

API 단절 등으로 중단되면 이 스크립트로 누락 단위만 골라 다시 돌린다.
"""
import glob
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
CAPTURE_DIR = r"C:\Users\Johnjeon\Desktop\태국어단어"


def check_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            d = json.load(f)
        return len(d.get("entries", []))
    except Exception as e:  # noqa: BLE001
        return f"BROKEN({e.__class__.__name__})"


def main():
    print("== captures (이미지 → JSON) ==")
    missing = []
    imgs = sorted(glob.glob(os.path.join(CAPTURE_DIR, "*.jpg"))) if os.path.isdir(CAPTURE_DIR) else []
    total = 0
    cimgs = [i for i in imgs if os.path.basename(i).startswith("20260904_")]
    for img in cimgs:
        base = os.path.splitext(os.path.basename(img))[0]
        out = os.path.join(HERE, "captures", base + ".json")
        if os.path.exists(out):
            n = check_json(out)
            if isinstance(n, int):
                total += n
            else:
                missing.append(base)
            print(f"  {base}: {n}")
        else:
            missing.append(base)
            print(f"  {base}: MISSING")
    print(f"  → 완료 {len(cimgs) - len(missing)}/{len(cimgs)}, 단어 {total}개")
    if missing:
        print("  재실행 필요:", ", ".join(missing))


    print("\n== pages (본문 이미지 → MD) ==")
    missing_p = []
    pimgs = [i for i in imgs if not os.path.basename(i).startswith("20260904_")]
    for img in pimgs:
        base = os.path.splitext(os.path.basename(img))[0]
        out = os.path.join(HERE, "pages", base + ".md")
        if os.path.exists(out) and os.path.getsize(out) > 200:
            txt = open(out, encoding="utf-8").read()
            pages = re.findall(r"<!-- PAGE ([^>]+) -->", txt)
            rows = sum(1 for l in txt.splitlines() if l.startswith("|") and not re.match(r"^\|[\s|:-]+\|$", l) and "| 한국어" not in l)
            print(f"  {base}: p.{'/'.join(pages)} rows={rows}")
        else:
            missing_p.append(base)
            print(f"  {base}: MISSING")
    print(f"  → 완료 {len(pimgs) - len(missing_p)}/{len(pimgs)}")
    if missing_p:
        print("  재실행 필요:", ", ".join(missing_p))

    print("\n== book (일차 MD → JSON) ==")
    missing_b = []
    total_b = 0
    for md in sorted(glob.glob(os.path.join(HERE, "book", "day*.md"))):
        base = os.path.splitext(os.path.basename(md))[0]
        out = os.path.join(HERE, "book", base + ".json")
        if os.path.exists(out):
            n = check_json(out)
            if isinstance(n, int):
                total_b += n
            else:
                missing_b.append(base)
            print(f"  {base}: {n}")
        else:
            missing_b.append(base)
            print(f"  {base}: MISSING")
    print(f"  → 단어 {total_b}개")
    if missing_b:
        print("  재실행 필요:", ", ".join(missing_b))


if __name__ == "__main__":
    main()
