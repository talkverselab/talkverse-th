"""질문 답 → '내 코스'(재생 목록). 앱에 옮길 선택 규칙의 기준 구현. 난수 없음 — 같은 답이면 같은 결과.

사용:  python select_playlist.py                 (예시 프로필 3개로 시연)
       python select_playlist.py '{"me":"m","domains":["biz"],"moment":"a",...}'
"""
import io
import json
import os
import sys

D = os.path.dirname(os.path.abspath(__file__))
Q = json.load(io.open(os.path.join(D, "questions.json"), encoding="utf-8"))
ALL = json.load(io.open(os.path.join(D, "scripts_th.json"), encoding="utf-8"))["scripts"]
QS = {q["id"]: q for q in Q["questions"]}


NEAR = {"beg": ("beg", "mid"), "mid": ("beg", "mid", "adv"), "adv": ("mid", "adv")}


def drive_scores(ans):
    sc = {d: 0 for d in Q["meta"]["drive_order"]}
    for qid, key in (("q4_moment", "moment"), ("q5_scene", "scene"), ("q6_friend", "friend")):
        opt = next(o for o in QS[qid]["options"] if o["id"] == ans[key])
        for d, v in opt["score"].items():
            sc[d] += v
    return sc


def pick_variant(ans):
    """q1(나) · q2(상대: f/m/any — any 는 이성) → 그 학습자에게 나갈 판만 남긴다."""
    me = ans["me"]
    pt = ans.get("partner", "any")
    pt = {"m": "f", "f": "m"}[me] if pt == "any" else pt
    return [s for s in ALL if s["variant"] in (me, me + pt)]


def playlist(ans, top=12):
    CAT = pick_variant(ans)
    ds = drive_scores(ans)
    max_heat = next(o for o in QS["q13_heat"]["options"] if o["id"] == ans["heat"])["max_heat"]
    scored = []
    for s in CAT:
        if s["ep"] != 1:
            continue  # 이어지는 회차는 1편 뒤에 붙인다
        if s["domain"] not in ans["domains"]:
            continue  # 고른 무대만 — 점수가 아니라 필터
        if s["level"] not in NEAR[ans["level"]]:
            continue  # 고른 레벨과 이웃 레벨까지만
        if s["heat"] > max_heat or (ans["alcohol"] == "no" and "alcohol" in s["flags"]):
            continue
        t = s["tags"]
        pts = ds[s["drive"]] + (3 if s["level"] == ans["level"] else 0)
        pts += 2 if t.get("stage") == ans["stage"] else 0
        pts += 1 if t.get("style") == ans["style"] else 0
        pts += 1 if t.get("persona") == ans["persona"] else 0
        pts += 2 if t.get("conflict") == ans["conflict"] else 0
        pts += 1 if t.get("reg") == ans["reg"] else 0
        scored.append((-pts, s["id"], s))
    scored.sort(key=lambda x: (x[0], x[1]))
    by_id = {s["id"]: s for s in CAT}
    out = []
    for negpts, _, s in scored[:top]:
        out.append((-negpts, s))
        nxt = s["next"]
        while nxt:  # 회차는 끊지 않고 이어 붙인다 (필터에 걸리면 거기서 멈춤)
            n = by_id[nxt]
            if n["heat"] > max_heat or (ans["alcohol"] == "no" and "alcohol" in n["flags"]):
                break
            out.append((-negpts, n))
            nxt = n["next"]
    return out


DEMO = {
    "겉은 일, 속은 설렘 (중급·직진·어른스러운 상대·첫 만남)": {
        "me": "m", "domains": ["work"], "level": "mid", "moment": "a", "scene": "a", "friend": "a",
        "stage": "first", "style": "direct", "persona": "mature", "conflict": "polite", "reg": "polite", "alcohol": "yes", "heat": "hot"},
    "초급 여행자, 속은 승부 (웃어넘김·술 제외·순한 맛)": {
        "me": "m", "domains": ["trip", "move"], "level": "beg", "moment": "b", "scene": "b", "friend": "b",
        "stage": "first", "style": "joke", "persona": "playful", "conflict": "laugh", "reg": "polite", "alcohol": "no", "heat": "mild"},
    "폰 속·밤, 속은 재회 (고급·여자 학습자 × 남자 상대·돌려 말하기·반말)": {
        "me": "f", "partner": "m", "domains": ["phone", "night"], "level": "adv", "moment": "a", "scene": "d", "friend": "a",
        "stage": "ex", "style": "indirect", "persona": "tsundere", "conflict": "escape", "reg": "casual", "alcohol": "yes", "heat": "hot"},
}

if __name__ == "__main__":
    profiles = {"입력": json.loads(sys.argv[1])} if len(sys.argv) > 1 else DEMO
    for name, ans in profiles.items():
        print("\n■ " + name)
        for i, (pts, s) in enumerate(playlist(ans), 1):
            print("  %2d. [%2d점] %s %s [%s] %s%s" % (i, pts, s["emoji"], s["id"], s["level"], s["title"], "  (%d편)" % s["ep"] if s["ep"] > 1 else ""))
