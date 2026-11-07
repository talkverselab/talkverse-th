# 회화 제작 워크플로 — 태국어앱 (2026-11-03)

공통 원칙 https://talkverse.uk/talkverse/dialogue-rules/ 과 일본어앱 `docs/DIALOGUE_WORKFLOW_JA.md`·`docs/REPLICATE_FOR_OTHER_LANGS.md`(구조·톤·도구 원본)를 그대로 따른다. 이 문서는 **태국어만의 차이**와 고정 인물만 적는다. 고칠 때는 덧붙이지 말고 전체를 다시 쓴다.

## 1. 태국어만의 규칙
- **독음(rd)** = 한글, `tools/rd_th.py`(성조 파이프라인 `thai_phon` 그대로, 성조 기호 없음). 검사기 `--fix-rd` 가 채우고 틀린 곳만 손으로 고쳐 `rd_manual: true`. 영·일·중 UI 의 로마자는 `th_tones.json` 이 맡는다. R1 독음 20음절 이하.
- **학습자 A 는 남성 기준(ผม/ครับ)으로 쓴다.** 여성판은 `drafts/script_engine/variants.py` 규칙(ผม→ฉัน, ครับ→ค่ะ/คะ, 독음 폼·크랍→찬·카)으로 앱이 만든다 — 프로필 성별(`LearnerPrefs`)로 고른다. 규칙으로 안 되는 줄은 overrides.
- **Gemini 검수 없음**(방콕 표준 구어만). Grok 재작성 프롬프트에 「확신 없는 줄은 ❓」 — `apply_rewrite.py` 가 그 턴에 `check: true` 를 달고, 세션이 다시 본다(구어 축약 ม่ะ·อะ·ป่ะ·จ้า, 조사 ครับ/ค่ะ/นะ/สิ, 속어 최신성).
- **절벽 구간** R1 ≤109 · R2 ≤149 · R3 ≤295 · R4 ≤642 (회화 빈도, 2026-10-03). 일본어(R1 294)보다 훨씬 좁아 "구간 단어만"은 지킬 수 없다 → 검사기는 구간 밖 단어를 **경고(통계)**로만 센다. 레벨은 턴 수·문장 길이·말투 전환으로 가른다.
- 표현 풀 `data/expressions/top_expressions.csv`(태국 사람이 실제로 많이 쓰는 짧은 말, Grok 추천을 계속 추가). 편마다 2개 이상.
- 장면은 태국형: 편의점(아침 7시 스탬프·데우기), 대학가 카페(차옌·หวานน้อย), BTS/MRT·오토바이 택시·그랩, 야시장·길거리 음식, 콘도, 송끄란·로이끄라통, 사원(ไหว้).
- 출처·교재·드라마 이름 금지(공개 저장소). 실존 브랜드 최소. 이름 고정 금지는 **학습자 A**(변수 `{name}`)에 해당 — 상대 B 는 고정 인물.

## 2. 고정 인물 (캐릭터 시트 `data/review/uxui/char_th_02_sheet.jpg`·`CHARACTERS.md`)
| 인물 | 주제 | 성격 한 줄 |
|---|---|---|
| **ฟ้า**(파, 여) | 연애·친구 | 캐릭터 시트의 여자. 밝고 먼저 다가감(여성이 먼저 플러팅하는 편을 더 많이), 놀리기 좋아하고 555 남발, 패들 테니스·차옌 중독, 놀리다가 먼저 마음을 들킴 |
| **ต้น**(똔, 남) | 친구·문화·생활 | 캐릭터 시트의 남자. 말이 짧음(เออ·ชิลๆ·โอเค), 게임·길거리 음식, 콘도 룸메이트, 다정함을 무심하게 |
| พนักงาน(점원, 시트 5번)·พี่วิน(오토바이 택시 기사, 6번)·แม่ค้า(노점 아주머니, 6번)·ยาม(경비) | 서바이벌·생활·여행 | 이름 없는 조연(고정 6인 시트 `char_th_03_cast.jpg`; 학습자 A = 3번 남/4번 여). 매뉴얼 말투인데 타이밍이 기막힘(S1 「รับแสตมป์ไหมคะ」는 R3 연애까지 콜백) |

**카오스·재미·심쿵(사용자 지시 2026-11-03)**: 편마다 반전 외 사고 1번 더, 2~3턴마다 웃음 포인트, 심쿵 최소 1번(서바이벌도 작은 것 하나), 마지막 턴은 여운이나 한 방 — Grok 재작성 프롬프트 ⑫.
콜백은 턴 `tags` 의 `callback:<편id>`. 반전은 `twist` 턴 번호, 수위 12+(`flags`: alcohol·jealousy·profanity_mild…).

## 3. 파이프라인(편 1개 = 한 바퀴)
1. 초안 JSON(`assets/data/dialogues/R<레벨>/<주제>/<id>.json`, 형식은 일본어앱 README 와 같되 `ja`→`th`, `kana` 없음) — 이 세션이 쓴다.
2. `thvenv python tools/check_dialogues.py --fix-rd <편>` → 오류 0.
3. `python tools/make_rewrite_prompt.py <편>` → `data/review/<id>_grok_rewrite_prompt.md` → `GROK_CDP_PORT=9225 python tools/grok_send.py <프롬프트> data/review/<id>_grok_rewrite.md --tab project/<태국어 회화 검수 방>` (한 요청 = 편 1개, 모델 전문가).
4. `python tools/apply_rewrite.py <편> data/review/<id>_grok_rewrite.md` → 「유지」가 많으면 버리고 다시 → 검사기 `--fix-rd` → ❓ 턴 확인.
5. 사용자 리뷰(채팅 보고 = 턴마다 태국어 / 한글 독음 / 한국어 세 줄) → 통과 편 `approved`. 리뷰 페이지 `tools/review_html.py` → uk 세션에 게시 요청.
6. 장면 컷: A·B 한 쌍당 1컷(8턴 → 4컷), UXUI 방에 캐릭터 시트 첨부, 말풍선·글자 없음 → `talkversehanja` `talkverse_art/scene/th/<편id>/cut<N>.jpg` 푸시 → 앱 `ArtService.sceneCut`.

## 4. Grok(태국어 전용)
Chrome 9225 / `~/chrome-grok-th`(로그인 = 공용 프로필 쿠키 복사, 사용자가 실행). 프로젝트 「태국어 회화 검수」(재작성)·「talkverse UXUI th」(그림). 다른 세션의 방·탭·Chrome 금지. 20~30회차마다 새 챗, 한도 문구면 적힌 시각 +5분.

## 5. 샘플 6편(톤 확정용) → 그 뒤 R1 양산(서바이벌 3 + 주제 5 × 16)
S1 편의점 「천천히 말해 주세요」 · S2 카페 「이거 태국어로 뭐예요?」 · 연애 R1 a1 「절하는 거야?」(ไหว้ 사건, 파가 먼저 말 걸기) · 연애 R1 c1 채팅 「작업 거는 거야?」(ชอบ 오해) · 연애 R2 b1 「막차, 놓쳐도 될까」(BTS) · 연애 R3 b1 「질투? …조금」(편의점 스탬프 콜백).

## 감정 열(2026-11-07, 사용자 지시 — 모든 언어앱)

회화를 새로 쓸 때 턴마다 음성용 감정을 함께 쓴다. Grok 집필 답의 5번째 칸 `감정1|감정2` → `build_from_write.py` 가 턴의 `emotion`(첫 값)·`emotions`(둘 이상일 때)로 넣는다. 값은 `data/tts/PLAN_GUIDE.md` 의 16개(neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle). neutral 만 쓰지 않는다. 감정 계획(`data/tts/plan/<편>.json`)의 `segs` 는 이 값에서 시작해 문장 단위로 나눈다. 기존 172편은 감정 계획을 쓸 때 채운다.

## 어조사 이모지(2026-11-07, 사용자 지시 — 한·중·일·태·베)

문장 끝 어조사(นะ สิ เถอะ เหรอ ล่ะ อะ ว่ะ จ้า เนี่ย ไง 등)로 감정을 나타내는 턴에만 어울리는 이모지를 턴의 `emoji` 칸에 둔다(`th` 본문에는 넣지 않는다 — 음성 본문에 안 들어가게). 새 편은 Grok 답의 태국어 줄 끝 이모지를 `build_from_write.py` 가 떼어 넣고, 기존 편은 `python3 tools/add_emoji.py` 가 감정 열·어조사·문장부호로 고른다. 앱(`LemmaText`)과 리뷰 페이지가 태국어 줄 끝에 보여 준다.

## 회화 음성 품질 기준(2026-11-07 밤, 일본어앱 DIALOGUE_AUDIO.md §5 를 태국어에 적용)

- `qa.py`: 받아쓰기 유사도 ≥ 0.90 · 첫/끝 낱말(newmm) 누락 불합격 · 말 속도 10~16 태국 문자/초(무음 트림 뒤; 참고 음성 중앙값 12 글자/초의 0.8~1.3배 — 태국 문자 수는 모음·성조 기호 포함) · 잡음 바닥 ≤ -55dB(트림 전) · 0dBFS 클리핑 표본 ≤ 4 · 12글자 이상 조각은 whisper 언어 판정 th. 웃음(ฮ่าๆ)은 비교·속도에서 뺀다.
- `pack.py`: 조각 안 쉼 ≤ 0.25초, 조각 사이 0.18초, 10 글자/초 미만이면 atempo 최대 1.15배.
- `make_plan.py`: 읽기에서 「…」 제거(쉼은 pack), 6글자 미만 첫 말은 뒷문장과 한 조각.
- `check_refs.py`: 참고 음성 잡음 ≤ -60dB, 같은 목소리 감정별 음색(장기 평균 스펙트럼) 상관 ≥ 0.90 — `run_all.py` 가 미달분을 seed 바꿔 두 번까지 다시 만든다.
- `voices.json`: 감정 지시문에 natural conversational pace, subtle · shout·flustered·sad·worried 참고 문장 약화.
- 시험 편 r3_work_b1(옛 기준 생성)을 새 기준으로 재면 34조각 중 15개 미달(끝 낱말 6·잡음 4·속도 3·클리핑 2) — 전편 때 참고 음성부터 새로 만들고 이 편도 다시 만든다.
