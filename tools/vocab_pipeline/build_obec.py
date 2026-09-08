r"""태국 교육부(OBEC) 기초 단어 목록(บัญชีคำพื้นฐาน ป.1~ป.6) → 앱 DB 에셋.

사용: python -X utf8 tools/vocab_pipeline/build_obec.py
입력: tools/vocab_pipeline/obec/obec_basic_words.json  (학년별 단어, .doc 에서 추출)
      tools/vocab_pipeline/obec/meanings_*.json       (1~3학년 중 단어장에 없던 단어의 뜻·독음)
      assets/data/vocab/th_vocab.json                 (이미 있는 단어의 뜻·독음·빈도)
출력: assets/data/wordsets/th_obec_basic.json
  {"meta": {...},
   "standard": [ {"th","grade":1|2|3,"reading","ko","inVocab":bool,"rank":int|0,"level":int|0}, ... ]   # 1~3학년 = 표준 2,600여 개
   "upper": {"4": [...단어...], "5": [...], "6": [...]}                                                   # 4~6학년은 단어만
앱 화면에는 아직 연결하지 않음(DB 보관용).
"""
import glob
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
from build_vocab import normalize_reading  # noqa: E402

OUT = os.path.join(ROOT, "assets", "data", "wordsets", "th_obec_basic.json")


def main():
    words = json.load(io.open(os.path.join(HERE, "obec", "obec_basic_words.json"), encoding="utf-8"))
    vocab = json.load(io.open(os.path.join(ROOT, "assets/data/vocab/th_vocab.json"), encoding="utf-8"))["entries"]
    by_th = {}
    for e in vocab:
        for v in e["th"].split("/"):
            by_th.setdefault(v.strip(), e)
    meanings = {}
    for f in sorted(glob.glob(os.path.join(HERE, "obec", "meanings_*.json"))):
        meanings.update(json.load(io.open(f, encoding="utf-8")))

    standard = []
    seen = set()
    by_base = {}
    n_missing = 0
    for g in ("1", "2", "3"):
        for th in words[g]:
            if th in seen:
                continue
            seen.add(th)
            base = re.sub(r"\s*\([^)]*\)\s*$", "", th).strip()  # "ขา (น)" → ขา
            e = by_th.get(th) or by_th.get(base)
            m = meanings.get(th) or meanings.get(base)
            if e is not None:
                item = dict(th=base, grade=int(g), reading=e.get("reading", ""), ko=e.get("ko", ""),
                            inVocab=True, rank=e.get("rank", 0), level=e.get("level", 0))
            elif m:
                item = dict(th=base, grade=int(g), reading=normalize_reading(m.get("reading", "")),
                            ko=m.get("ko", "").strip(), inVocab=False, rank=0, level=0)
            else:
                n_missing += 1
                item = dict(th=base, grade=int(g), reading="", ko="", inVocab=False, rank=0, level=0)
            if th != base:
                item["hint"] = th[len(base):].strip()
            dup = by_base.get(base)
            if dup is not None:  # 괄호 힌트만 다른 같은 표제어 → 뜻 합치기
                for part in item["ko"].split(", "):
                    if part and part not in dup["ko"]:
                        dup["ko"] = (dup["ko"] + ", " + part).strip(", ")
                continue
            by_base[base] = item
            standard.append(item)
    upper = {g: words[g] for g in ("4", "5", "6")}
    doc = dict(
        meta=dict(
            title="태국 교육부(OBEC) 기초 단어 목록 — ป.1~ป.3 표준 단어",
            note="สำนักวิชาการและมาตรฐานการศึกษา สพฐ. 「บัญชีคำพื้นฐานที่ใช้ในการเรียนการสอนภาษาไทย」 초등 1~6학년. "
                 "standard = 1~3학년(외국인용 TCT 2~3급 수준), upper = 4~6학년 단어만. 아직 앱 화면에는 연결하지 않음.",
            counts=dict(standard=len(standard), g1=len(words["1"]), g2=len(words["2"]), g3=len(words["3"]),
                        g4=len(words["4"]), g5=len(words["5"]), g6=len(words["6"]),
                        inVocab=sum(1 for x in standard if x["inVocab"]), noMeaning=n_missing),
        ),
        standard=standard,
        upper=upper,
    )
    io.open(OUT, "w", encoding="utf-8", newline="\n").write(json.dumps(doc, ensure_ascii=False, indent=0))
    print(f"standard {len(standard)} (inVocab {doc['meta']['counts']['inVocab']}, noMeaning {n_missing}) "
          f"upper {sum(len(v) for v in upper.values())} → {OUT} ({os.path.getsize(OUT):,} bytes)")


if __name__ == "__main__":
    main()
