#!/usr/bin/env python3
"""편 JSON → 장면 컷 그림 요청문(data/review/<편id>_scene_prompt.md). 2026-11-03.
  python tools/make_scene_prompt.py <편.json> [...]
규칙(사용자 지시·REPLICATE §1·§3): A·B 대화 한 쌍당 1컷(8턴 → 4컷, 최대 4컷을 한 요청에), 점토 톤, 말풍선·글자 없음(앱이 얹음),
인물은 확정 캐릭터 시트(data/review/uxui/char_th_02_sheet.jpg — 전송 때 --attach) 두 사람만, 3:2 가로 1168×784, 실제 인물 얼굴 금지.
전송: GROK_CDP_PORT=9225 python tools/grok_send.py <요청문> data/review/<id>_scene.md --tab project/<UXUI th 방> --attach data/review/uxui/char_th_02_sheet.jpg
받은 그림은 talkversehanja talkverse_art/scene/th/<편id>/cut<N>.jpg 로 푸시(uk 세션 저장소)."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'data/review'
CHAR = ("첨부한 캐릭터 시트(6인)의 인물만 등장합니다(점토·펠트 인형 톤, 둥근 얼굴, 따뜻한 조명, 파스텔 배경). "
        "1번 ฟ้า = 골든 탠 피부·긴 흑발 웨이브·환한 미소, 크림 니트(장면에 따라 흰 바이저·테니스 차림). "
        "2번 ต้น = 짧고 단정한 흑발·부드러운 인상·베이지 셔츠·갈색 바지. "
        "3번 학습자(남) · 4번 학습자(여) · 5번 점원 · 6번 노점 아주머니/오토바이 택시 기사. "
        "얼굴·옷은 시트와 똑같이(다른 장면에서도 같은 인물로 보여야 함).")
RULES = ("규칙: ① 그림 안에 글자·말풍선·자막을 절대 넣지 않습니다(말풍선은 앱이 얹습니다) ② 각 컷은 3:2 가로(1168×784), 인물이 크게 ③ 컷마다 그 순간의 표정·몸짓으로 대사의 감정을 보여 주세요 "
         "④ 배경은 방콕(편의점·카페·BTS·야시장 등 장면대로)이되 간판 글자는 없게 ⑤ 실존 인물·브랜드 금지 ⑥ 컷 4장을 한 번에 그려 주세요(cut1~cut4 순서, 같은 인물·같은 옷).")


# 고정 6인(2026-11-03 사용자 확정 "이 6명으로 진행") — 시트 번호는 data/review/uxui/CHARACTERS.md
CAST = {
    'ฟ้า': '1번 ฟ้า(여자 친구·연인)',
    'ต้น': '2번 ต้น(남자 친구·룸메이트)',
    'พนักงาน': '5번 편의점·카페 점원',
    'แม่ค้า': '6번 노점 아주머니',
    'พี่วิน': '6번 오토바이 택시 기사',
}


def role(name):
    return f"{name}(시트 {CAST[name]})" if name in CAST else f"{name}(시트 밖 단역 — 시트 인물과 겹치지 않게)"


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for a in sys.argv[1:]:
        ep = json.load(open(a, encoding='utf-8'))
        who = ep.get('speakers', {})
        a_role = '학습자(시트 3번 — 남자판. 여자판 그림이 필요하면 4번)'
        b_role = role(who.get('B', '상대'))
        turns = ep['turns']
        cuts = []
        for i in range(0, len(turns), 2):
            pair = turns[i:i + 2]
            desc = ' / '.join(f"{'A' if t['speaker']=='A' else t['speaker']}: {t['ko']}" for t in pair)
            cuts.append(f"cut{len(cuts)+1} (턴 {pair[0]['num']}~{pair[-1]['num']}): {desc}")
        cuts = cuts[:4] if len(cuts) <= 4 else cuts[:3] + [f"cut4 (턴 {turns[6]['num']}~{turns[-1]['num']}): " + ' / '.join(f"{t['speaker']}: {t['ko']}" for t in turns[6:])]
        text = (f"[{ep['id']}] 태국어 학습 앱 회화 「{ep['title']}」의 장면 컷 4장을 그려 주세요.\n"
                f"장면: {ep['scene']}. 장소: {ep.get('where','')}. A = {a_role}, B = {b_role}"
                + (f", C = {role(who['C'])}" if who.get('C') else '') + ".\n"
                f"{CHAR}\n{RULES}\n\n컷 구성(대사는 참고용 — 그림에 쓰지 마세요):\n" + '\n'.join(cuts) + "\n")
        p = OUT / f"{ep['id']}_scene_prompt.md"
        p.write_text(text, encoding='utf-8')
        print(p)


if __name__ == '__main__':
    main()
