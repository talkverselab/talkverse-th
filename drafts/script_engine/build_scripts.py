"""scripts_src.txt → scripts_th.json(앱용) + REVIEW.md(검수표).

검사: 도메인 6 × 욕구 4 = 24개 1편이 전부 있는지, 회차 번호가 1부터 빠짐없이 이어지는지,
각 8턴인지, 독음에 로마자가 섞였는지, 태국어 칸이 비었는지.
"""
import io
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from variants import make_variants  # noqa: E402

D = os.path.dirname(os.path.abspath(__file__))
DOMAINS = ["biz", "travel", "stay", "fan", "night", "chat"]
DRIVES = ["romance", "win", "status", "thrill"]
DOMAIN_KO = {"biz": "비즈니스", "travel": "여행", "stay": "살아 보기", "fan": "드라마·팬", "night": "밤", "chat": "채팅"}
DRIVE_KO = {"romance": "설렘", "win": "승부", "status": "인정", "thrill": "일탈"}

src = io.open(os.path.join(D, "scripts_src.txt"), encoding="utf-8").read().split("\n")
scripts, cur, errs = [], None, []
for ln, line in enumerate(src, 1):
    if not line.strip() or (line.startswith("#") and not line.startswith("###")):
        continue
    if line.startswith("###"):
        p = [x.strip() for x in line[3:].split("|")]
        if len(p) != 8:
            errs.append("%d: 머리줄 칸 수 %d" % (ln, len(p)))
            continue
        key, _, ep = p[0].partition("#")
        dom, drv, slug = key.split(".")
        ep = int(ep or 1)
        cur = {
            "id": "%s#%d" % (key, ep), "key": key, "ep": ep, "domain": dom, "drive": drv,
            "heat": int(p[1]), "emoji": p[2], "title": p[3],
            "characters": {"A": p[4].split("=", 1)[1], "B": p[5].split("=", 1)[1]},
            "flags": [f for f in p[6].split("=", 1)[1].split(",") if f],
            "tags": dict(t.split(":", 1) for t in p[7].split("=", 1)[1].split(",") if t),
            "recap": "", "hook": "", "prev": None, "next": None,
            "review": {"status": "draft", "reviewer": None}, "turns": [],
        }
        scripts.append(cur)
    elif line.startswith("<"):
        cur["recap"] = line[1:].strip()
    elif line.startswith(">"):
        cur["hook"] = line[1:].strip()
    else:
        p = line.split("|")
        if len(p) != 5 or p[0] not in ("A", "B"):
            errs.append("%d: 턴 형식 오류 (%d칸)" % (ln, len(p)))
            continue
        sp, th, roman, ko, note = [x.strip() for x in p]
        if not re.search("[฀-๿]", th):
            errs.append("%d: 태국어 없음" % ln)
        if re.search("[A-Za-z]", roman):
            errs.append("%d: 독음에 로마자 — %s" % (ln, roman[:30]))
        t = {"num": len(cur["turns"]) + 1, "speaker": sp, "th": th, "roman": roman, "ko": ko}
        if note:
            t["note"] = note
        cur["turns"].append(t)

# 시리즈: 같은 key 의 회차를 1,2,3… 으로 잇는다
series = {}
for s in scripts:
    series.setdefault(s["key"], []).append(s)
cell = {}
for key, eps in series.items():
    cell.setdefault(key.rsplit(".", 1)[0], []).append(key)
for d in DOMAINS:
    for r in DRIVES:
        if "%s.%s" % (d, r) not in cell:
            errs.append("빠진 조합: %s.%s" % (d, r))
TAGS = {"stage": {"first", "talking", "couple", "ex"}, "style": {"direct", "indirect", "joke", "listener"},
        "persona": {"sweet", "tsundere", "playful", "mature"}, "conflict": {"confront", "laugh", "polite", "escape"},
        "reg": {"polite", "casual"}}
for s in scripts:
    for k, v in s["tags"].items():
        if k not in TAGS or v not in TAGS[k]:
            errs.append("%s: 모르는 태그 %s:%s" % (s["id"], k, v))
    if "reg" not in s["tags"] or "style" not in s["tags"]:
        errs.append("%s: reg·style 태그는 필수" % s["id"])
for key, eps in series.items():
    eps.sort(key=lambda s: s["ep"])
    if [s["ep"] for s in eps] != list(range(1, len(eps) + 1)):
        errs.append("%s: 회차 번호가 1부터 이어지지 않음 %s" % (key, [s["ep"] for s in eps]))
    for a, b in zip(eps, eps[1:]):
        a["next"], b["prev"] = b["id"], a["id"]
        if not b["recap"]:
            errs.append("%s: '지난 이야기'(< 줄) 없음" % b["id"])
    for s in eps:
        s["series_len"] = len(eps)
for s in scripts:
    if len(s["turns"]) != 8:
        errs.append("%s: %d턴" % (s["id"], len(s["turns"])))
if errs:
    print("\n".join(errs))
    sys.exit(1)

scripts.sort(key=lambda s: (DOMAINS.index(s["domain"]), DRIVES.index(s["drive"]), s["key"], s["ep"]))
base_scripts = scripts
warn = []
cfg = json.load(io.open(os.path.join(D, "variants.json"), encoding="utf-8"))
scripts = make_variants(base_scripts, cfg, warn)
json.dump({"meta": {"version": "draft-4", "lang": "th", "turns_per_script": 8,
                    "lookup": "질문 답으로 전체에 점수를 매겨 재생 목록을 만든다(select_playlist.py). 앞 회차를 끝내야 next 가 열린다.",
                    "variants": "id 끝의 @판: 연애 상대가 나오는 스크립트 = mf·fm·mm·ff(나·상대), 그 밖 = m·f(나). voices = 화자별 음성 성별.",
                    "note": "roman = 한글 근사 독음. 전부 자체 제작, 사람 검수 전(review.status=draft)."},
           "scripts": scripts},
          io.open(os.path.join(D, "scripts_th.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

md = ["# 스크립트 검수표 (자동 생성 — 고칠 때는 scripts_src.txt 를 고친다)\n",
      "괄호 안 숫자 = 이어지는 회차 수\n",
      "| | " + " | ".join(DRIVE_KO[r] for r in DRIVES) + " |", "|---|" + "---|" * len(DRIVES)]
for d in DOMAINS:
    cells = []
    for r in DRIVES:
        items = []
        for key in sorted(cell["%s.%s" % (d, r)]):
            eps = series[key]
            items.append("%s%s" % (eps[0]["title"], (" (%d)" % len(eps)) if len(eps) > 1 else ""))
        cells.append("<br>".join(items))
    md.append("| **%s** | " % DOMAIN_KO[d] + " | ".join(cells) + " |")
md.append("")
md.append("### 태그 분포 (질문 답마다 걸리는 스크립트 수)")
md.append("")
for k in ("stage", "style", "persona", "conflict", "reg"):
    cnt = {}
    for s_ in base_scripts:
        v = s_["tags"].get(k)
        if v:
            cnt[v] = cnt.get(v, 0) + 1
    md.append("- **%s**: " % k + " · ".join("%s %d" % (v, cnt.get(v, 0)) for v in sorted(TAGS[k])))
md.append("")
for s in base_scripts:
    ep = (" · %d편/%d" % (s["ep"], s["series_len"])) if s["series_len"] > 1 else ""
    md.append("## %s %s — %s · %s%s  %s" % (s["emoji"], s["title"], DOMAIN_KO[s["domain"]], DRIVE_KO[s["drive"]], ep, "🌶" * s["heat"]))
    md.append("`%s` · A = %s · B = %s%s · 태그: %s  " % (s["id"], s["characters"]["A"], s["characters"]["B"],
                                              (" · 표시: " + ", ".join(s["flags"])) if s["flags"] else "",
                                              ", ".join("%s:%s" % kv for kv in s["tags"].items())))
    if s["recap"]:
        md.append("지난 이야기: " + s["recap"] + "  ")
    md.append("> " + s["hook"] + "\n")
    md.append("| # | 화자 | 태국어 | 독음 | 한국어 | 노트 |")
    md.append("|---|---|---|---|---|---|")
    for t in s["turns"]:
        md.append("| %d | %s | %s | %s | %s | %s |" % (t["num"], t["speaker"], t["th"], t["roman"], t["ko"], t.get("note", "")))
    md.append("\n검수: ☐ 태국어 자연스러움 ☐ 독음 ☐ 수위 ☐ 통과\n")
io.open(os.path.join(D, "REVIEW.md"), "w", encoding="utf-8", newline="\n").write("\n".join(md))


# 성별판 검수표 — 기본판과 달라진 줄만
vm = ["# 성별판 검수표 (자동 생성) — 기본판(남자 학습자 × 여자 상대)과 **달라진 줄만** 보여 준다", "",
      "규칙 치환(ผม↔ฉัน·หนู, ครับ↔ค่ะ·คะ, 이름) + variants.json overrides 결과다. 어미 ค่ะ/คะ 선택과 1인칭을 특히 볼 것.", ""]
if warn:
    vm += ["## 생성기 경고", ""] + ["- " + w for w in warn] + [""]
LABEL = {"f": "여자 학습자", "fm": "여자 학습자 × 남자 상대", "mm": "남자 학습자 × 남자 상대", "ff": "여자 학습자 × 여자 상대"}
for s in scripts:
    if s["variant"] in ("m", "mf"):
        continue
    vm.append("## %s — %s" % (s["title"], LABEL[s["variant"]]))
    vm.append("`%s` · A = %s · B = %s · 음성 A:%s B:%s" % (
        s["id"], s["characters"]["A"], s["characters"]["B"], s["voices"]["A"], s["voices"]["B"]))
    vm.append("")
    if not s["changed"]:
        vm += ["(달라진 줄 없음)", ""]
        continue
    vm.append("| # | 화자 | 태국어 | 독음 | 한국어 |")
    vm.append("|---|---|---|---|---|")
    for t in s["turns"]:
        if t["num"] in s["changed"]:
            vm.append("| %d | %s | %s | %s | %s |" % (t["num"], t["speaker"], t["th"], t["roman"], t["ko"]))
    vm.append("")
io.open(os.path.join(D, "REVIEW_variants.md"), "w", encoding="utf-8", newline="\n").write("\n".join(vm))

print("기본판 %d개(1편 %d + 이어지는 회차 %d) · %d턴 · 표현 노트 %d개 · heat3 %d개" % (
    len(base_scripts), len(series), len(base_scripts) - len(series), sum(len(s["turns"]) for s in base_scripts),
    sum(1 for s in base_scripts for t in s["turns"] if "note" in t), sum(1 for s in base_scripts if s["heat"] == 3)))
print("성별판 포함 %d개 · 생성기 경고 %d건" % (len(scripts), len(warn)))
