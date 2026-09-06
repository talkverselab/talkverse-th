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


READING_FIX = {  # 캡처 독음 누락분 보정
    "มี": {"reading": "미"}, "ไม่มี": {"reading": "마이 미"}, "ดี": {"reading": "디"},
    "สภาพร่างกาย": {"reading": "싸팝 랑까이"}, "ประเภทผิว": {"reading": "쁘라펫 피우"},
    "ปัญหาผิว": {"reading": "빤하 피우"},
}


def load_freq(known):
    """빈도 Top1000 — 단어장에 없는 단어는 top1000_meanings.json 의 뜻/독음으로 추가.
    반환: (entries, rank_by_th)"""
    ranks = {}
    entries = []
    path = os.path.join(ROOT, "assets", "data", "wordsets", "th_top1000.csv")
    meanings = {}
    mp = os.path.join(HERE, "top1000_meanings.json")
    if os.path.exists(mp):
        with open(mp, encoding="utf-8") as f:
            meanings = json.load(f)
    try:
        with open(path, encoding="utf-8") as f:
            next(f)
            for line in f:
                parts = line.rstrip("\r\n").split(",")
                if len(parts) < 2:
                    continue
                th = parts[1].strip()
                rank = int(parts[0]) if parts[0].isdigit() else 0
                if not th or not THAI.search(th):
                    continue
                ranks.setdefault(th, rank)
                if th in known:
                    continue
                m = meanings.get(th)
                if not m or not m.get("ko"):
                    continue
                if len(th) < 2 or "조각" in m["ko"]:
                    continue  # 단자음·음역 조각 등 토크나이저 부산물 제외
                entries.append(OrderedDict(
                    id=make_id("freq", th),
                    th=th,
                    reading=normalize_reading(m.get("reading", "")),
                    ko=m["ko"].strip(),
                    src="freq",
                    order=rank,
                ))
    except OSError:
        pass
    return entries, ranks


def freq_level(rank):
    """빈도 순위 → 1~5 단계 (1 = 최상위 100, 2 = ≤250, 3 = ≤500, 4 = ≤750, 5 = ≤1000)."""
    if not rank:
        return 0
    if rank <= 100:
        return 1
    if rank <= 250:
        return 2
    if rank <= 500:
        return 3
    if rank <= 750:
        return 4
    return 5


def merge_same_th(entries):
    """표제어(th) 완전 동일 항목 병합 — 뜻은 합치고(중복 제거), 독음은 첫 항목, day/theme 는 book 우선."""
    by = OrderedDict()
    for e in entries:
        key = e["th"]
        if key not in by:
            item = OrderedDict(e)
            item["kos"] = []
            by[key] = item
        item = by[key]
        for part in re.split(r"\s*[;/]\s*|\s*·\s*", e["ko"]):
            part = part.strip()
            if part and part not in item["kos"]:
                item["kos"].append(part)
        if not item.get("reading") and e.get("reading"):
            item["reading"] = e["reading"]
        if e.get("day") and not item.get("day"):
            item["day"] = e["day"]
            item["theme"] = e.get("theme", "")
            item["kind"] = e.get("kind", "")
        if e.get("uncertain") and item is not e:
            item["uncertain"] = True
    out = []
    for item in by.values():
        item["ko"] = ", ".join(item.pop("kos")[:4])
        for k in ("readingRaw", "pages", "num", "group", "ex", "src"):
            item.pop(k, None)
        out.append(item)
    return out


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
    known = set()
    for e in caps + body + book:
        for v in e["th"].split("/"):
            known.add(v.strip())
    freq, ranks = load_freq(known)
    # 우선순위: book(일차·테마 보존) > capture > body > freq. 표제어 동일 항목은 하나로 병합.
    entries = merge_same_th(book + caps + body + freq)
    mp = os.path.join(HERE, "top1000_meanings.json")
    fill = json.load(open(mp, encoding="utf-8")) if os.path.exists(mp) else {}
    fill.update(READING_FIX)
    entries = [e for e in entries if not re.search(r"\d{4}", e["th"])]  # 날짜 등 서식 행 제외
    for i, e in enumerate(entries):
        e["order"] = i
        if not e.get("reading") and e["th"] in fill:
            e["reading"] = normalize_reading(fill[e["th"]].get("reading", ""))
        rank = ranks.get(e["th"].split("/")[0].strip(), 0)
        if rank:
            e["rank"] = rank
            e["level"] = freq_level(rank)
    nfreq = len(freq)

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
                note="통합 단어장 — 표제어 기준 병합, level 은 빈도 1~5 단계(1=최상위), day/theme 는 30일 코스",
                counts=OrderedDict(capture=len(caps), body=len(body), book=len(book), freq=nfreq),
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
    print(f"freq: {nfreq} entries (Top1000 중 단어장에 없던 단어)")
    print(f"merged by th: {len(entries)}  → assets/data/vocab/th_vocab.json")
    print(f"root candidates: {len(cand_list)} (top: {[(c['th'], c['derived']) for c in cand_list[:15]]})")
    print(f"roots written: {len(roots)}")


if __name__ == "__main__":
    main()
