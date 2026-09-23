"""초급 스크립트 검사 — scripts_src_beginner.txt

검사: 머리줄 8칸 · 8턴 · 태국어 있음 · 독음에 로마자 없음 · 무대 8 × 욕구 4 = 32칸 전부 있음 ·
      02_BEGINNER_GRAMMAR.md 의 1군·2군 문법 요소가 태국어 본문에 얼마나 들어갔는지(스크립트별·전체).
출력: 화면 요약 + REVIEW_beginner.md (검수표: 대사 전체 + 문법 포함 표).
"""
import io
import os
import re
import sys

D = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(D, "scripts_src_beginner.txt")
STAGES = ["eat", "move", "home", "work", "trip", "night", "phone", "us"]
STAGE_KO = {"eat": "먹고 마시기", "move": "이동·거리", "home": "살림", "work": "일", "trip": "여행", "night": "밤", "phone": "폰 속", "us": "둘만의 시간"}
DRIVES = ["romance", "win", "status", "thrill"]
DRIVE_KO = {"romance": "설렘", "win": "승부", "status": "인정", "thrill": "일탈"}

# 1군 (거의 모든 교재) — 이름: 정규식(태국어 본문에서 찾음)
TIER1 = [
    ("ครับ/ค่ะ 어조사", r"ครับ|ค่ะ|คะ"),
    ("นะ", r"นะ"), ("สิ", r"สิ\b|สิ$|สิ "),
    ("ผม/ฉัน", r"ผม|ฉัน"), ("คุณ", r"คุณ"), ("พี่/น้อง", r"พี่|น้อง"), ("ชื่อ", r"ชื่อ"),
    ("เป็น 계사", r"เป็น"), ("คือ", r"คือ"), ("ไม่ใช่", r"ไม่ใช่"), ("ไม่ 부정", r"ไม่(?!ใช่|ได้|เอา|มี|เคย|ต้อง|ค่อย|เป็นไร|ทราบ)"),
    ("…ไหม", r"ไหม"), ("เหรอ/หรือ", r"เหรอ|หรือ(?!เปล่า|ยัง)"), ("ใช่ไหม", r"ใช่ไหม"), ("หรือเปล่า/เปล่า", r"หรือเปล่า|เปล่า"), ("หรือยัง", r"หรือยัง"),
    ("อะไร", r"อะไร"), ("ใคร", r"ใคร"), ("ที่ไหน/ไหน", r"ไหน"), ("เมื่อไหร่", r"เมื่อไหร่|เมื่อไร"), ("ทำไม", r"ทำไม"), ("ยังไง", r"ยังไง|อย่างไร"), ("เท่าไหร่", r"เท่าไหร่|เท่าไร"), ("กี่", r"กี่"),
    ("มี/ไม่มี", r"มี"), ("อยู่ 위치", r"อยู่"), ("ของ", r"ของ"),
    ("จะ 미래", r"จะ"), ("กำลัง…อยู่", r"กำลัง"), ("แล้ว 완료", r"แล้ว"), ("ยัง(ไม่)", r"ยัง"), ("เคย/ไม่เคย", r"เคย"), ("เพิ่ง", r"เพิ่ง"),
    ("อยาก", r"อยาก"), ("ต้อง/ไม่ต้อง", r"ต้อง"), ("ควร", r"ควร"), ("ได้ 가능", r"ได้"), ("ได้ไหม", r"ได้ไหม"),
    ("ขอ…", r"ขอ(?!บคุณ|โทษ)"), ("ช่วย…หน่อย", r"ช่วย"), ("หน่อย", r"หน่อย"), ("เอา/ไม่เอา", r"เอา"),
    ("อย่า", r"อย่า"), ("ห้าม", r"ห้าม"), ("กันไหม/กันเถอะ", r"กันไหม|กันเถอะ|เถอะ"), ("ลอง…ดู", r"ลอง"), ("ก็ได้", r"ก็ได้"),
    ("กว่า 비교", r"กว่า"), ("ที่สุด", r"ที่สุด"), ("เหมือน(กัน)", r"เหมือน"),
    ("มาก", r"มาก"), ("จัง", r"จัง"), ("นิดหน่อย", r"นิดหน่อย"), ("เกินไป/Adj+ไป", r"เกินไป|แพงไป|เยอะไป|เร็วไป|เล็กไป|ใหญ่ไป|ช้าไป"), ("ไม่ค่อย", r"ไม่ค่อย"), ("เลย 강조", r"เลย"),
    ("수사", r"หนึ่ง|สอง|สาม|สี่|ห้า|หก|เจ็ด|แปด|เก้า|สิบ|ร้อย|พัน"), ("분류사", r"(?:หนึ่ง|สอง|สาม|สี่|ห้า|หก|เจ็ด|แปด|เก้า|สิบ|ร้อย|กี่|เดียว)\s*(?:คน|อัน|แก้ว|ขวด|จาน|ชิ้น|ครั้ง|คืน|ตัว|คัน|เม็ด|กระป๋อง|วัน|ปี|เดือน|ชั่วโมง|นาที|จาน)|(?:คน|แก้ว|ขวด|จาน|ครั้ง|คืน|ห้อง)เดียว"), ("บาท", r"บาท"),
    ("시각", r"โมง|ทุ่ม|ตี(?:หนึ่ง|สอง|สาม|สี่|ห้า)|เที่ยง"), ("กี่โมง", r"กี่โมง"), ("ตอน+시간", r"ตอน"), ("วันนี้/พรุ่งนี้/เมื่อวาน", r"วันนี้|พรุ่งนี้|เมื่อวาน|คืนนี้"), ("요일", r"วันจันทร์|วันอังคาร|วันพุธ|วันพฤหัส|วันศุกร์|วันเสาร์|วันอาทิตย์"), ("ที่แล้ว/หน้า", r"ที่แล้ว|หน้า(?!ร้าน|คอนโด)|คราวหน้า|ครั้งหน้า"),
    ("ตั้งแต่…ถึง", r"ตั้งแต่|ถึง"), ("ก่อน/หลัง", r"ก่อน|หลัง"), ("ใช้เวลา", r"ใช้เวลา"), ("ประมาณ", r"ประมาณ"), ("V+มา+기간+แล้ว", r"มา(?:สอง|สาม|หนึ่ง|กี่|นาน)(?:ปี|วัน|เดือน)?"),
    ("และ", r"และ"), ("แต่", r"แต่(?!ก่อน)"), ("เพราะ", r"เพราะ"), ("ก็เลย/เลย 그래서", r"ก็เลย"), ("ถ้า", r"ถ้า"), ("งั้น", r"งั้น"), ("แล้วก็/แล้ว 순차", r"แล้วก็|แล้วค่อย"),
    ("ก็ ~도", r"ก็(?!ได้|เลย)"), ("กับ", r"กับ"), ("ที่ 관계사", r"(?:คน|ร้าน|ห้อง|ที่|ฝรั่ง|คนต่างชาติ)ที่"), ("ให้", r"ให้"), ("ว่า 보문", r"ว่า(?!ง)"), ("ไป/มา+V", r"ไป(?:กิน|ดู|หา|ดื่ม|ทำ|รับ|ส่ง|เที่ยว)|มา(?:หา|ส่ง|ทำ)"), ("น่า+V", r"น่า(?!ที)"), ("ชอบ", r"ชอบ"), ("ทุก", r"ทุก"), ("อีก", r"อีก"), ("แค่", r"แค่"),
]
TIER2 = [
    ("กำลังจะ", r"กำลังจะ"), ("คง/อาจจะ/น่าจะ", r"คง|อาจจะ|น่าจะ"), ("V+เป็น/ไหว", r"เป็นแล้ว|เป็นไหม|ไหว"), ("สามารถ", r"สามารถ"),
    ("บ่อย/เสมอ/ปกติ", r"บ่อย|เสมอ|ปกติ|บางครั้ง"), ("ขึ้น/ลง 변화", r"ดีขึ้น|แย่ลง|น้อยลง|มากขึ้น|แพงขึ้น|ถูกลง"), ("ถูก/โดน 수동", r"โดน|ถูก(?:ด่า|หลอก)"),
    ("ละ (~당)", r"(?:วัน|คืน|คน|อัน)ละ"), ("เอง", r"เอง"), ("…เดียว", r"เดียว"), ("ไม่ทราบว่า", r"ไม่ทราบว่า"), ("กรุณา", r"กรุณา"), ("ขอให้", r"ขอให้"), ("ยินดี", r"ยินดี"),
    ("ไว้", r"ไว้"), ("เสร็จ", r"เสร็จ"), ("ต่อ", r"ต่อ"), ("คนเดียว", r"คนเดียว"), ("ด้วยกัน", r"ด้วยกัน"), ("เหมือนกัน", r"เหมือนกัน"), ("หมด", r"หมด"), ("ผิด", r"ผิด"),
    ("ไม่เป็นไร", r"ไม่เป็นไร"), ("ขอโทษ", r"ขอโทษ"), ("ยินดีที่ได้รู้จัก", r"ยินดีที่ได้รู้จัก"), ("เลิกงาน", r"เลิกงาน"), ("ว่าง", r"ว่าง"), ("ใจ 합성어", r"ใจดี|ใจเย็น|เข้าใจ|แน่ใจ|ดีใจ"),
]

src = io.open(SRC, encoding="utf-8").read().split("\n")
scripts, cur, errs = [], None, []
for ln, line in enumerate(src, 1):
    if not line.strip() or (line.startswith("#") and not line.startswith("###")):
        continue
    if line.startswith("###"):
        p = [x.strip() for x in line[3:].split("|")]
        if len(p) != 8:
            errs.append("%d: 머리줄 칸 수 %d" % (ln, len(p)))
            cur = None
            continue
        key = p[0]
        try:
            stage, drive, slug = key.split(".")
        except ValueError:
            errs.append("%d: 키 형식 오류 %s" % (ln, key))
            cur = None
            continue
        if stage not in STAGES:
            errs.append("%d: 모르는 무대 %s" % (ln, stage))
        if drive not in DRIVES:
            errs.append("%d: 모르는 욕구 %s" % (ln, drive))
        tags = dict(t.split(":", 1) for t in p[7].split("=", 1)[1].split(",") if t)
        if tags.get("level") != "beg":
            errs.append("%d: tags 에 level:beg 없음" % ln)
        cur = {"key": key, "stage": stage, "drive": drive, "heat": int(p[1]), "emoji": p[2], "title": p[3],
               "A": p[4].split("=", 1)[1], "B": p[5].split("=", 1)[1], "flags": p[6].split("=", 1)[1], "tags": tags,
               "hook": "", "turns": [], "line": ln}
        scripts.append(cur)
    elif line.startswith(">"):
        if cur:
            cur["hook"] = line[1:].strip()
    else:
        if cur is None:
            errs.append("%d: 머리줄 없는 턴" % ln)
            continue
        p = line.split("|")
        if len(p) != 5 or p[0] not in ("A", "B"):
            errs.append("%d: 턴 형식 오류 (%d칸)" % (ln, len(p)))
            continue
        sp, th, roman, ko, note = [x.strip() for x in p]
        if not re.search("[฀-๿]", th):
            errs.append("%d: 태국어 없음" % ln)
        if re.search("[A-Za-z]", roman):
            errs.append("%d: 독음에 로마자 — %s" % (ln, roman[:30]))
        if not note.startswith("문법:"):
            errs.append("%d: 노트에 '문법:' 없음" % ln)
        syl = len(re.findall(r"[가-힣]", roman))
        cur["turns"].append({"sp": sp, "th": th, "roman": roman, "ko": ko, "note": note, "syl": syl})

for s in scripts:
    if len(s["turns"]) != 8:
        errs.append("%s: 턴 %d개" % (s["key"], len(s["turns"])))
    if not s["hook"]:
        errs.append("%s: 미끼(>) 없음" % s["key"])
cells = {(s["stage"], s["drive"]) for s in scripts}
for st in STAGES:
    for dr in DRIVES:
        if (st, dr) not in cells:
            errs.append("칸 비어 있음: %s.%s" % (st, dr))
keys = [s["key"] for s in scripts]
for k in set(keys):
    if keys.count(k) > 1:
        errs.append("키 중복: " + k)

def hits(text, table):
    return [name for name, rx in table if re.search(rx, text)]

all_th = "\n".join(t["th"] for s in scripts for t in s["turns"])
t1_all = hits(all_th, TIER1)
t2_all = hits(all_th, TIER2)
t1_missing = [n for n, _ in TIER1 if n not in t1_all]
t2_missing = [n for n, _ in TIER2 if n not in t2_all]

# 요소별 등장 스크립트 수
freq1 = {n: sum(1 for s in scripts if re.search(rx, "\n".join(t["th"] for t in s["turns"]))) for n, rx in TIER1}
freq2 = {n: sum(1 for s in scripts if re.search(rx, "\n".join(t["th"] for t in s["turns"]))) for n, rx in TIER2}

print("스크립트 %d편 · 턴 %d · 오류 %d" % (len(scripts), sum(len(s["turns"]) for s in scripts), len(errs)))
for e in errs:
    print("  !", e)
print("1군 %d/%d 포함 · 빠진 것: %s" % (len(t1_all), len(TIER1), ", ".join(t1_missing) or "없음"))
print("2군 %d/%d 포함 · 빠진 것: %s" % (len(t2_all), len(TIER2), ", ".join(t2_missing) or "없음"))
syls = [t["syl"] for s in scripts for t in s["turns"]]
print("턴 길이(독음 음절): 평균 %.1f · 최대 %d · 20음절 넘는 턴 %d" % (sum(syls) / len(syls), max(syls), sum(1 for x in syls if x > 20)))
per = sorted(((len(hits("\n".join(t["th"] for t in s["turns"]), TIER1)), s["key"]) for s in scripts))
print("스크립트별 1군 요소 수: 최소 %d (%s) · 최대 %d (%s)" % (per[0][0], per[0][1], per[-1][0], per[-1][1]))

# REVIEW_beginner.md
md = ["# 초급 스크립트 검수표 (자동 생성 — `python check_beginner.py`)", "",
      "%d편 · 각 8턴 · 무대 8 × 욕구 4. 전부 자체 제작 초안, 원어민 검수 전. 문법 기준: `02_BEGINNER_GRAMMAR.md`." % len(scripts), "",
      "## 문법 포함도", "",
      "1군 %d/%d — 빠진 것: %s" % (len(t1_all), len(TIER1), ", ".join(t1_missing) or "없음"), "",
      "2군 %d/%d — 빠진 것: %s" % (len(t2_all), len(TIER2), ", ".join(t2_missing) or "없음"), "",
      "| 1군 요소 | 등장 편수 |", "|---|---|"]
for n, _ in TIER1:
    md.append("| %s | %d |" % (n, freq1[n]))
md += ["", "| 2군 요소 | 등장 편수 |", "|---|---|"]
for n, _ in TIER2:
    md.append("| %s | %d |" % (n, freq2[n]))
md += ["", "## 스크립트", ""]
for st in STAGES:
    for dr in DRIVES:
        for s in scripts:
            if s["stage"] != st or s["drive"] != dr:
                continue
            h1 = hits("\n".join(t["th"] for t in s["turns"]), TIER1)
            md.append("### %s %s — %s · %s  %s" % (s["emoji"], s["title"], STAGE_KO[st], DRIVE_KO[dr], "🌶" * s["heat"]))
            md.append("`%s` · A=%s · B=%s · flags=%s · 1군 요소 %d개" % (s["key"], s["A"], s["B"], s["flags"] or "-", len(h1)))
            md.append("")
            md.append("> " + s["hook"])
            md.append("")
            md.append("| | 태국어 | 독음 | 뜻 | 문법 |")
            md.append("|---|---|---|---|---|")
            for t in s["turns"]:
                md.append("| %s | %s | %s | %s | %s |" % (t["sp"], t["th"], t["roman"], t["ko"], t["note"][3:].strip()))
            md.append("")
            md.append("- [ ] 태국어 자연스러움  - [ ] 독음  - [ ] 문법 표기  - [ ] 통과")
            md.append("")
io.open(os.path.join(D, "REVIEW_beginner.md"), "w", encoding="utf-8").write("\n".join(md))
print("→ REVIEW_beginner.md")
sys.exit(1 if errs else 0)
