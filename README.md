# 태국어유니버스 (thai_universe)

> 한국 화자용 태국어(방콕) 학습 앱
> Flutter · `zh`(중국어)·`vi`(베트남어) 앱 구조를 참고해 구축

---

## 한 줄 정리

한국 화자 → 태국어. **Flutter** 단일 앱. 디자인은 **방콕 모던** 스타일(난초 마젠타 + 사프란 골드 + 트로피컬 틸).

---

## 구현된 기능

| 메뉴 | 화면 | 내용 |
|------|------|------|
| 홈 | `home_screen.dart` | 방콕(왓 아룬/차오프라야) 무드 히어로 배너 + 기능 그리드 |
| 알파벳 | `alphabet_screen.dart` | 자음 44자(고·중·저 분류별) + 모음(단·장) 탭, 글자별 상세 시트 |
| 자음 3분류 | `consonant_class_screen.dart` | 고(สูง)·중(กลาง)·저(ต่ำ) 심화 — 구성·암기·성조 연결 |
| 성조 | `tones_screen.dart` | 5성조 곡선 그래프, 성조부호 4개, **자음 분류별 성조 규칙표** |

- **한자 메뉴 없음** (태국어는 표음문자라 불필요)
- 성조 연습 UI/모델은 `vi` 앱의 성조 화면 구조를 참고

---

## 폴더 구조

```
th/
├── lib/
│   ├── main.dart
│   ├── core/theme.dart              ← 방콕 모던 팔레트
│   ├── data/
│   │   ├── models/                  alphabet.dart, tone.dart
│   │   └── repositories/            alphabet/tone JSON 로더(캐싱)
│   └── screens/                     home, alphabet, consonant_class, tones, main
├── assets/data/
│   ├── alphabet/th_alphabet.json    자음 44 + 모음 25
│   └── tones/th_tones.json          5성조 + 부호 4 + 규칙표 3행
├── android/ · ios/ · web/
└── pubspec.yaml
```

---

## 데이터 메모

- **자음 44자**: 중자음 9 / 고자음 11 / 저자음 24. ฃ·ฅ는 폐자(廢字)지만 전통적 44자에 포함.
- **성조 규칙**: `자음 분류 × 모음 길이 × 받침 종류 × 성조부호 → 성조`. 규칙표는 평음절/사음절(단·장)/ไม้เอก/ไม้โท 5열.
- 발음(`ko`)·로마자는 **방콕 표준 근사** 표기. `audio` 필드는 비어 있으며 합성(TTS) 후 채울 예정.

---

## 빌드/실행

```bash
flutter pub get
flutter test          # 스모크 테스트
flutter run           # 디바이스/에뮬레이터
flutter build web     # 웹 빌드 (검증 완료)
```
