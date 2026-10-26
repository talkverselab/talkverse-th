# Supabase → Cloudflare 이관 — 태국어앱 조사 · Talkverse ID 첫 설계

2026-10-26 작성. 지침: `~/cloudflare-migration/GUIDE.md`(한자 세션). **아직 아무것도 만들지 않았다**(D1·R2·Worker 생성, 코드 변경 없음).

## 1. 조사 — 이 앱이 Supabase 에서 쓰는 것

조회 2026-10-26, 공용 프로젝트 `Talkverse`(SELECT 만).

### 코드에서 Supabase 를 만지는 곳

| 파일 | 하는 일 |
|---|---|
| `lib/core/backend.dart` | 프로젝트 주소 · publishable 키 · `appLang='th'` · 로그인 딥링크 `io.supabase.talkverse.th://login-callback/` |
| `lib/services/auth_service.dart` | 로그인(Google·Kakao OAuth, PKCE) · 프로필 · 이용권 RPC · 코스 동기화 |
| `lib/services/dev_notes.dart` | 개발자 메모 넣기·내 메모 읽기 · 화면 캡처 업로드 |
| `lib/screens/account_screen.dart` | `AuthService` 만 부른다(직접 접근 없음) |
| `pubspec.yaml` | `supabase_flutter: ^2.9.0` |
| `AndroidManifest.xml` · `ios/Runner/Info.plist` | 딥링크 스킴 |

콘텐츠 무선 갱신(`content_store.dart`)과 앱 업데이트는 GitHub 를 쓴다 — Supabase 와 무관.

### 표 (`tv_` 접두사, 스키마 `docs/sql/tv_accounts_billing.sql` · `tv_dev_notes.sql`)

| 표 | 행 수 | 앱이 하는 일 | 비고 |
|---|---|---|---|
| `tv_profiles` | 5 | 본인 행 읽기·고치기 | 가입 트리거가 만든다 |
| `tv_identities` | 5 (email 3 · google 2) | 앱은 안 씀 | 트리거가 기록 |
| `tv_products` | 8 | 앱은 직접 안 읽음 | 언어·세트·전체 상품(초기값만) |
| `tv_plans` | 16 | 앱은 직접 안 읽음 | 가격 자리값 |
| `tv_orders` | 0 | — | 결제 미구현 |
| `tv_subscriptions` | 1 | 이용권 계산에 쓰임 | 쓰기는 서버만 |
| `tv_course_answers` | 0 | 답 올리기·받기(upsert) | `app_lang` 열로 앱 구분 |
| `tv_course_progress` | 1 (th) | 완료 회차 올리기·받기 | 〃 |
| `tv_dev_notes` | 0 | 메모 넣기·내 메모 읽기 | 처리 상태는 Claude 세션이 고침 |

`tv_` 표 전체 304 kB. **행이 적어 데이터 옮기기는 몇 분 일**이다.

### 저장소 버킷
- `dev-notes`(비공개, 5MB, png·jpeg, 본인 폴더 `<uid>/` 만) — 파일 0개.

### RPC · 트리거 · RLS
- RPC: `tv_has_access(p_lang)` · `tv_my_entitlements()` → 둘 다 `tv_entitlements(uid)`(구독 → 요금제 → 상품 → 언어 목록 펼치기, `all` 상품은 20개 언어).
- 트리거: `tv_on_auth_user_created`(가입 → 프로필 + 로그인 수단) · `tv_touch`(`updated_at` 자동 갱신: profiles·subscriptions·course_answers).
- RLS: 모든 표가 "본인 행만", 상품·요금제는 누구나 읽기, 주문·구독은 읽기만.

### Auth — **쓴다(지침 5번: 맨 마지막 대상)**
- 회원 5명: 이메일 3(비밀번호 있음, 모두 이메일 확인됨) · Google 2. Kakao 는 코드에 있으나 가입자 0. Naver 는 설계만(talkverse.uk Worker 경유 예정, 미구현).
- 방식: Supabase 내장 OAuth, 브라우저 → 딥링크 복귀(PKCE). 앱의 모든 서버 기능(프로필·이용권·코스·메모)이 로그인 뒤에만 동작한다.
- **이 앱의 Supabase 사용은 전부 로그인에 묶여 있다** → 로그인 방식이 정해지기 전에는 옮길 수 있는 부분이 없다.

### 다른 앱과의 관계
- `tv_` 표를 코드에서 쓰는 언어 앱은 지금 **태국어 하나뿐**(`~/talkverse/*/lib` 검색). talkverse.uk·talkverse-site 에도 사용처 없음.
- 그러나 설계상 계정·요금제·구독은 **모든 언어 앱 공용**이다(세트 상품 `set_sea`·`all` 이 여러 앱에 걸친다).

### 지금 상태
- 402 제한 중에는 로그인·동기화·메모 전송이 실패하지만 앱 학습 기능은 그대로 된다(전부 `_guard` 로 실패를 삼키고, 메모는 폰에 쌓였다가 나중에 보낸다).

## 2. 설계 — Talkverse ID 와 공용 학습 DB (첫 설계, 2026-10-26)

사용자 결정(2026-10-26, 한자 세션 전달 · GUIDE §구조 규칙 1): **ID 는 하나** — Talkverse 언어앱 20개와 talkverse.uk 홈페이지가 같은 계정을 쓴다. 이 설계를 태국어앱 세션이 처음 잡고, 다른 언어앱·talkverse.uk 는 여기에 맞춘다.

| 이름 | 종류 | 담는 것 | 담당 |
|---|---|---|---|
| `talkverse-accounts` | D1 | 계정·로그인 수단·세션·상품·요금제·주문·구독 | 이 문서 |
| `talkverse-auth` | Worker (`auth.talkverse.uk`) | 로그인·토큰 발급/검증·구독 확인 | 이 문서 |
| `talkverse-db` | D1 | 언어앱 20개 공용 학습 데이터(행마다 `lang`) | 이 문서(첫 표), 앱마다 표 추가 |
| `talkverse-api` | Worker (제안) | `talkverse-db` 읽기·쓰기 | 2-6 |
| `talkverse-files` | R2 (제안) | 개발자 메모 캡처 등 비공개 파일 | 2-6 |

`<언어>-db` 는 만들지 않는다. **생성·적재는 요금제가 정해진 뒤.**

### 2-1. 공통 규칙
- id: TEXT. 사용자 id 는 UUID — **Supabase `auth.users.id` 를 그대로 옮겨** 기존 회원·학습 기록의 참조가 끊기지 않게 한다. 새 사용자는 `crypto.randomUUID()`.
- 시각: TEXT, ISO 8601 UTC(`2026-10-26T03:00:00.000Z`). JSON: TEXT. 참/거짓: INTEGER 0/1. 원화 금액: INTEGER, 달러: INTEGER 센트.
- 두 DB 사이에는 외래 키를 걸 수 없다 — `talkverse-db` 의 `user_id` 는 **토큰을 검증한 뒤 얻은 id 만** 쓴다(앱이 보낸 user_id 를 믿지 않음).
- 토큰·비밀번호·일회용 코드는 **해시만** 저장(SHA-256, 비밀번호는 2-4).
- `updated_at` 은 Worker 가 넣는다(Postgres 트리거 `tv_touch` 대신).

### 2-2. `talkverse-accounts` 스키마

```sql
-- 계정
create table users (
  id            text primary key,              -- UUID (Supabase uid 그대로)
  email         text,                          -- 소문자. 소셜에서 이메일을 안 주면 null
  email_verified integer not null default 0,
  display_name  text,
  gender        text check (gender in ('m','f')),
  market        text not null default 'kr' check (market in ('kr','global')),
  country       text,                          -- ISO 2자리
  ui_lang       text not null default 'ko',    -- ko en ja zh
  marketing_ok  integer not null default 0,
  status        text not null default 'active' check (status in ('active','disabled','deleted')),
  created_at    text not null,
  updated_at    text not null,
  last_login_at text
);
create unique index users_email on users(email) where email is not null and email_verified = 1;

-- 로그인 수단 — 한 계정에 여러 개. 같은 "확인된 이메일"이면 같은 계정에 붙인다(2-4)
create table identities (
  provider      text not null check (provider in ('google','kakao','naver','apple','email')),
  provider_uid  text not null,                 -- 제공자의 사용자 번호(sub). email 은 이메일 주소
  user_id       text not null references users(id) on delete cascade,
  email         text,
  password_hash text,                          -- provider='email' 일 때만 (2-4)
  linked_at     text not null,
  last_used_at  text,
  primary key (provider, provider_uid),
  unique (user_id, provider)
);
create index identities_user on identities(user_id);

-- 로그인 세션 — 앱은 refresh 토큰, 웹은 쿠키. 값은 해시만
create table sessions (
  id           text primary key,               -- 세션 id (토큰의 sid)
  user_id      text not null references users(id) on delete cascade,
  kind         text not null check (kind in ('app','web')),
  client_id    text not null references clients(id),
  token_hash   text not null unique,           -- 지금 유효한 refresh 토큰 / 쿠키 값의 해시
  prev_hash    text,                           -- 바로 앞 refresh 토큰(재사용 감지용)
  device       text,                           -- 'th android 0.2.0+47' 같은 설명
  created_at   text not null,
  last_seen_at text not null,
  expires_at   text not null,
  revoked_at   text
);
create index sessions_user on sessions(user_id);

-- 로그인 도중의 일회용 값 — OAuth state·PKCE, 앱에 넘길 교환 코드, 이메일 코드
create table auth_flows (
  id             text primary key,             -- state 값 / 교환 코드 해시 / 이메일 코드 id
  kind           text not null check (kind in ('oauth_state','exchange','email_code')),
  client_id      text not null,
  user_id        text,                         -- exchange: 로그인된 사용자
  email          text,                         -- email_code: 받는 주소
  code_hash      text,                         -- email_code: 6자리 코드 해시
  code_challenge text,                         -- 앱의 PKCE S256
  redirect_uri   text,
  attempts       integer not null default 0,
  created_at     text not null,
  expires_at     text not null                 -- state 10분 · exchange 2분 · email 10분
);

-- 로그인을 쓰는 곳(앱 20개 + 홈페이지). 되돌아갈 주소를 여기 등록된 것만 허용
create table clients (
  id            text primary key,              -- 'th' 'zh' … 'web'
  kind          text not null check (kind in ('app','web')),
  lang          text,                          -- 앱이면 언어 코드
  redirect_uris text not null,                 -- JSON 배열: ["talkverse.th://auth"] / ["https://talkverse.uk/auth/done"]
  active        integer not null default 1
);

-- 상품·요금제·주문·구독 — Supabase tv_ 표와 같은 뜻
create table products (
  id text primary key, kind text not null check (kind in ('language','set','all')),
  langs text not null default '[]',            -- JSON 배열, all 은 []
  name_ko text not null, name_en text, sort integer not null default 100, active integer not null default 1
);
create table plans (
  id text primary key, product_id text not null references products(id),
  period text not null check (period in ('month','year')),
  price_krw integer, price_usd_cents integer, sku_google text, sku_apple text,
  trial_days integer not null default 0, active integer not null default 1
);
create table orders (
  id text primary key, user_id text not null references users(id) on delete cascade,
  plan_id text not null references plans(id),
  channel text not null check (channel in ('web_kr','web_global','google_play','app_store','admin')),
  provider_ref text, amount integer not null, currency text not null default 'KRW',
  status text not null default 'pending' check (status in ('pending','paid','refunded','canceled','failed')),
  raw text, created_at text not null, paid_at text
);
create unique index orders_channel_ref on orders(channel, provider_ref) where provider_ref is not null;
create table subscriptions (
  id text primary key, user_id text not null references users(id) on delete cascade,
  plan_id text not null references plans(id), order_id text references orders(id),
  channel text not null, channel_ref text,
  status text not null default 'active' check (status in ('active','grace','canceled','expired','refunded')),
  starts_at text not null, ends_at text not null, auto_renew integer not null default 1, updated_at text not null
);
create index subs_user on subscriptions(user_id, ends_at desc);

-- 관리 키(해시만) — 구독 수동 부여·개발자 메모 처리 같은 관리 경로용
create table admin_keys (key_hash text primary key, label text not null, scopes text not null, created_at text not null, revoked_at text);
```

`clients` 초기값: 언어앱 20개(`th` … 각 `talkverse.<언어>://auth`) + `web`(`https://talkverse.uk/auth/done`). 표 순서상 `clients` 를 `sessions` 보다 먼저 만든다.

### 2-3. 토큰

| | 앱 | 웹(talkverse.uk) |
|---|---|---|
| 들고 다니는 것 | access 토큰(JWT) + refresh 토큰 | 쿠키 하나 |
| 보내는 법 | `Authorization: Bearer <access>` | 쿠키 자동 |
| 수명 | access **1시간** · refresh **60일**, 쓸 때마다 새로 바꿈(rotation) | **30일**, 하루 한 번 이상 쓰면 만료 연장 |
| 저장 | 앱: `flutter_secure_storage` | `tv_sid` 쿠키 — HttpOnly · Secure · `Domain=.talkverse.uk` · `SameSite=Lax` · `Path=/` |

- **access JWT**: ES256(P-256, Workers WebCrypto 기본 지원). 머리 `kid`. 내용 `iss=https://auth.talkverse.uk` · `sub`=user id · `sid`=세션 id · `aud`=client id(`th`) · `iat` · `exp` · `ent`=지금 쓸 수 있는 언어 목록(예 `["th"]`, 전체 상품이면 `["*"]`). 개인 키는 `wrangler secret`(사용자가 넣음), 공개 키는 `GET /.well-known/jwks.json`.
- 다른 Worker(`talkverse-api` 등)는 **JWKS 로 서명만 확인**하면 되고 매번 DB 를 보지 않는다. 즉시 끊어야 할 일(로그아웃·계정 정지)은 access 수명 1시간 안에 반영된다 — 더 빨라야 하면 `/session/verify` 를 부른다.
- **refresh 토큰**: 무작위 32바이트(base64url), 해시만 `sessions.token_hash`. 이미 바꾼 토큰(`prev_hash`)이 다시 오면 탈취로 보고 그 세션을 끊는다.
- 쿠키 값 `tv_sid` 도 무작위 32바이트, 해시만 저장. 웹은 JWT 를 쓰지 않는다(사이트 Worker 가 서비스 바인딩으로 확인).

### 2-4. 로그인 방식

**Google · Kakao (· 나중에 Naver · Apple)** — Worker 가 OAuth 를 직접 처리(Authorization Code + PKCE).

앱:
1. 앱이 `code_verifier` 를 만들고 브라우저로 `https://auth.talkverse.uk/oauth/<provider>/start?client_id=th&redirect_uri=talkverse.th://auth&code_challenge=<S256>` 를 연다.
2. Worker: `clients` 에서 redirect_uri 확인 → `auth_flows(oauth_state)` 저장 → 제공자 로그인 화면으로.
3. 제공자 → `https://auth.talkverse.uk/callback/<provider>?code&state` → Worker 가 제공자 토큰 교환·사용자 정보 확인 → 계정 찾기/만들기(아래) → 교환 코드(2분, 한 번만) 발급 → `talkverse.th://auth?code=<교환 코드>` 로 되돌림.
4. 앱이 `POST /token {grant_type:"authorization_code", code, code_verifier, client_id}` → access·refresh 받음.

웹: 1번의 `client_id=web&redirect_uri=https://talkverse.uk/auth/done`(PKCE 없이 state 만) → 3번에서 교환 코드 대신 **`tv_sid` 쿠키를 심고** redirect_uri 로 보낸다(`auth.talkverse.uk` 와 `talkverse.uk` 는 같은 사이트라 `Domain=.talkverse.uk` 쿠키가 바로 통한다).

**계정 찾기/만들기** (Postgres 가입 트리거 `tv_handle_new_user` 대신):
1. `identities(provider, provider_uid)` 가 있으면 그 계정.
2. 없고, 제공자가 **확인된 이메일**을 줬고(Google `email_verified`, Kakao `is_email_verified`), 같은 확인된 이메일의 계정이 있으면 → 그 계정에 로그인 수단 추가.
3. 아니면 새 계정 + 로그인 수단. 이름은 제공자 이름 → 이메일 앞부분 순.

**이메일** — 비밀번호 + 이메일 확인 코드.
- 가입: `POST /email/start {email, client_id}` → 6자리 코드 메일(10분, 5회 틀리면 무효) → `POST /email/verify {email, code, password?, …}` → 계정·로그인 수단 → 앱은 access·refresh, 웹은 쿠키.
- 로그인: `POST /email/login {email, password, client_id}`. 비밀번호 재설정도 같은 코드 메일로.
- 비밀번호 해시: **PBKDF2-SHA256 (WebCrypto, 반복 횟수는 시험 후 확정)**. 기존 Supabase 이메일 회원 3명의 비밀번호 해시는 **옮기지 않았다**(2026-10-26 내보내기에서 뺌 — 비밀번호 값 규칙). 이 3명은 첫 로그인 때 이메일 코드로 비밀번호를 새로 정한다(그중 1명은 Google 로도 로그인 가능).
- 메일 발송 수단이 필요하다 — **결정 필요**(3번 항목).
- 로그인 시도 제한: 이메일·IP 별 분당 횟수(D1 카운터 또는 Workers Rate Limiting).

**Apple** — App Store 는 Google·Kakao 같은 외부 로그인을 넣은 iOS 앱에 **Sign in with Apple 을 함께 요구**한다(심사 지침 4.8). 표에는 `apple` 을 넣어 두었고, iOS 출시 전에 경로를 더한다.

### 2-5. `talkverse-auth` API (`https://auth.talkverse.uk`)

| 경로 | 쓰는 쪽 | 하는 일 |
|---|---|---|
| `GET /oauth/<provider>/start` | 앱·웹 | 로그인 시작(2-4) |
| `GET /callback/<provider>` | 제공자 | OAuth 콜백. 제공자 콘솔에 등록할 주소 |
| `POST /token` | 앱 | `authorization_code`(교환 코드 → 토큰) · `refresh_token`(갱신) |
| `POST /email/start` · `/email/verify` · `/email/login` · `/email/reset` | 앱·웹 | 이메일 가입·로그인·재설정 |
| `POST /logout` | 앱·웹 | 지금 세션 끊기(앱: refresh 토큰, 웹: 쿠키 지움) |
| `GET /me` · `PATCH /me` | 앱·웹 | 프로필 읽기·고치기(`display_name` `gender` `country` `ui_lang` `marketing_ok`) |
| `GET /me/entitlements` | 앱·웹 | `[{lang, ends_at, plan_id, source}]` — Supabase `tv_my_entitlements` 와 같은 모양 |
| `GET /me/access?lang=th` | 앱·웹 | `{lang:"th", ok:true, ends_at}` — `tv_has_access` 대신 |
| `GET /me/sessions` · `DELETE /me/sessions/<id>` | 앱·웹 | 로그인 기기 목록·끊기 |
| `DELETE /me` | 앱·웹 | 탈퇴(스토어 심사 요구). 계정 `status='deleted'` + 개인정보 지움. 학습 데이터는 `talkverse-api` 가 같이 지움 |
| `GET /plans` | 앱·웹 | 판매 중 상품·요금제(로그인 불필요) |
| `POST /session/verify` | **다른 Worker 전용**(서비스 바인딩 `AUTH`) | 아래 |
| `GET /.well-known/jwks.json` | 다른 Worker | access JWT 공개 키 |
| `POST /admin/subscriptions` 등 | 관리 키 | 구독 수동 부여·회수 |
| `POST /webhooks/<channel>` | 결제 채널 | 나중에(결제 붙일 때) |

**`POST /session/verify`** — 사이트·다른 Worker 가 서비스 바인딩으로만 부른다(공개 주소에서는 404).
- 요청: `{ "cookie": "<tv_sid 값>" }` 또는 `{ "bearer": "<access JWT>" }`, 선택 `"lang": "th"`.
- 응답 200:
  ```json
  { "ok": true,
    "user": { "id": "…", "display_name": "…", "email": "…", "ui_lang": "ko", "market": "kr" },
    "session": { "id": "…", "kind": "web", "expires_at": "…" },
    "entitlements": [ { "lang": "th", "ends_at": "…", "plan_id": "lang_th_y", "source": "admin" } ],
    "access": true }
  ```
  `access` 는 `lang` 을 줬을 때만. 세션이 없거나 끝났으면 `{ "ok": false, "reason": "no_session" | "expired" | "revoked" }`(200, 사이트는 비로그인으로 처리).

**구독 → 언어 펼치기**(Postgres `tv_entitlements` 대신, Worker 함수 하나): 그 사용자의 구독 중 `status in (active, grace)` 이고 `ends_at > 지금` 인 것 → 요금제 → 상품. `kind=all` 이면 언어 20개 전부, 아니면 `langs`. 언어마다 가장 늦은 `ends_at`.

**CORS**: `Access-Control-Allow-Origin` 은 `https://talkverse.uk` · `https://www.talkverse.uk` 만 명시(`*` 금지) + `Allow-Credentials: true`. 앱은 브라우저가 아니라 CORS 무관.

**쿠키 쓰는 쪽의 CSRF**: 쿠키로 바꾸는 요청(`PATCH /me`, `POST /logout` 등)은 `Origin` 이 위 두 주소인지 확인한다.

### 2-6. `talkverse-db` (공용 학습 데이터) 첫 표

```sql
-- 내 코스 질문 답 — 사용자 × 언어 한 벌. 최신 updated_at 이 이긴다
create table course_answers (
  user_id text not null, lang text not null, answers text not null, updated_at text not null,
  primary key (user_id, lang)
);
-- 내 코스 완료 회차 — 합집합 동기화
create table course_progress (
  user_id text not null, lang text not null, script_key text not null, done_at text not null,
  primary key (user_id, lang, script_key)
);
-- 앱이 따로 맞추고 싶은 작은 값(설정·진도 요약 등) — 새 표를 만들기 전의 공용 칸
create table user_state (
  user_id text not null, lang text not null, key text not null, value text not null, updated_at text not null,
  primary key (user_id, lang, key)
);
-- 개발자 메모 — 모든 언어앱 공용
create table dev_notes (
  id integer primary key autoincrement, created_at text not null,
  user_id text not null, lang text not null, app_build integer, platform text, screen text,
  context text not null default '{}',
  note text not null check (length(note) between 1 and 4000),
  shot_key text,                                 -- R2 talkverse-files 의 dev-notes/<lang>/<user_id>/<파일>
  status text not null default 'open' check (status in ('open','doing','done','wontfix')),
  resolution text, resolved_at text
);
create index dev_notes_open on dev_notes(status, created_at desc);
create index dev_notes_user on dev_notes(user_id, lang);
```

다른 언어앱이 단어 복습 기록 같은 큰 데이터를 올릴 때는 `user_state` 에 넣지 말고 `lang` 열을 가진 표를 이 DB 에 더한다(표 이름에 언어를 붙이지 않음).

**`talkverse-api` Worker**(제안 — 지침 3 "앱마다 Worker 하나" 는 DB 가 하나로 합쳐졌으니 Worker 도 하나로). 모든 경로 `Authorization: Bearer <access>` → JWKS 로 확인 → `sub` 의 행만:

| 경로 | Supabase 때 |
|---|---|
| `GET/PUT /v1/<lang>/course/answers` | `tv_course_answers` select·upsert |
| `GET/POST /v1/<lang>/course/progress` | `tv_course_progress` select·upsert |
| `GET/PUT /v1/<lang>/state/<key>` | (새것) |
| `POST /v1/<lang>/dev-notes`(본문 JSON + 캡처 png/jpeg 5MB 이하, multipart) · `GET /v1/<lang>/dev-notes/mine` | `tv_dev_notes` insert·select + 버킷 `dev-notes` |
| `POST /v1/admin/dev-notes/<id>/resolve` (관리 키) | Claude 세션의 `update … set status='done'` |

`<lang>` 이 토큰의 `aud` 와 다르면 거부(태국어앱 토큰으로 중국어 데이터를 못 고치게). 이용권이 필요한 경로가 생기면 JWT 의 `ent` 로 판단.

### 2-7. Supabase 에서 옮기기 — **내보내기 끝(2026-10-26)**, 적재는 요금제 결정 뒤

| Supabase | → |
|---|---|
| `auth.users`(5) + `tv_profiles`(5) | `users`(id 그대로, 이메일 확인 여부 포함) |
| `auth.identities`(6: email 3 · google 3) | `identities` — `password_hash` 는 비움(위) |
| `tv_products`(8) · `tv_plans`(16) | `products` · `plans`(`langs` → JSON, 달러 → 센트) |
| `tv_subscriptions`(1) · `tv_orders`(0) | `subscriptions` · `orders` |
| `tv_course_answers`(0) · `tv_course_progress`(1) | `talkverse-db` `course_*`(`app_lang` → `lang`) |
| `tv_dev_notes`(0) · 버킷 `dev-notes`(0) | 옮길 것 없음 |

세션은 옮기지 않는다 — 모든 사용자가 한 번 다시 로그인.

**원본 보관 — R2 `supabase-archive/talkverse/<표>.json`**(사용자 지시 "데이터 보관도 Cloudflare 로", 비공개 버킷, 2026-10-26): `auth_users`(5, 비밀번호 해시 제외)·`auth_identities`(6)·`tv_` 9개·`items`(24,459)·`etymon`(141)·`user_stats`·`daily_counts`·`user_progress` — 16개 파일. items.json 크기 대조 일치.

**적재용 파일 — PC `D:\backup\supabase_talkverse_20261026\`**(회원 이메일이 들어 있어 리포·맥에 두지 않음):
- `tv_accounts_and_legacy_user.json` — `auth.users`(5, 비밀번호 해시 제외) · `auth.identities`(6) · `tv_` 표 9개 전부 · 옛 언어앱 `user_stats`(1)·`daily_counts`(9)·`user_progress`(7)·`etymon`(141).
- `talkverse_accounts_seed.sql`(clients 21 · users 5 · identities 6 · products 8 · plans 16 · subscriptions 1) · `talkverse_db_seed.sql`(course_progress 1) — D1 에 그대로 넣는 INSERT. `acc_schema.sql`·`db_schema.sql`(이 문서의 스키마, clients 를 맨 앞으로) 와 함께 로컬 SQLite 로 적재 시험 통과.
- 적재: `npx wrangler d1 execute talkverse-accounts --remote --file acc_schema.sql` → `--file talkverse_accounts_seed.sql`, `talkverse-db` 도 같은 순서.

**옛 Talkverse 언어앱(`~/talkverse/_legacy`) 데이터**:
- `user_stats`·`daily_counts`·`user_progress` 는 운영자 계정 1명의 시험 기록(17행) — **보관만**(위 JSON), 새 DB 로 옮기지 않음.
- `etymon`(어원 141행) — 콘텐츠, **보관만**(위 JSON).
- `items`(24,459행 · 12MB, 언어 17개: ru 6,682 · vi 3,086 · fr 3,005 · es 2,864 · id 2,406 · mn 2,070 · th 1,572 · ms 1,498 · de 988 · lo 170 · 그 밖 7개 각 30행 미만) — 자체 제작 학습 문장·단어, 사용자 데이터 아님 → **보관만**(아래 R2). 행 수·id 중복 없음 확인.
- `tts` 버킷(3,622개 · 53MB) — Storage API 가 막혀 못 꺼냄. 로컬 원본은 몽골어 578개(`_legacy/mn/assets/audio`)뿐. 나머지 음성은 TTS 로 다시 만들 수 있는 것이라 잃어도 복구 가능.


### 2-8. 태국어앱 코드 바꿀 곳 (설계 확정 뒤)
- `backend.dart`: Supabase 값 → `authBase = https://auth.talkverse.uk`, `apiBase`, `clientId = 'th'`, 딥링크 `talkverse.th://auth`(AndroidManifest·Info.plist 같이 — 옛 `io.supabase.talkverse.th` 는 지움).
- `auth_service.dart`: `http` + `flutter_secure_storage`. 공개 메서드(`signInWithGoogle`·`signInWithKakao`·`refreshAccess`·`syncCourse`·`pushDone`·`pushAnswers`)와 `user`·`hasAccess` 알림은 그대로 둬 화면 코드가 안 바뀌게. 401 이면 refresh 한 번 → 실패하면 로그아웃 상태.
- 이메일 로그인 화면 새로(지금 앱에는 없음).
- `dev_notes.dart`: `_send`·`mine` 만 HTTP 로.
- `pubspec.yaml`: `supabase_flutter` 빼고 `flutter_secure_storage` 넣기.
- `CLAUDE.md` §8·§9 를 새 방식으로.

### 2-9. 순서
1. (결정) 요금제 · 메일 발송 수단 · 아래 3번 항목.
2. 사용자: `auth.talkverse.uk` 커스텀 도메인 · Google/Kakao 콘솔에 콜백 `https://auth.talkverse.uk/callback/<provider>` 등록 · 시크릿(OAuth 클라이언트 비밀값, JWT 개인 키, 메일 키) `wrangler secret put`.
3. D1 `talkverse-accounts`·`talkverse-db` 생성 · 스키마 · `clients`·`products`·`plans` 초기값.
4. `talkverse-auth` → 웹(talkverse.uk)·앱 순으로 시험. `talkverse-api`.
5. Supabase 데이터 옮기기(2-7).
6. 태국어앱 코드 교체 → 빌드 → Zealot·폰 확인. 다른 언어앱·talkverse.uk 가 이어서.
7. Supabase `tv_` 표(행 36개 · 304 kB)·`dev-notes` 버킷(0개) 삭제는 사용자에게 보고하고 사용자가 실행.

## 3. 결정이 필요한 것
1. **Workers 요금제** — 비밀번호 해시(PBKDF2)는 CPU 를 많이 쓴다. 무료(요청당 CPU 10ms)로는 넘칠 수 있어 이메일 로그인은 유료(요청당 30초) 전제가 안전.
2. **메일 발송 수단**(이메일 가입 코드·비밀번호 재설정) — Cloudflare 의 메일 발송 기능을 이 계정에서 쓸 수 있는지, 아니면 외부 발송 서비스(키는 Doppler)로 할지.
3. **Naver 로그인** 을 1차에 넣을지(설계상 Google·Kakao 와 같은 방식이라 콘솔 등록만 더하면 됨).
4. iOS 출시 시점 — 그 전에 Sign in with Apple 을 더해야 함(Apple Developer 에 Services ID 등록 필요).
