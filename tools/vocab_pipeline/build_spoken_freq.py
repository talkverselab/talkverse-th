r"""구어(드라마 자막) 코퍼스 통계로 빈도 Top1000 재생성 → assets/data/wordsets/th_top1000.csv

사용: python -X utf8 tools/vocab_pipeline/build_spoken_freq.py
입력: corpus/analysis_th/_pairs_clean.jsonl (로컬 전용, 리포 미포함) — 문장은 쓰지 않고 단어 빈도만 집계
필터: 태국 문자만 · pythainlp 사전(또는 앱 단어장·영어유래)에 있는 단어만(이름·오분절 제거) · 비속어 제외
출력 열: rank,word,freq,tier,domain  (tier R1 ≤250 / R2 ≤500 / R3 ≤750 / R4 ≤1000, domain=spoken)
"""
import io
import json
import os
import re
import sys
from collections import Counter

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(ROOT, "corpus", "analysis_th", "_pairs_clean.jsonl")
OUT = os.path.join(ROOT, "assets", "data", "wordsets", "th_top1000.csv")

VULGAR = set("กู มึง ไอ้ อี เหี้ย สัส สัตว์ ควย เย็ด แม่ง ห่า ชิบหาย ระยำ เชี่ย เฮงซวย บ้า ตาย โง่ หน้าด้าน "
             "ดอกทอง กะหรี่ ส้นตีน ตีน สถุน ชาติหมา หมา".split())
SKIP = set("ๆ ฯ ฯลฯ".split())


def main():
    from pythainlp.tokenize import word_tokenize
    from pythainlp.corpus import thai_words
    dictionary = set(thai_words())
    vocab = json.load(io.open(os.path.join(ROOT, "assets/data/vocab/th_vocab.json"), encoding="utf-8"))["entries"]
    known = set()
    for e in vocab:
        for v in e["th"].split("/"):
            known.add(v.strip())
    lw = os.path.join(ROOT, "assets/data/wordsets/th_loanwords.json")
    if os.path.exists(lw):
        for w in json.load(io.open(lw, encoding="utf-8"))["words"]:
            known.add(w["th"].strip())
    pairs = json.load(io.open(SRC, encoding="utf-8"))
    cnt = Counter()
    for p in pairs:
        for w in word_tokenize(p["src"], engine="newmm", keep_whitespace=False):
            w = w.strip()
            if not re.fullmatch(r"[ก-๙]+", w) or w in SKIP or w in VULGAR:
                continue
            if len(w) == 1 and w not in known:
                continue
            if w not in dictionary and w not in known:
                continue
            cnt[w] += 1
    top = cnt.most_common(1000)
    with io.open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("rank,word,freq,tier,domain\n")
        for i, (w, c) in enumerate(top, 1):
            tier = "R1" if i <= 250 else "R2" if i <= 500 else "R3" if i <= 750 else "R4"
            f.write(f"{i},{w},{c},{tier},spoken\n")
    total = sum(cnt.values())
    print(f"sentences {len(pairs):,}  tokens {total:,}  types {len(cnt):,}  → {OUT}")
    print("top30:", " ".join(w for w, _ in top[:30]))
    cover = [sum(c for _, c in top[:n]) / total * 100 for n in (100, 250, 500, 750, 1000)]
    print("누적 비중 100/250/500/750/1000:", " ".join(f"{c:.1f}%" for c in cover))
    missing = [w for w, _ in top if w not in known]
    print(f"단어장에 뜻 없는 신규 {len(missing)}개:", " ".join(missing[:40]))
    json.dump([{"rank": i + 1, "th": w} for i, (w, _) in enumerate(top) if w not in known],
              io.open(os.path.join(HERE, "spoken_missing.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=0)


if __name__ == "__main__":
    main()
