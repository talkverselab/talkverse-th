"""캡처 단어장 + 나혼자 단어장 JSON 체크포인트를 병합해 앱 에셋을 생성.

사용:  python -X utf8 tools/vocab_pipeline/build_vocab.py
입력:  captures/*.json, book/day*.json   (status.py 로 누락 확인)
출력:  assets/data/vocab/th_vocab.json   (통합 단어)
       assets/data/vocab/th_roots.json   (루트 단어 — roots_curated.json 이 있으면 그것을 우선)
       tools/vocab_pipeline/root_candidates.json (루트 후보 통계, 검토용)

재실행해도 같은 결과가 나오도록 결정적으로 동작한다 (id = 소스+순번 해시).
"""
import glob
import hashlib
import json
import os
import re
import sys
from collections import Counter, OrderedDict

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT_DIR = os.path.join(ROOT, "assets", "data", "vocab")
os.makedirs(OUT_DIR, exist_ok=True)

THAI = re.compile(r"[฀-๿]")
JONG = {  # 호환 자모 → 종성 인덱스
    "ㄱ": 1, "ㄲ": 2, "ㄳ": 3, "ㄴ": 4, "ㄵ": 5, "ㄶ": 6, "ㄷ": 7, "ㄹ": 8, "ㄺ": 9,
    "ㄻ": 10, "ㄼ": 11, "ㄽ": 12, "ㄾ": 13, "ㄿ": 14, "ㅀ": 15, "ㅁ": 16, "ㅂ": 17,
    "ㅄ": 18, "ㅅ": 19, "ㅆ": 20, "ㅇ": 21, "ㅈ": 22, "ㅊ": 23, "ㅋ": 24, "ㅌ": 25,
    "ㅍ": 26, "ㅎ": 27,
}
JUNG = {  # 호환 모음 → 중성 인덱스
    "ㅏ": 0, "ㅐ": 1, "ㅑ": 2, "ㅒ": 3, "ㅓ": 4, "ㅔ": 5, "ㅕ": 6, "ㅖ": 7, "ㅗ": 8,
    "ㅘ": 9, "ㅙ": 10, "ㅚ": 11, "ㅛ": 12, "ㅜ": 13, "ㅝ": 14, "ㅞ": 15, "ㅟ": 16,
    "ㅠ": 17, "ㅡ": 18, "ㅢ": 19, "ㅣ": 20,
}


def _is_syl(ch):
    return "가" <= ch <= "힣"


def _decompose(ch):
    code = ord(ch) - 0xAC00
    return code // 588, (code % 588) // 28, code % 28


def _compose(cho, jung, jong):
    return chr(0xAC00 + cho * 588 + jung * 28 + jong)


def normalize_reading(raw):
    """책 표기('파낙응아-ㄴ커-ㅇ라-ㄴ', '루r-쓱', '쁘ㅓ-ㄷ')를 앱 표기('파낙응안컹란', '루쓱', '뻗')로."""
    if not raw:
        return ""
    s = raw
    s = re.sub(r"\((?:f|r|y|n|l|v|th|ph|kh|ch)\)", "", s)  # (f) 등 표기 제거
    s = re.sub(r"[A-Za-z]", "", s)  # r/y/f/n 첨자 제거
    s = s.replace("^", "").replace("_", "")
    s = re.sub(r"\s*/\s*", " / ", s)  # 변형 구분자 정리
    s = re.sub(r"(?<!/)\s*[-–—ー]\s*(?!/)", "", s)  # 장음 하이픈 제거
    out = []
    for ch in s:
        if ch in JONG and out and _is_syl(out[-1]):
            cho, jung, jong = _decompose(out[-1])
            if jong == 0:
                out[-1] = _compose(cho, jung, JONG[ch])
                continue
        if ch in JUNG and out and _is_syl(out[-1]):
            cho, jung, jong = _decompose(out[-1])
            if jong == 0 and jung == JUNG["ㅡ"]:
                out[-1] = _compose(cho, JUNG[ch], 0)
                continue
        out.append(ch)
    s = "".join(out)
    s = re.sub(r"[ㄱ-ㅎㅏ-ㅣ]", "", s)  # 결합 못한 잔여 자모 제거
    s = re.sub(r"\s+", " ", s).strip()
    return s


def clean_th(th):
    th = (th or "").strip()
    th = re.sub(r"^[\d\s.]+", "", th)
    return th.strip()


def make_id(src, key):
    return src[0] + hashlib.md5(f"{src}|{key}".encode("utf-8")).hexdigest()[:8]


def load_captures():
    entries = []
    files = sorted(glob.glob(os.path.join(HERE, "captures", "*.json")))
    for fn in files:
        with open(fn, encoding="utf-8") as f:
            d = json.load(f)
        pages = d.get("pages", "")
        for i, e in enumerate(d.get("entries", [])):
            th = clean_th(e.get("th", ""))
            if not th or not THAI.search(th):
                continue
            entries.append(OrderedDict(
                id=make_id("capture", f"{os.path.basename(fn)}#{i}"),
                th=th,
                reading=normalize_reading(e.get("reading", "")),
                readingRaw=(e.get("reading") or "").strip(),
                ko=(e.get("ko") or "").strip(),
                src="capture",
                pages=pages,
                order=len(entries),
                **({"uncertain": True} if e.get("uncertain") else {}),
            ))
    return entries, len(files)


def load_body():
    """회화집 본문(12~153쪽) 단어 표 — build_phrasebook.py 산출물 기반."""
    try:
        from build_phrasebook import body_words
    except ImportError:
        return [], 0
    entries = []
    for i, r in enumerate(body_words()):
        th = clean_th(r["th"])
        if not th:
            continue
        key = f"{r['page']}|{r['group']}|{th}|{r['ko']}"
        entries.append(dict(
            id=make_id("body", key),
            th=th,
            reading=normalize_reading(r["reading"]),
            readingRaw=r["reading"],
            ko=r["ko"],
            src="body",
            order=i,
            pages=str(r["page"]),
            group=r["group"],
            theme=r["topic"],
            uncertain=bool(r.get("uncertain")),
        ))
    return entries, len(entries)


def load_book():
    entries = []
    files = sorted(glob.glob(os.path.join(HERE, "book", "day*.json")))
    themes = {}
    for fn in files:
        with open(fn, encoding="utf-8") as f:
            d = json.load(f)
        if d.get("day") and d.get("theme"):
            themes[int(d["day"])] = d["theme"]
        for i, e in enumerate(d.get("entries", [])):
            th = clean_th(e.get("th", ""))
            if not th or not THAI.search(th):
                continue
            day = int(e.get("day") or d.get("day") or 0)
            item = OrderedDict(
                id=make_id("book", f"{os.path.basename(fn)}#{i}"),
                th=th,
                reading=normalize_reading(e.get("reading", "")),
                readingRaw=(e.get("reading") or "").strip(),
                ko=(e.get("ko") or "").strip(),
                src="book",
                day=day,
                kind=e.get("kind", "plus"),
                order=len(entries),
            )
            if e.get("num"):
                item["num"] = int(e["num"])
            if e.get("group"):
                item["group"] = e["group"]
            if e.get("ex_th"):
                item["ex"] = OrderedDict(
                    th=e.get("ex_th", "").strip(),
                    reading=normalize_reading(e.get("ex_reading", "")),
                    readingRaw=(e.get("ex_reading") or "").strip(),
                    ko=(e.get("ex_ko") or "").strip(),
                )
            if e.get("uncertain"):
                item["uncertain"] = True
            entries.append(item)
    if any(e["day"] == 1 for e in entries):
        themes.setdefault(1, "왕초보 필수 문법")
    for e in entries:
        e["theme"] = themes.get(e["day"], "")
    return entries, len(files), themes


STOP_ROOTS = set("ที่ ใน ไป มา ไม่ ได้ จะ และ กับ แล้ว ก็ ของ ให้ อยู่ เป็น มี คน การ ความ นี้ นั้น ว่า ๆ ครับ ค่ะ คะ ยัง อีก ด้วย ต้อง ถ้า หรือ แต่ จาก ถึง ตาม เมื่อ กว่า เท่า ไหน อะไร ใคร ทำ ดู เอา ขอ ช่วย".split())


def build_roots(entries, top1000):
    """루트 후보: 어휘 자체가 단어이고 다른 단어 3개 이상에 포함되는 것."""
    by_th = {}
    for e in entries:
        by_th.setdefault(e["th"], e)
    cands = Counter()
    for th in list(by_th) + [w for w in top1000 if w not in by_th]:
        if len(th) < 2 or len(th) > 7 or " " in th or th in STOP_ROOTS:
            continue
        if not re.fullmatch(r"[฀-๿]+", th.replace("ๆ", "")):
            continue
        n = sum(1 for e in entries if th in e["th"] and e["th"] != th)
        if n >= 3:
            cands[th] = n
    return by_th, cands


def main():
    caps, ncap = load_captures()
    body, nbody = load_body()
    book, nbook, themes = load_book()
    entries = caps + body + book
    # 완전 중복(th+ko 동일) 제거 — 앞선 소스 우선
    seen = set()
    uniq = []
    for e in entries:
        key = (e["th"], e["ko"])
        if key in seen:
            continue
        seen.add(key)
        uniq.append(e)
    entries = uniq

    top1000 = []
    try:
        with open(os.path.join(ROOT, "assets", "data", "wordsets", "th_top1000.csv"), encoding="utf-8") as f:
            next(f)
            for line in f:
                parts = line.rstrip("\n").split(",")
                if len(parts) >= 2:
                    top1000.append(parts[1])
    except OSError:
        pass

    by_th, cands = build_roots(entries, top1000)
    top_set = set(top1000)
    cand_list = []
    for th, n in cands.most_common():
        e = by_th.get(th)
        cand_list.append(OrderedDict(
            th=th, derived=n,
            reading=e["reading"] if e else "",
            ko=e["ko"] if e else "",
            inTop1000=th in top_set,
        ))
    with open(os.path.join(HERE, "root_candidates.json"), "w", encoding="utf-8") as f:
        json.dump(cand_list, f, ensure_ascii=False, indent=1)

    curated_path = os.path.join(HERE, "roots_curated.json")
    if os.path.exists(curated_path):
        with open(curated_path, encoding="utf-8") as f:
            roots = json.load(f)["roots"]
        # 검토본에 없는 정보는 후보 통계로 보완
        for r in roots:
            e = by_th.get(r["th"])
            r.setdefault("reading", e["reading"] if e else "")
            r.setdefault("ko", e["ko"] if e else "")
    else:
        roots = [OrderedDict(th=c["th"], reading=c["reading"], ko=c["ko"]) for c in cand_list[:80]]

    with open(os.path.join(OUT_DIR, "th_vocab.json"), "w", encoding="utf-8") as f:
        json.dump(OrderedDict(
            meta=OrderedDict(
                note="reading 은 한글 독음(정규화), readingRaw 는 원서 표기",
                sources=OrderedDict(
                    capture="회화집 단어장 캡처(한→태, 가나다순)",
                    body="회화집 본문(12~153쪽) 단어 표 — th_phrasebook.json 과 동일 출처",
                    book="나혼자 끝내는 태국어 단어장 개정판(30일차)",
                ),
                captureFiles=ncap, bodyEntries=nbody, bookFiles=nbook,
                themes={str(k): v for k, v in sorted(themes.items())},
            ),
            entries=entries,
        ), f, ensure_ascii=False, indent=0)
    with open(os.path.join(OUT_DIR, "th_roots.json"), "w", encoding="utf-8") as f:
        json.dump(OrderedDict(meta=OrderedDict(note="루트 단어 — 파생어는 앱에서 포함 관계로 계산"), roots=roots),
                  f, ensure_ascii=False, indent=1)

    print(f"captures: {ncap} files, {len(caps)} entries")
    print(f"body: {nbody} entries (회화집 본문 단어)")
    print(f"book: {nbook} files, {len(book)} entries, themes {len(themes)}")
    print(f"merged (dedup): {len(entries)}  → assets/data/vocab/th_vocab.json")
    print(f"root candidates: {len(cand_list)} (top: {[(c['th'], c['derived']) for c in cand_list[:15]]})")
    print(f"roots written: {len(roots)}")


if __name__ == "__main__":
    main()
