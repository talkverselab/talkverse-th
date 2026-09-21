# Talkverse 회원 · 로그인 · 결제 · 이용권 — 설계 (2026-09-21)

> 모든 언어 앱(th·zh·ja·…)과 talkverse.uk 가 **Supabase 프로젝트 `Talkverse` 하나**를 쓴다.
> 표·함수는 `docs/sql/tv_accounts_billing.sql` (적용 완료, 마이그레이션 `tv_accounts_billing`).
> 세무조정(`taxadj_*`)·사이트 계정(D1)과는 다른 표다 — `tv_` 접두사만 Talkverse 것.

## 1. 한 사람 = auth.users 한 줄

- 어느 앱, 어느 채널에서 가입해도 `auth.users.id`(uuid) 하나. 앱은 이 id 로 프로필·답·진행·이용권을 본다.
- `tv_profiles` — 이름·성별·시장(`kr`/`global`)·표시 언어. 가입 트리거가 자동 생성.
- `tv_identities` — 로그인 수단(google·kakao·naver·email·apple). 한 사람이 여러 수단을 이어 붙일 수 있다(같은 이메일이면 Supabase 가 자동으로 같은 사용자에 붙인다 — Google·Kakao 는 이메일 제공, Naver 는 §2).

## 2. 로그인 수단 — 국내 3종, 해외 1종

| 수단 | 방식 | 준비할 것 |
|---|---|---|
| Google (국내·해외) | Supabase 내장 OAuth. 앱은 `signInWithOAuth(google, redirectTo: 딥링크)` → 브라우저 → 딥링크 복귀 | **이미 켜져 있음**(오너 계정이 google 로 가입돼 있음). Redirect URLs 에 앱별 딥링크 추가 |
| Kakao (국내) | Supabase 내장 OAuth(kakao) | Kakao Developers 앱 REST 키·Client Secret 을 Supabase Auth → Providers → Kakao 에 등록. 이메일 동의 항목 필요 |
| Naver (국내) | **Supabase 에 내장 제공자가 없다.** talkverse.uk Worker 가 Naver OAuth 를 처리하고, 이메일로 사용자를 만들거나 찾은 뒤 `auth.admin.generateLink(magiclink)` 의 `hashed_token` 을 딥링크로 앱에 넘김 → 앱이 `verifyOTP(type: magiclink)` 로 세션 획득. `tv_identities(provider='naver')` 는 Worker 가 기록 | Naver Developers 앱 Client ID/Secret → Worker 시크릿. Worker 경로 `/auth/naver/start?app=th` · `/auth/naver/callback` |
| Apple (해외 iOS) | Supabase 내장 OAuth(apple) | Google 로그인을 넣은 iOS 앱은 심사 규정상 Apple 로그인도 필요. TestFlight 단계에서 추가 |

딥링크 규칙: **앱마다 다르게** `io.supabase.talkverse.<iso>://login-callback/` (같은 스킴을 여러 앱이 쓰면 Android 가 앱 선택창을 띄운다). 웹은 `https://talkverse.uk/auth/callback`.
Supabase Auth → URL Configuration → Redirect URLs 에 전부 등록해야 한다(와일드카드 `io.supabase.talkverse.*://login-callback/` 가 되면 한 줄).

## 3. 이용권 — "무엇을, 언제까지"

```
tv_products  무엇         lang_th(태국어) · set_sea(태·베·인·미얀마) · set_cjk · all
tv_plans     기간·가격    lang_th_m(월) · lang_th_y(년) · … · all_y   + 스토어 SKU
tv_orders    결제 1건     채널(web_kr·web_global·google_play·app_store·admin)·금액·상태·원본
tv_subscriptions  유효 기간이 있는 권리   status·starts_at·ends_at·auto_renew·channel_ref
```

- **"이 사용자가 이 언어를 쓸 수 있나"는 함수 하나만 본다**: `tv_my_entitlements()` → `(lang, ends_at, plan_id, source)`, `tv_has_access('th')` → bool.
  세트·전체 상품은 여기서 언어별로 풀린다. 앱도 Worker 도 이 함수만 호출한다 — 요금제를 새로 만들어도 앱 코드는 안 바뀐다.
- 새 상품·요금제 = `tv_products`·`tv_plans` 에 행 추가. 1년 정기, 세트, 언어별 한 달, 전체 — 전부 같은 두 표.
- 무료 범위(로그인 없이/이용권 없이 볼 수 있는 것)는 **앱이 정한다**(예: 코스 첫 2편·문자·성조 무료). `tv_has_access` 가 false 면 잠금 화면 → 결제.

## 4. 결제 채널 4곳 → 전부 Worker 가 받아서 tv_orders·tv_subscriptions 에 쓴다

| 채널 | 결제 | 확인 경로 |
|---|---|---|
| 웹 국내 (talkverse.uk) | 토스페이먼츠/포트원 정기결제(빌링키) | 승인 콜백 → Worker `/api/tv/pay/kr/confirm` → 서버-서버 검증 → orders(paid) + subscriptions |
| 웹 해외 (talkverse.uk) | Stripe Checkout/Subscriptions | Stripe 웹훅 → Worker `/api/tv/pay/stripe/webhook` |
| Google Play (앱) | 인앱 정기결제 | 앱이 구매 토큰을 Worker `/api/tv/pay/google/verify` 로 보냄 → Play Developer API 검증. 갱신·해지는 RTDN(Pub/Sub) → Worker |
| App Store (앱) | 인앱 정기결제 | 앱이 영수증/트랜잭션을 `/api/tv/pay/apple/verify` → App Store Server API 검증. 갱신·해지는 Server Notifications V2 → Worker |
| 관리자 | 수동 부여(체험·보상) | talkverse.uk 관리자 화면 → `/api/tv/admin/grant` |

- Worker 는 **service role 키**로 Supabase 에 쓴다(앱은 anon 키, 본인 행 읽기만). 앱에서 직접 `tv_subscriptions` 를 쓸 수 없다(RLS).
- 스토어 규정: 앱 안에서 디지털 상품을 팔면 그 스토어 결제를 써야 한다. 웹 결제 유도 문구를 앱에 넣지 말 것(한국은 2022년 법 개정으로 외부 결제 고지 가능하지만 수수료 차이가 작다).
- 같은 사용자가 두 채널에서 겹쳐 사면 `tv_entitlements` 가 `max(ends_at)` 로 합친다 — 손해는 없고 환불 처리는 관리자가.

## 5. 앱에 붙일 때 (다음 단계)

1. `supabase_flutter` + `app_links`. `Supabase.initialize(url, anonKey)` — url·anon 키는 공개 가능(RLS 가 지킨다). 서비스 키는 절대 앱에 넣지 않는다.
2. 프로필 화면: 「로그인」 타일(Google · Kakao · Naver 버튼; `market` 이 global 이면 Google 만) / 로그인 후 이름·이용권 표시.
3. 로그인하면 `tv_course_answers`·`tv_course_progress` 를 서버와 맞춘다(서버 updated_at 이 새로우면 내려받고, 아니면 올린다). 오프라인은 지금처럼 폰 저장.
4. 잠금: `tv_has_access(appLang)` 를 앱 시작 때 한 번 + 하루 한 번 확인, 결과를 폰에 저장(오프라인 유예 7일).
5. 다른 앱 15개는 `_update_kit` 으로 같은 코드 배포(딥링크 스킴만 앱별).

## 6. 지금 DB 에 들어 있는 것

- 상품 8개(태·중·일·베·한 + 동남아 세트 + 한중일 세트 + 전체), 요금제 16개(월/년) — **가격은 자리표시 값**, 확정되면 UPDATE.
- 오너 계정(`talkverse.lab@gmail.com`)에 `all_y` 1년 이용권(channel=admin, ref=owner-test) — 앱 테스트용.
- 기존 사용자 4명 프로필·로그인 수단 채워 넣음.
