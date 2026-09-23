"""성별판 생성기 — 기본판(남자 학습자 × 여자 상대)에서 규칙으로 나머지 판을 만든다.

판 이름
  상대역이 연애 상대인 스크립트(partner):  mf(기본) · fm · mm · ff   ← 앞 글자 = 나, 뒤 글자 = 상대
  그 밖(상대 성별이 고정된 스크립트):       m(기본) · f

규칙으로 바꾸는 것: 호칭(ผม↔ฉัน/หนู) · 어미(ครับ↔ค่ะ/คะ) · 독음(폼·크랍↔찬·카) · 이름 · 한국어의 성별 낱말.
규칙으로 안 되는 줄은 variants.json 의 overrides 로 덮어쓴다. 생성 결과는 전부 사람 검수 대상이다.
"""
import copy
import re

Q_WORDS = ("ไหม", "เหรอ", "หรือเปล่า", "หรือยัง", "อะไร", "ใคร", "ไหน", "ยังไง", "ทำไม", "กี่", "เท่าไหร่", "ล่ะ", "หรือ")
TOKEN = re.compile(r"[^\s,.!?…\"“”()]+")


def _female_particles(th):
    """ครับ → ค่ะ / คะ. 그 절에 의문어가 있거나 นะ·สิ 바로 뒤면 คะ."""
    out, last = [], 0
    for m in re.finditer("ครับ", th):
        clause = th[last:m.start()]
        tail = clause.rstrip()
        q = tail.endswith(("นะ", "สิ")) or any(w in clause for w in Q_WORDS)
        out.append(clause + ("คะ" if q else "ค่ะ"))
        last = m.end()
    out.append(th[last:])
    return "".join(out)


def _swap_tokens(roman, mapping):
    return TOKEN.sub(lambda m: mapping.get(m.group(0), m.group(0)), roman)


def learner_to_female(t, i_th, i_ro, warn):
    t["th"] = _female_particles(t["th"]).replace("ผม", i_th)
    t["roman"] = _swap_tokens(t["roman"], {"크랍": "카", "폼": i_ro})


def partner_to_male(t, warn, sid):
    th = t["th"]
    n_part = len(re.findall("ค่ะ|คะ", th))
    n_ka = sum(1 for x in TOKEN.findall(t["roman"]) if x == "카")
    th = re.sub("ค่ะ|คะ", "ครับ", th).replace("ดิฉัน", "ผม").replace("ฉัน", "ผม")
    t["th"] = th
    mp = {"찬": "폼", "디찬": "폼"}
    if n_part == n_ka:
        mp["카"] = "크랍"
    elif n_part:
        warn.append("%s 턴%d: 어미 %d개 ↔ 독음 '카' %d개 — 독음 직접 확인" % (sid, t["num"], n_part, n_ka))
    t["roman"] = _swap_tokens(t["roman"], mp)
    if re.search("จ้ะ|จ๊ะ|จ้า", th):
        warn.append("%s 턴%d: จ้ะ 류 어미 — 남성 화자에 어색, override 필요" % (sid, t["num"]))


def _rename(s, pairs, chars=("A", "B")):
    def r(x):
        for a, b in pairs:
            x = x.replace(a, b)
        return x
    for k in ("title", "hook", "recap"):
        s[k] = r(s[k])
    s["characters"] = {k: (r(v) if k in chars else v) for k, v in s["characters"].items()}
    for t in s["turns"]:
        for k in ("th", "roman", "ko", "note"):
            if k in t:
                t[k] = r(t[k])


def _match(okey, base_id, v):
    """override 키 '<id>@<패턴>' — 패턴 글자는 m·f·*(아무거나). 예: @f* = 여자 학습자 전부, @*m = 남자 상대 전부."""
    oid, _, pat = okey.partition("@")
    if oid != base_id:
        return False
    if pat[0] not in ("*", v[0]):
        return False
    return len(v) == 1 or len(pat) == 1 or pat[1] in ("*", v[1])


def make_variants(scripts, cfg, warn):
    out = []
    lf = cfg["learner_f"]
    for base in scripts:
        pc = cfg["scripts"].get(base["key"], {})
        partner = pc.get("partner", False)
        kinds = ["mf", "fm", "mm", "ff"] if partner else ["m", "f"]
        for v in kinds:
            s = copy.deepcopy(base)
            s["variant"], s["me"] = v, v[0]
            s["partner"] = v[1] if partner else None
            s["id"] = "%s@%s" % (base["id"], v)
            for k in ("prev", "next"):
                if s[k]:
                    s[k] = "%s@%s" % (s[k], v)
            if v[0] == "f":
                for t in s["turns"]:
                    if t["speaker"] == "A":
                        learner_to_female(t, pc.get("i_f", lf["i_th"]), pc.get("i_f_ro", lf["i_ro"]), warn)
                _rename(s, lf["rename"])
                s["characters"]["A"] = s["characters"]["A"].replace("남자친구", "여자친구")
            if partner and v[1] == "m":
                if not pc.get("b_fixed"):
                    for t in s["turns"]:
                        if t["speaker"] == "B":
                            partner_to_male(t, warn, s["id"])
                _rename(s, [tuple(p) for p in pc.get("b_male", [])] + [tuple(p) for p in cfg["partner_m_ko"]], chars=("B",))
            bg = pc.get("b_gender", "f")
            s["voices"] = {"A": v[0], "B": (v[1] if partner and not pc.get("b_fixed") else
                                            ({"m": "f", "f": "m"}[v[0]] if bg == "opp" else bg))}
            for okey, patches in cfg["overrides"].items():
                if not _match(okey, base["id"], v):
                    continue
                for num, patch in patches.items():
                    if num == "meta":
                        s.update(patch)
                    else:
                        s["turns"][int(num) - 1].update(patch)
                        if "th" in patch:  # 사람이 고친 줄 — 그 줄의 자동 경고는 해소됨
                            tag = "%s 턴%s:" % (s["id"], num)
                            warn[:] = [w for w in warn if not w.startswith(tag)]
            s["changed"] = [t["num"] for t, b in zip(s["turns"], base["turns"])
                            if any(t.get(k) != b.get(k) for k in ("th", "roman", "ko", "note"))]
            out.append(s)
    return out
