r"""회화집 본문 전사 MD(pages/*.md) → phrasebook_parsed.json (로컬 전용; build_vocab.py 가 단어 표만 사용)

사용: python -X utf8 tools/vocab_pipeline/build_phrasebook.py
- `## 제목`      → topic (페이지 단위 주제)
- `### 라벨`     → 문장 그룹(kind=phrase)
- `#### 라벨`    → 단어 그룹(kind=word), 단 '한마디 표현' 은 kind=phrase
- 표 행         → rows {ko, th, reading, en, reply, ref, template}
- `> **제목**: 본문` → notes, 이탤릭/평문 → captions
섹션(탭)은 SECTION_STARTS 의 시작 쪽수로 배정.
"""
import glob
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, "phrasebook_parsed.json")  # 원서 문장 전사 — 앱 에셋에 넣지 않음(로컬 전용)

# (id, 이름, 이모지, 시작 쪽) — 책의 오른쪽 탭 순서. 시작 쪽은 전사 결과의 구분 페이지 기준.
SECTION_STARTS = [
    ("basic", "기본회화", "🙏", 12),
    ("food", "맛집", "🍜", 24),
    ("shop", "쇼핑", "🛍️", 50),
    ("beauty", "뷰티", "💆", 78),
    ("tour", "관광", "🏛️", 88),
    ("enter", "엔터테인먼트", "🎭", 102),
    ("hotel", "호텔", "🏨", 110),
    ("transport", "교통수단", "🚕", 118),
    ("info", "기본정보", "ℹ️", 132),
]

THAI = re.compile(r"[฀-๿]")


def section_for(page):
    cur = SECTION_STARTS[0][0]
    for sid, _, _, start in SECTION_STARTS:
        if page >= start:
            cur = sid
    return cur


def split_row(line):
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|"):
        body = body[:-1]
    cells = re.split(r"(?<!\\)\|", body)
    return [c.replace("\\|", "|").strip() for c in cells]


def col_index(header):
    idx = {}
    for i, h in enumerate(header):
        h = h.strip()
        if h.startswith("한국어") or h in ("뜻", "한글"):
            idx.setdefault("ko", i)
        elif h.startswith("태국어"):
            idx.setdefault("th", i)
        elif h.startswith("독음") or h.startswith("발음"):
            idx.setdefault("reading", i)
        elif h.startswith("영어") or h.lower().startswith("english"):
            idx.setdefault("en", i)
    return idx


def new_topic(title, page):
    return {"title": title, "page": page, "intro": [], "groups": [], "notes": [], "captions": []}


def parse_file(path):
    lines = io.open(path, encoding="utf-8").read().splitlines()
    topics = []
    state = {"topic": None, "page": 0}
    sub = ""
    box = ""
    i = 0

    def ensure_topic():
        if state["topic"] is None:
            state["topic"] = new_topic("", state["page"])
            topics.append(state["topic"])
        return state["topic"]

    def group_for(kind, label):
        t = ensure_topic()
        page = state["page"]
        if t["groups"]:
            last = t["groups"][-1]
            if last["label"] == label and last["kind"] == kind and last["page"] == page:
                return last
        g = {"label": label, "kind": kind, "page": page, "rows": []}
        t["groups"].append(g)
        return g

    while i < len(lines):
        line = lines[i].rstrip()
        m = re.match(r"<!-- PAGE\s*(\d+)", line)
        if m:
            state["page"] = int(m.group(1))
            i += 1
            continue
        if line.startswith("## "):
            state["topic"] = new_topic(line[3:].strip(), state["page"])
            topics.append(state["topic"])
            sub = box = ""
            i += 1
            continue
        if line.startswith("### "):
            sub = line[4:].strip()
            box = ""
            i += 1
            continue
        if line.startswith("#### "):
            box = line[5:].strip()
            i += 1
            continue
        if line.startswith("|"):
            header = split_row(line)
            idx = col_index(header)
            j = i + 1
            if j < len(lines) and re.match(r"^\|[\s|:-]+\|$", lines[j].strip()):
                j += 1
            rows = []
            while j < len(lines) and lines[j].strip().startswith("|"):
                rows.append(split_row(lines[j]))
                j += 1
            i = j
            if "th" not in idx:
                ensure_topic()["captions"].append("[표] " + " / ".join(header))
                continue
            if box:
                kind = "phrase" if "한마디" in box else "word"
                label = box
            else:
                kind = "phrase"
                label = sub
            g = group_for(kind, label)
            for r in rows:
                def cell(k):
                    p = idx.get(k)
                    return r[p].strip() if p is not None and p < len(r) else ""
                ko, th, rd, en = cell("ko"), cell("th"), cell("reading"), cell("en")
                if not THAI.search(th):
                    continue
                reply = ko.startswith("↳")
                ko = ko.lstrip("↳").strip()
                ref = ""
                mref = re.search(r"\(참고\s*([^)]*)\)", ko)
                if mref:
                    ref = mref.group(1).strip()
                    ko = (ko[:mref.start()] + ko[mref.end():]).strip()
                row = {"ko": ko, "th": th, "reading": rd, "en": en}
                if reply:
                    row["reply"] = True
                if ref:
                    row["ref"] = ref
                if "__" in th or "～" in th:
                    row["template"] = True
                if "(?)" in ko or "(?)" in th or "(?)" in rd:
                    row["uncertain"] = True
                g["rows"].append(row)
            continue
        if line.startswith(">"):
            body = line.lstrip("> ").strip()
            mt = re.match(r"\*\*(.+?)\*\*:?\s*(.*)", body)
            title, text = (mt.group(1), mt.group(2)) if mt else ("", body)
            j = i + 1
            while j < len(lines) and lines[j].strip().startswith(">"):
                text += " " + lines[j].strip().lstrip("> ").strip()
                j += 1
            i = j
            ensure_topic()["notes"].append({"title": title.strip(), "body": text.strip(), "page": state["page"]})
            continue
        if line.strip():
            t = ensure_topic()
            txt = line.strip()
            if txt.startswith("*") and txt.endswith("*"):
                t["captions"].append(txt.strip("*").strip())
            elif not t["groups"] and not t["notes"] and not t["captions"]:
                t["intro"].append(txt)
            else:
                t["captions"].append(txt)
        i += 1
    return topics


def main():
    topics = []
    files = sorted(glob.glob(os.path.join(HERE, "pages", "*.md")))
    for f in files:
        topics.extend(parse_file(f))
    out = []
    n_rows = n_words = n_phr = 0
    for k, t in enumerate(topics):
        t["groups"] = [g for g in t["groups"] if g["rows"]]
        if not t["groups"] and not t["notes"] and not t["captions"]:
            continue
        t["intro"] = " ".join(t["intro"]).strip()
        t["section"] = section_for(t["page"])
        t["id"] = f"p{t['page']:03d}_{k}"
        for g in t["groups"]:
            n_rows += len(g["rows"])
            if g["kind"] == "word":
                n_words += len(g["rows"])
            else:
                n_phr += len(g["rows"])
        out.append(t)
    data = {
        "meta": {
            "title": "태국어 여행회화집",
            "note": "Desktop/태국어단어 스마트폰 캡처 71장(12~153쪽) 비전 전사 → tools/vocab_pipeline/build_phrasebook.py",
            "sections": [{"id": s, "name": n, "emoji": e, "from": p} for s, n, e, p in SECTION_STARTS],
            "pageFiles": [os.path.basename(f) for f in files],
        },
        "topics": out,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with io.open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    per = {}
    for t in out:
        per[t["section"]] = per.get(t["section"], 0) + 1
    print(f"pages {len(files)} → topics {len(out)}, rows {n_rows} (문장 {n_phr} / 단어 {n_words})")
    print("  섹션별 주제:", per)
    print(f"→ {OUT} ({os.path.getsize(OUT):,} bytes)")


def body_words():
    """build_vocab.py 용: 본문 단어 그룹의 행을 단어장 항목으로 반환."""
    rows = []
    if not os.path.exists(OUT):
        return rows
    data = json.load(io.open(OUT, encoding="utf-8"))
    for t in data["topics"]:
        for g in t["groups"]:
            if g["kind"] != "word":
                continue
            for r in g["rows"]:
                if r.get("template"):
                    continue
                rows.append({"ko": r["ko"], "th": r["th"], "reading": r.get("reading", ""),
                             "page": g["page"], "group": g["label"], "topic": t["title"], "section": t.get("section", ""),
                             "uncertain": r.get("uncertain", False)})
    return rows


if __name__ == "__main__":
    main()
