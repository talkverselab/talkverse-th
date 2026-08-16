# 태국어유니버스 (thai_universe)

> 한국 화자용 태국어(방콕) 학습 앱
> Flutter · **`zh`(중국어유니버스) 앱 구조를 그대로 이식**하고 전체를 태국풍으로 재해석

---

## 한 줄 정리

한국 화자 → 태국어. **Flutter** 단일 앱 + **Drift**(SQLite).
디자인은 **방콕 모던**: 난초 마젠타(`#E6007E`) + 사원 골드 + 에메랄드 + 인디고, 라이타이(끄라녹) 문양, 코끼리 마스코트.

---

## 구조 (zh 미러)

4탭: **홈 / 학습 / 진행 / 프로필** + 홈 메뉴 그리드 9종.

| 메뉴 | 화면 | 내용 |
|------|------|------|
| 회화 (다이얼로그) | `conversation_screen` `episode_screen` | L1 스토리 3편(민호 & ฟ้า) + L2 카오스 챗 6편(Netflix 코퍼스). 채팅 버블·청크 탭·TTS·학습 체크 |
| 문자 44 | `alphabet_screen` | 자음 44(고·중·저) + 모음, 글자별 상세 시트 |
| 자음 3분류 | `consonant_class_screen` | 고(สูง)·중(กลาง)·저(ต่ำ) 심화 |
| 성조 5 | `tones_screen` | 5성조 곡선·성조부호·자음 분류별 성조 규칙표 |
| 어말조사 | `grammar_lesson_screen` | คำลงท้าย 12종 (นะ·ครับ·ค่ะ·ไหม…) — 코퍼스 실예문 |
| 단어 | `word_freq_screen` | Netflix 코퍼스 빈도 Top1000 (R1~R4 티어) |
| 문자 퀴즈 | `script_quiz_screen` | 자음 4지선다 10라운드 |
| **키보드연습** | `keyboard_practice_screen` | **Kedmanee 자판** — 다음 키 하이라이트(Shift층 포함), 자모→단어→문장 코스, 정확도 |
| 복습 | `flashcard_screen` `sentence_flashcard_screen` | 자음 카드 + 문장 플래시카드(한↔태 뒤집기, 남/녀 TTS) |
| 청크 검색 | `chunk_search_screen` | 태국어·로마자·한국어 검색 → 청크별 실전 문장 |

---

## 폴더

```
th/
├── lib/
│   ├── main.dart                    앱 진입 (DB 시딩)
│   ├── core/theme.dart              방콕 모던 팔레트 + 5성조·자음분류 컬러
│   ├── data/
│   │   ├── db/                      Drift: Turns·Words·UserProgress·LetterProgress·UserMemos
│   │   ├── models/ repositories/    alphabet·tone JSON 로더
│   ├── screens/                     main, conversation, episode, flashcard×2,
│   │                                alphabet, consonant_class, tones, grammar(SFP),
│   │                                script_quiz, keyboard_practice, word_freq,
│   │                                chunk_search, progress, profile
│   ├── services/                    tts(th-TH)·audio·memo·thai_dict(최장일치 분절)·chunk_index
│   └── widgets/                     thai_decor(금장 엠블럼·라이타이·쩨디), mascot(코끼리),
│                                    selectable_thai, today_mission, memo_toggle
├── assets/data/
│   ├── alphabet/th_alphabet.json    자음 44 + 모음
│   ├── tones/th_tones.json          5성조 + 부호 + 규칙
│   ├── dialogues/L1.json L2.json    스토리 3편 + 카오스 챗 6편
│   ├── wordsets/th_top1000.csv      코퍼스 빈도 상위 1000
│   ├── chunks/th_chunks.json        큐레이션 문장 2200
│   └── grammar/sfp.json             어말조사 12종 + 실예문 72
└── corpus/                          Netflix 원어 코퍼스 파이프라인 (원본)
```

---

## 태국어 특화 포인트

- **분절**: 태국어는 띄어쓰기가 없어 빈도 상위 단어 사전 **최장일치 분절**로 청크 탭/검색 구현 (`thai_dict_service`)
- **성조**: 중국어 4성 매트릭스 대신 **자음 분류(고/중/저) × 성조부호 규칙표** 체계 유지
- **한자 메뉴 없음** → 그 자리에 **태국 문자 44 스테이지 + 키보드연습**
- 마스코트: 판다 → **골드 장식 코끼리** (드래그·부유·감정 6종 순환)

## 빌드

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift 코드젠
flutter run
```
