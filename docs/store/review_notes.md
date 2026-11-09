# 심사 메모 · 앱 개인정보 답 · 개인정보처리방침 추가 문안 — 태국어유니버스 (2026-11-02)

> 한자 앱 `docs/store/review_notes.md`·`data_safety.md`(빌드 46~50 검증)를 태국어앱 사실에 맞춰 옮긴 것.
> 1.0 = Talkverse ID 로그인(선택) + 인앱 구입(가격표 2026-11-09: 언어 1m·3m·1y 구독·평생, 종합 1y·평생). 4.3 대비 차별화 문단은 `store_listing.md`. **아직 잠근 콘텐츠는 없다** — 무료/유료 구간이 정해지면 [인앱 구입] 줄의 "어디서 사는지"를 고칠 것.
> 데모 계정 비밀번호는 Doppler `TALKVERSE_REVIEW_ACCOUNT` 에만 있다 — 이 문서에 적지 말 것.

## App Store Connect "심사 정보 → 메모"

```
[로그인] 로그인은 선택입니다. 모든 학습 기능은 로그인 없이 사용할 수 있고, 로그인은 구매 복원·기기 간 이용권 공유·학습 진도 동기화에만 쓰입니다.
- 로그인 화면: 프로필 탭 → 계정 → 로그인. Apple로 로그인 + 이메일 로그인(심사·테스트용).
- 데모 계정(이메일 로그인): review@talkverse.uk / 비밀번호: <Doppler 에서 복사해 여기 입력>
- 계정 삭제: 프로필 탭 → 계정 → 계정 삭제(확인 창) → 서버에서 개인정보와 학습 동기화 데이터가 삭제되고 모든 기기에서 로그아웃됩니다.
[인앱 구입] 자동 갱신 구독 lang_th_1m·lang_th_3m·lang_th_1y, 비소모성 lang_th_life(서비스 운영 기간 동안), 종합 패키지 all_1y(구독)·all_life. 프로필 탭 → 계정 → [이용권 보기] → 상품 선택 → [구매], [이전 구매 복원]. 결제 시트에 기간·자동 갱신·해지 방법·약관·개인정보처리방침이 있습니다. Sandbox 계정으로 시험할 수 있고, 로그인 없이도 구매·복원이 됩니다.
[마이크·음성 인식] "문장 말하기"에서만 발음을 녹음해 판정합니다(사용자가 버튼을 누를 때만).

[Sign-in] Optional. Every learning feature works without an account; sign-in is only for restoring purchases, sharing the pass across devices and syncing study progress.
- Where: Profile tab → Account → Sign in (Sign in with Apple, or email sign-in for review/testing).
- Demo account (email sign-in): review@talkverse.uk / password: <paste from Doppler>
- Account deletion: Profile tab → Account → Delete account (confirmation) → personal data and synced study data are deleted server-side and all sessions are revoked.
[IAP] Auto-renewable subscriptions lang_th_1m · lang_th_3m · lang_th_1y, non-consumable lang_th_life (for as long as the service runs), bundle all_1y (subscription) · all_life. Profile tab → Account → [View passes] → choose → [Buy], or [Restore purchases]. The sheet shows period, auto-renewal, how to cancel, Terms and Privacy Policy. Works with a Sandbox account; sign-in is not required.
[Microphone / speech recognition] Used only in "Sentence speaking" to check pronunciation, when the user taps record.
```

## App Store "앱 개인정보 보호" 답
- 데이터 수집: **예**(로그인·구매한 사용자만). 모두 "사용자와 연결됨", 추적 아님.
  - 연락처 정보 → 이메일 주소(계정 관리)
  - 연락처 정보 → 이름(로그인 제공자가 주는 범위, 선택)
  - 식별자 → 사용자 ID(Talkverse 계정 ID)
  - 구매 → 구매 내역(이용권 복원)
  - 사용자 콘텐츠 → 기타(코스 질문 답·완료 회차 동기화, 개발자 메모 — 로그인한 사용자만)
- 수집하지 않음: 위치·건강·금융(카드 정보는 Apple/Google 이 처리)·광고·진단·검색 기록. 추적(ATT) 없음.

## Google Play 데이터 보안 답
- 수집: 예 — 이메일 주소·이름(계정 관리, 선택), 사용자 ID, 구매 내역, 앱 활동(학습 진도 동기화, 로그인 시). 전송 암호화 예.
- **사용자가 삭제 요청 가능: 예** — 앱 안 "계정 삭제" + 웹 안내 https://talkverse.uk/account/delete
- 공유: 없음(결제 처리는 Google Play). 광고 없음.

## 개인정보처리방침에 추가할 문안(talkverse.uk 세션 반영 요청)
```
계정(선택)
태국어유니버스는 로그인 없이 쓸 수 있습니다. Talkverse 계정으로 로그인하면 다음을 처리합니다.
- 수집 항목: 이메일 주소, 이름(로그인 제공자가 전달하는 범위), 계정 ID, 로그인 시각·기기 식별 토큰, 학습 진도(코스 답·완료 회차)·개발자 메모.
- 목적: 로그인 유지, 구매(평생 이용권) 복원과 기기 간 공유, 학습 진도 동기화, 고객 문의 응대.
- 보관: 계정 삭제 시 즉시 삭제(구매·주문 기록은 관계 법령에 따라 회계 목적으로 사용자 ID 만 남깁니다).
- 삭제 방법: 앱 → 프로필 → 계정 → 계정 삭제. 또는 talkverse.lab@gmail.com 으로 요청.
- 처리 위탁·국외 이전: 계정 서버는 Cloudflare(미국 등 글로벌 리전)에서 운영됩니다.

결제
평생 이용권 결제는 Apple App Store 또는 Google Play 가 처리하며, 앱은 카드 정보를 받지 않습니다. 앱은 구매 영수증(거래 번호·상품 ID)만 확인해 이용권을 적용합니다.
```

## 사용자가 할 일(한 번만)
1. 개발자 포털 → App ID `com.talkverse.thaiUniverse` → **Sign in with Apple** capability 켜기(명령줄 자동 서명으로는 안 켜짐), Services ID 는 "Group with existing primary".
2. App Store Connect 인앱 구입 비소모성 `com.talkverse.thaiUniverse.lifetime` 등록(가격 확정 — 앱 참고가 ₩14,900), Play Console 일회성 상품 `lang_th`.
3. 데모 계정 review@talkverse.uk 에 이용권 `th` 부여 — talkverse.uk 세션에 요청.
