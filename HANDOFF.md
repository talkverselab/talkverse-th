# 태국어유니버스 — 인수인계 (2026-10-06 기준)

> 새 세션은 이 파일 → `CLAUDE.md` 순으로 읽고 이어간다. 빌드·서명·배포·공개 저장소 규칙은 CLAUDE.md §1~§4, 기능별 설명은 §5~§9.
> 출처 이름(자막·말뭉치 제공처, 영상 서비스, 작품 제목)이 필요한 상세는 git 제외 파일 `corpus/HANDOFF.md` 맨 앞 절에 있다(맥미니 로컬 전용).
> 직전 세션: 맥미니, talkverse.world 계정(2026-10-02 lab → world 이전), 2026-10-03~06.

## 1. 지금 상태

| 항목 | 상태 | 값 · 근거 |
|---|---|---|
| 앱 저장소 `talkverselab/talkverse-th` | 푸시됨 | 마지막 기능 커밋 `857f639`(추가 교육 단어) + 이 HANDOFF 커밋. 원격 master = 로컬 HEAD 확인(2026-10-06 `git fetch`) |
| 앱 릴리스 | 게시됨 | GitHub Actions 실행 #46 성공 → `latest` 릴리스 `latest.json` = build 46, version 0.2.0, sha 857f639 |
| 폰(S25)에 빌드 46 설치 | **미확인** | 앱 안 「앱 업데이트」로 받아야 함. 「단어장 → 📎 추가 교육 단어」 화면 실기기 확인 안 함 |
| 추가 교육 단어 | 완료 | 교육부 기초 단어(ป.1~3) 2,625개 중 단어장에 있음 994 / 없음 1,631(ป.1 230·ป.2 683·ป.3 718). 없는 1,631개를 별도 화면에 학년별 나열, `standardEntries`(중요 단어·루트 표준 단계)에서는 제외 |
| `flutter analyze` / `flutter test` | 통과 | 맥미니에서 이슈 0 / 28개 통과(2026-10-03) |
| 사이트 talkverse.uk 태국어 페이지 | 배포됨·라이브 확인 | talkverse-uk `20d4094`, Worker 버전 `0f2eef24-6711-43a3-b095-c30e408a95b8`. 절벽 곡선 3종 + 코퍼스 절벽선·차이 음영 + 「절벽 비교」 표 + 「교육부 기초 단어와 비교」 표 |
| talkverse-uk 저장소 | 푸시됨 | origin/main = `20d4094`(로컬 `ahead 4` 표시는 URL 로 푸시해서 추적 참조가 낡은 것 — `git fetch` 하면 사라짐) |
| 절벽 R1·R2·R3·R4 | 확정 | ① 원래 50편 260,333토큰 109·149·295·642 / ② 추가 드라마 20편 771영상 914,368토큰 101·136·260·536 / ③ 코퍼스 50,361,190토큰 120·172·381·923 |
| 단어 겹침(원래 절벽 단어 중 코퍼스 같은 절벽 안) | 확정 | R1 90/109 · R2 127/149 · R3 236/295 · R4 524/642 |
| ② 추가 소스 계수 | 완료 | 1,011개(목록 1,014 중 중복 3): 자막 771(직접 195·자동 576), 자막 없음 236, 연령 제한 4(건너뜀) |
| 작업 트리 미커밋 | 커밋하지 말 것 | 약 91개 파일이 줄바꿈(CRLF↔LF)만 다름(`git diff --ignore-cr-at-eol` 비어 있음). 미추적 `.claude/settings.local.json`, `ios/Podfile`(맥 flutter 가 만든 것 — 필요 여부 **미확인**) |
| 개발자 메모 `tv_dev_notes` open 건 | **미확인** | 이번 세션에서 조회 안 함 |
| 코퍼스 원본 `corpus/cliff3/` 의 코퍼스 원본 `.txt.gz`(650MB, 파일명은 `corpus/HANDOFF.md`) | 남아 있음 | 지워도 되는지 사용자에게 물었으나 답 없음 — 지우지 말 것 |
| 백그라운드 작업 | 없음 | 계수·CI 감시·로컬 서버 모두 종료 확인 |

## 2. 막혀 있는 것 · 주의

| 문제 | 원인 | 푸는 방법 | 안 되는 방법 |
|---|---|---|---|
| 맥미니에서 talkverse-uk `git pull/push` | 그 저장소 remote 가 `git@github.com:`(SSH)인데 맥에 GitHub SSH 키 없음 → `Permission denied (publickey)` | 토큰 헬퍼로 HTTPS: `T=$(gh auth token --user talkverselab); git -c credential.helper= -c "credential.helper=!f(){ echo username=x-access-token; echo password=$T; };f" push https://github.com/talkverselab/talkverse-uk.git main` (pull 도 같은 방식) | `gh auth switch` — 맥 gh 활성 계정은 `gpyungbusan`(다른 세션용), 바꾸지 말 것 |
| 맥미니에서 talkverse-th 푸시 | remote 는 HTTPS 이나 기본 자격 증명 동작 **미확인** | 위와 같은 토큰 헬퍼로 `https://github.com/talkverselab/talkverse-th.git HEAD:master` (이번 세션 전부 이 방식으로 성공) | — |
| 노트북에서 SSH 로 `git pull` | 노트북 git 이 SSH 세션에서는 GitHub 자격 증명을 못 읽음(`could not read Username`) | 맥에서 번들 넘기기: `git bundle create uk.bundle main` → `scp uk.bundle laptop:C:/Users/Johnjeon/uk.bundle` → `ssh laptop 'cmd /c "cd /d C:\Users\Johnjeon\talkverse-uk && git pull --ff-only C:\Users\Johnjeon\uk.bundle main"'` | 노트북 PowerShell 에 `&&` (기본 셸이 PowerShell 5 → 파서 오류). `cmd /c "..."` 로 감쌀 것 |
| talkverse.uk 배포 | 2026-10-03엔 맥 wrangler 미로그인이라 노트북에서 배포함 | 2026-10-06 확인: 맥 `npx wrangler whoami` = talkverse.lab OAuth 로그인됨 → 맥에서 `cd ~/talkverse-uk && npx wrangler deploy` 가능(맥에서 실제 배포는 **미확인**). 안 되면 노트북에서 위 번들 pull 후 `npx wrangler deploy` | `_KEYS.env` 에 Cloudflare 토큰 없음 |
| 맥 `python3` | yt-dlp(Homebrew) 설치 때 Homebrew Python 3.14 가 `python3` 를 가져감, 여기엔 pythainlp 없음 | pythainlp 쓰는 스크립트(`corpus/cliff3/count_added.py`, `tools/vocab_pipeline/*`) = `/usr/bin/python3`(3.9, pythainlp 5.3.8). talkverse-uk `tools/th_cliff3.py` = `python3`(3.14, `write_text(newline=)` 때문에 3.10+ 필요) | 3.9 로 th_cliff3.py 실행 → TypeError |
| 맥에서 flutter 실행 후 | `flutter analyze/test` 가 `analysis_options.yaml`·`ios/Flutter/*.xcconfig`·`pubspec.lock` 을 고침 | 커밋 전 `git checkout -- analysis_options.yaml ios/Flutter/Debug.xcconfig ios/Flutter/Release.xcconfig pubspec.lock`, 커밋은 파일을 지정해 `git add` | `git add -A`(줄바꿈만 바뀐 91개가 딸려 들어감) |
| 맥에 adb 없음 | 설치 안 함 | 폰 설치는 앱 「앱 업데이트」 또는 노트북 adb(`%LOCALAPPDATA%\Android\platform-tools\adb.exe`, PATH 미등록) | — |
| 연령 제한 영상 4개 | 영상 사이트 로그인 필요 | 계정 쿠키(`--cookies-from-browser`)를 쓰면 되지만 사용자 계정 사용이라 하지 않음 — 수치 영향 미미 | — |
| 맥에서 OneDrive 전자책 폴더 읽기 | 클라우드 전용 → `Resource deadlock avoided` | PC `D:\OneDrive\...` 에서 `scp pc:"D:/OneDrive/..."` | 맥에 내려받기(용량) |

## 3. 다음 할 일 (순서대로)

진행 중인 사용자 요청은 없다. 아래는 남은 확인·정리 항목.

1. **폰 확인(사용자)** — S25 에서 앱 → 프로필·설정 → 「앱 업데이트」로 build 46 설치 → 단어장 → 「📎 추가 교육 단어」(학년 칩·검색·발음) 확인. 「중요 단어」 전체 수가 1,631 줄었는지 확인.
2. **개발자 메모 처리** — Supabase 프로젝트 `Talkverse`(CLAUDE.md §9 흐름): `select * from tv_dev_notes where status='open' order by created_at;` → 고친 뒤 `update ... set status='done', resolution=..., resolved_at=now()`.
3. **맥 추적 참조 정리** — `cd ~/talkverse/th && git fetch origin`, `cd ~/talkverse-uk && git fetch`(SSH 막히면 생략 가능, 기능 영향 없음).
4. **사용자 결정 대기** — (a) `corpus/cliff3/` 코퍼스 원본 `.txt.gz` 650MB 삭제 여부 (b) 공개 저장소 과거 커밋의 출처 문자열·원서 전사(`9248fe6` 의 `pages/*.md`) 제거를 위한 history rewrite + 강제 푸시 여부 (c) 자동 성조 오류 검토.
5. 절벽 그래프·비교표를 다시 만들 때: `cd ~/talkverse-uk && python3 tools/th_cliff3.py` → `public/talkverse/lang/th.html` 의 `<!--cliff3-->` 구간 교체 → 데스크톱·390px 확인 → 커밋·푸시(§2 토큰 방식) → `npx wrangler deploy` → `curl -sL https://talkverse.uk/talkverse/lang/th | grep 절벽 비교`.
   - 화면 캡처: 맥 `~/Library/Caches/ms-playwright/chromium-1148/chrome-mac/Chromium.app/Contents/MacOS/Chromium --headless=new --window-size=390,4200 --screenshot=out.png <url>` (로컬 서버 `python3 -m http.server 8765` 를 `public/` 에서).

### 반복 절차
```
# 문장만 고쳤을 때(APK 불필요) — /usr/bin/python3
/usr/bin/python3 drafts/script_engine/build_scripts.py && /usr/bin/python3 drafts/script_engine/publish_to_app.py   # manifest 자동 갱신 → 커밋·푸시

# 코드 변경 → 푸시하면 CI 가 APK + latest.json (CLAUDE.md §2)
flutter analyze && flutter test          # 맥미니 가능, 끝나면 §2 의 되돌리기
# CI 확인
GH_TOKEN=$(gh auth token --user talkverselab) gh run list -R talkverselab/talkverse-th -L1
# 케이블 설치는 노트북에서: adb -s R3CY20HDN2K install --user 0 -r <apk>
```

### 에셋 생성 순서 (단어 데이터 바꿀 때, `/usr/bin/python3 -X utf8`)
1. `tools/vocab_pipeline/build_spoken_freq.py` → `assets/data/wordsets/th_top1000.csv` (로컬 `corpus/` 통계)
2. `build_phrasebook.py` → `phrasebook_parsed.json`(로컬 전용)
3. `build_vocab.py` → `th_vocab.json`·`th_topics.json`·`th_expressions.json`·`th_roots.json`
4. `build_obec.py` → `assets/data/wordsets/th_obec_basic.json` (`inVocab` 갱신 — 추가 교육 단어 수가 바뀜. 앱은 실행 시 단어장과 다시 대조하므로 코드 수정 불필요)
5. `tools/tone_pipeline/build_tones.py` → `th_tones.json`
6. `flutter test`

## 4. 기계별 준비 상태

| | 맥미니 (주 작업기, `ssh talkverse@100.73.137.80`) | 노트북 (맥에서 `ssh laptop`) | PC (맥에서 `ssh pc`) |
|---|---|---|---|
| 앱 repo | `~/talkverse/th` — HEAD 최신, 줄바꿈 차이만 미커밋 | `C:\Users\Johnjeon\talkverse\th` — `7ff85fd` 에 멈춤(3커밋 뒤처짐, SSH 로는 pull 불가 → 번들 또는 노트북에서 직접 pull) | 없음 |
| 사이트 repo | `~/talkverse-uk` — `20d4094` | `C:\Users\Johnjeon\talkverse-uk` — `20d4094`(번들로 맞춤) | 없음 |
| 코퍼스(로컬 전용, git 제외) | `~/talkverse/th/corpus/` (`cliff3/` 빈도 파일, `analysis_th_tiers.csv`, `HANDOFF.md`) | 옛 사본(갱신 안 됨) | 없음 |
| 파이썬 | `/usr/bin/python3` 3.9 + pythainlp 5.3.8 / `python3` = Homebrew 3.14 | 미확인 | — |
| Flutter | `/opt/homebrew/bin/flutter` 3.47.6 (analyze·test 됨, APK 빌드는 안 해 봄 — **미확인**) | `C:\flutter\bin\flutter.bat` | — |
| adb | 없음 | `%LOCALAPPDATA%\Android\platform-tools\adb.exe` | — |
| 서명 키 | `android/key.properties`·`android/app/upload-keystore.jks` 있음 | `android\key.properties` 있음 | — |
| yt-dlp | Homebrew 2026.08.19 (`--js-runtimes node`) | — | — |
| wrangler | talkverse.lab OAuth 로그인됨(2026-10-06 확인) | 로그인됨(2026-10-03 배포 성공) | — |
| GitHub | gh 계정 talkverselab(비활성)·gpyungbusan(활성) — 토큰 헬퍼로만 사용 | SSH 세션에선 자격 증명 불가 | — |
| 키 파일 | `~/OneDrive/APIs/_KEYS.env`(Cloudflare 토큰 없음), Supabase 접속값은 `lib/core/backend.dart`(공개 키) | `OneDrive\APIs\_KEYS.env` | — |
| 기타 | headless Chromium(위 §3-5 경로) | — | `D:\OneDrive` 전체 동기화 — 태국어 교재 MD `D:\OneDrive\01_전자책_외국어\전자책_MD\01.04_동남아시아어\01.04.02.태국어\`(개인 소장본, 공개 금지) |

## 5. 결정 사항 (바꾸지 말 것)

- **답변·보고는 한국어.** 독음은 **한글만**(로마자는 매뉴얼·성조 로마자 모드·외국어 UI 모드만 예외), 이탤릭 안 씀.
- 디자인: 크림 배경·직각 타일 플랫, 그라데이션·글로우·마스코트 금지. 주색 하늘색 `#3F9FD6`.
- **출처 노출 금지**: CLAUDE.md §4. 커밋 메시지 포함. 출처 메모는 `corpus/` 에만. (talkverse.uk 페이지의 공개 연구 코퍼스 이름 표기는 그 사이트의 기존 관례 — 영상 서비스명·작품 제목은 금지.)
- 대화 8턴. 남성 화자 남성 음성, 여성 화자 여성 음성, 단어·표현은 여성 음성, 재생 1초 지연.
- 요청이 "푸시/설치"면 commit → push → 빌드 → `adb install --user 0 -r` → 실행까지(폰 연결돼 있으면 묻지 말 것).
- 서명 키 새로 만들지 말 것(CLAUDE.md §1).
- **원래 50편 유지**(2026-10-03): 추가 소스로 늘리지 않는다. 사용자 판단 "충분하네 딱봐도" — 그래프에 코퍼스 절벽을 함께 그려 충분함을 보인다. 원래 목록의 코퍼스 커버율(R1 50.5% 등)은 페이지에 넣지 않았다.
- **추가 교육 단어**(2026-10-03): 교육 자료 = 태국 교육부 기초 단어 목록(ป.1~3, `th_obec_basic.json`). 우리 단어장에 없는 것만 「추가 교육 단어」로 나열하고 **가르치지 않는다**(알고도 안 가르친다는 걸 앱·사이트에 밝힘). 출처 목록에 주제(도메인)가 없으므로 주제 분류는 하지 않고 학년만 쓴다. 교재 전자책(시판 교재)은 이 용도로 쓰지 않는다.
- 연령 제한 영상은 계정 쿠키로 받지 않고 건너뛴다.
- woojoo.page·g-pyung.com 등 다른 사이트에 이 작업을 섞지 않는다(전역 CLAUDE.md).

## 푸시 확인
- 이 파일을 담은 커밋은 맥미니에서 §2 의 토큰 방식으로 푸시했다. 확인: `git ls-remote https://github.com/talkverselab/talkverse-th.git refs/heads/master` 가 이 커밋 해시와 같으면 푸시된 것.
