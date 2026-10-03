# 태국어유니버스 — 인수인계 (2026-10-02 기준)

> 새 세션은 이 파일 → `CLAUDE.md`(빌드·서명·공개 저장소 규칙, 기능별 SSOT) 순으로 읽고 이어서 작업.
> 앱: Flutter · GitHub `talkverselab/talkverse-th`(master, **공개**) · 패키지 `com.talkverse.thai_universe` · 폰 S25 `R3CY20HDN2K`
> 작업 기계: **맥미니**(`~/talkverse/th`, 2026-09-29 노트북에서 이전). 노트북 경로는 `C:\Users\Johnjeon\talkverse\th`.

## 0. 지금 상태
- 최신 커밋 `7ff85fd`(출처 표기 제거). 앱 기능은 아래 1절까지 완료·배포됨.
- ⚠ 맥미니 작업 트리에 **변경 92개**가 보이지만 줄바꿈(CRLF↔LF) 차이뿐이다(`git diff --ignore-cr-at-eol` 은 비어 있음). 커밋하지 말 것 — 정리하려면 내용 확인 후 `git checkout -- .`.
- ⚠ 맥미니에는 아직 `flutter`·`adb`·`pythainlp`·`yt-dlp` 가 없다. 앱 빌드·폰 설치는 CI(푸시) 또는 노트북에서.
- 절벽 곡선 3종 그래프 완료·배포(2026-10-03) → 3절.
- ⚠ 맥미니 `python3` 는 Homebrew 3.14(yt-dlp 설치 때 들어옴, pythainlp 없음). pythainlp 쓰는 스크립트는 `/usr/bin/python3`(3.9), talkverse-uk 생성기는 3.10+ 문법이라 `python3`.

## 1. 앱 기능 (2026-09-10 이후 추가분 — 상세는 CLAUDE.md 해당 절)
| 기능 | 핵심 파일 | CLAUDE.md |
|---|---|---|
| 내 코스(질문 14개 → 스크립트 재생 목록, 무대 8 × 레벨 3 × 욕구 4) | `drafts/script_engine/`, `lib/services/course_service.dart` | §7 |
| 추가 교육 단어(교육부 기초 단어 ป.1~3 중 단어장에 없는 1,631개, 학년별 참고 목록 — 가르치지 않음, `standardEntries` 에서 제외) | `lib/screens/extra_edu_words_screen.dart`, `VocabService.extraEduEntries` | — |
| 초급 문법 16과 | `assets/data/grammar/lessons.json`, `grammar_hub_screen.dart` | §7-1 |
| 계정·이용권(Google·Kakao 로그인, Supabase `tv_*`) | `lib/services/auth_service.dart` | §8 |
| 개발자 메모(모든 화면 캡처+맥락 → Supabase `tv_dev_notes`) | `lib/services/dev_notes.dart` | §9 |
| 콘텐츠 무선 갱신(스크립트·문법 문장은 APK 없이) | `lib/services/content_store.dart`, `tools/content_manifest.py` | §9 |
| 표시 언어 4종(한·영·일·중) | `lib/core/l10n*.dart` | §5 |
| 갤럭시·아이폰 공용 UI | `lib/core/platform.dart` | §6 |
| 앱 자체 업데이트(GitHub 릴리스) | `lib/services/update_service.dart` | §1·§2 |

- 개발자 메모 처리: `select * from tv_dev_notes where status='open'` → 고친 뒤 `status='done'`, `resolution` 기록.

## 2. 항상 지킬 규칙 (사용자 확정)
- **답변·보고는 한국어.**
- 독음은 **한글만**(로마자는 매뉴얼·성조 로마자 모드·외국어 UI 모드만 예외). 이탤릭 안 씀.
- 디자인: 크림 배경·직각 타일 플랫, 그라데이션·글로우·마스코트 금지. 주색 하늘색 `#3F9FD6`.
- **출처 노출 금지**(공개 저장소): 책명·쪽수, 자막·말뭉치 제공처, 영상 서비스명, 드라마·영화 제목을 코드·에셋·문서·파일명·화면 문구·커밋 메시지 어디에도 쓰지 않는다. 원문 문장은 넣지 않고 단어·빈도 통계만, 문장은 자체 제작. 출처가 필요한 메모는 git 제외 폴더 `corpus/` 에만.
- 대화는 8턴. 남성 화자 남성 음성, 여성 화자 여성 음성, 단어·표현은 여성 음성, 재생 1초 지연.
- 요청이 "푸시/설치"면 commit → push → 빌드 → `adb install --user 0 -r` → 실행까지(폰 연결돼 있으면 묻지 말 것).
- 서명 키 새로 만들지 말 것(CLAUDE.md §1).

## 3. 완료 — 절벽 곡선 3종 (사용자 요청 2026-09-28, 배포 2026-10-03)
- 요청: "50편으로는 모자란 것 같다" → 소스 3개(①원래 ②추가 ③대규모 코퍼스)의 누적 커버리지 곡선을 **한 그래프에 부드러운 곡선 3개 + 절벽(R1~R4) 빨간 수직선**으로 talkverse.uk 태국어 페이지에 표시.
- 단어는 영상(청크) 하나씩 받아 세고 자막 원문은 즉시 삭제 — 빈도만 보관.
- 상태: 세 소스 계수 완료, talkverse.uk 반영(커밋 talkverse-uk `be93e93`). R1~R4 = ① 109·149·295·642 / ② 101·136·260·536 / ③ 120·172·381·923.
- 경로·주의점(출처 포함): **`corpus/HANDOFF.md` 맨 앞 절** (로컬 전용).
- 배포: 맥미니엔 wrangler 로그인 없음 → 노트북에서 `npx wrangler deploy`(노트북 git 은 SSH 로 GitHub 인증 불가 → 맥에서 `git bundle` 넘겨 pull).
- 생성기: `~/talkverse-uk/tools/th_cliff3.py` → `public/talkverse/lang/th.html` 의 `<!--cliff3-->` 구간 갱신 → `npx wrangler deploy`.

## 4. 반복 절차
```
# 푸시 (403 이면 계정 전환 먼저)
gh auth switch --user talkverselab
git pull --rebase && git push origin master

# 문장만 고쳤을 때(APK 불필요)
python drafts/script_engine/build_scripts.py && python drafts/script_engine/publish_to_app.py   # manifest 자동 갱신 → 커밋·푸시

# 빌드·설치(노트북 또는 flutter 있는 기계)
flutter build apk --release
adb -s R3CY20HDN2K install --user 0 -r build/app/outputs/flutter-apk/app-release.apk
adb -s R3CY20HDN2K shell "monkey -p com.talkverse.thai_universe -c android.intent.category.LAUNCHER 1"
```
- CI: push → GitHub Actions → `releases/latest` 에 APK + `latest.json`. `**.md`·콘텐츠 JSON 만 바뀐 푸시는 빌드 안 함.
- 폰 업데이트: 앱 → 프로필·설정 → 「앱 업데이트」.

## 5. 에셋 생성 순서 (단어 데이터 바꿀 때, `python -X utf8`)
1. `tools/vocab_pipeline/build_spoken_freq.py` → `assets/data/wordsets/th_top1000.csv` (로컬 `corpus/` 통계)
2. `build_phrasebook.py` → `phrasebook_parsed.json`(로컬 전용)
3. `build_vocab.py` → `th_vocab.json`·`th_topics.json`·`th_expressions.json`·`th_roots.json`
4. `build_obec.py` → `assets/data/wordsets/th_obec_basic.json`
5. `tools/tone_pipeline/build_tones.py` → `th_tones.json`
6. `flutter test`

## 6. 남은 선택 과제 (요청 전에는 하지 않음)
- 공개 저장소 과거 커밋에 출처 문자열이 남아 있음(현재 파일에서는 제거). 지우려면 history rewrite + 강제 푸시 — 사용자 결정 필요.
- 커밋 9248fe6 의 원서 전사 `pages/*.md` 도 같은 처리 필요.
- 자동 성조 오류 검토.

## 7. 이전 기록
- 2026-09-10 판의 상세(단어장·루트 단어·단어 그림 구조, 18개 앱 공통 작업)는 git 이력의 `HANDOFF_2026-09-10.md` 참고(`git show 7ff85fd:HANDOFF_2026-09-10.md`).
