# talkverse_pitch

발화 음높이(F0) 측정·성조 채점 공용 모듈. 순수 Dart(플랫폼 의존 없음) — 마이크 녹음은 앱이 하고 16kHz 모노 PCM 을 넘긴다.

```dart
final track = const PitchTracker().track(pcm16ToFloat(bytes));      // 10ms 단위 음높이
final r = scoreMandarinSequence(track, [1, 1], hanzi: ['今', '天'],   // 사전 성조(경성 0)
    speakerMedianHz: range.medianHz);                                // 그 사람 평소 음높이
r.passed;                 // 전부 통과?
r.syllables[i].verdict;   // good / close / off
r.method;                 // 'word'(두 음절 — 원어민 본보기와 견줌) / 'rules'(그 밖 — 음절별 특징)
r.syllables[i].tone?.heard, .hints;   // 어느 성조로 들렸나, 고칠 점(keep_level·end_higher·middle_lower·fall_more)
r.syllables[i].contour?.st;           // 겹쳐 그릴 곡선(평소 음높이 기준 반음, 20점)
```

- `surfaceTones` — 변조: 3+3 → 2+3, 반3성, 不+4성. 一 의 변조는 자료가 바뀐 성조로 적어 준다.
- `PitchTracker` — YIN 차이 함수에서 칸마다 골짜기 후보 5개를 뽑고, 이웃 칸과 음높이가 이어지는 길(무성 포함)을 골라 옥타브 튐·갈라지는 목소리를 줄인다.
- `splitSyllables` — 무성 자음의 끊김 → 이어 말해 소리가 안 끊겨도 음높이를 3반음 넘게 다시 올리는 곳(4성+4성 现在 등) → 세기 골 순으로 음절을 나눈다. 2~4음절용. 문장은 음절별 채점을 하지 않는다.
- `matchToneWord`·`judgeToneWord` — 두 음절 낱말: 낱말 전체 곡선(40점, 제 평균·제 폭으로 고르게 함 → 목소리 높낮이·오르내림 폭은 보지 않음)을 모듈에 든 본보기(`mandarinWordModel`)와 견줘, 목표 조합이 가장 닮은 조합의 0.75 이상이면 통과. 아니면 어느 음절이 어긋났는지 짚는다.
- `compareContoursWarped` — 문장: 기준 음성 곡선과 모양 비교(참고용 점수 + 겹쳐 보기).
- `SpeakerRange.fromHz` — 그 사람 음역(5·50·95 백분위). 녹음할 때마다 유성 칸을 모아 갱신해 저장한다. 없으면 그 발화의 가운뎃값으로 대신하지만 "전체가 높은지"는 못 가린다(1성+1성 낱말).
- `bin/contour.dart` — 기준 음성에서 곡선 자료 뽑기: `ffmpeg -v error -i a.mp3 -f s16le -ar 16000 -ac 1 - | dart run talkverse_pitch:contour 50`

## 두 음절 본보기 자료

- `lib/src/mandarin_word_data.dart` — `tool/build_model.dart <list.tsv> build` 가 만든다(손으로 고치지 말 것). 2026-11-11: 낱말 573개 × 합성 원어민 음성 12가지(본토 남녀 6, 대만 2, 그 밖 4)에서 본보기 5,688개 · 성조 조합 19(3-3 은 2-3 과 같은 꼴). 원본 wav·목록은 M6 `~/talkverse/talkverse-pitch-data/`(저장소 밖).
- 정확도(`build_model.dart <list.tsv> eval --each --same-word`, 음성 하나를 통째로 빼고 나머지로 판정, 좋음 0.75): 바르게 말한 낱말 통과 89.0% · 다른 조합을 목표로 했을 때 잘못 통과 22.7%(한 음절만 다른 목표 38.1%). 빠르고 음역이 좁은 남성 음성 둘은 통과 67~68%, 나머지는 87~98%. 처음 규칙 방식(5c01706)은 같은 자료에서 17%.
- 문턱은 `judgeToneWord(good:, close:)`. 0.8 로 올리면 통과 84% · 잘못 통과 18%, 0.7 로 내리면 91% · 28%. 판정은 참고용이라 너그러운 쪽으로 잡았다.
- 시도했지만 낫지 않은 것: 음절별로 잘라 견주기(`--align`), 본보기 수 k 1·5, 조용한 곡선 바닥 1.0·2.5, 작은 신경망 분류기(가장 닮은 조합 맞히기 48~51% — 본보기 견주기와 같은 수준).

한계: 본보기는 합성 원어민 음성이다. 실제 학습자 녹음(기기 마이크·잡음·느린 말)으로 다시 재야 한다. 세 음절 이상은 음절별 특징(`rules`)으로 판정한다. 곡선 겹쳐 보기는 보조 수단이다.

시험: `dart test` (합성음 — 2음절 20칸, 3·4음절, 틀린 음절 짚기, 이어 말한 4성+4성 나누기, 모듈에 든 본보기 점검, 문장 비교).
