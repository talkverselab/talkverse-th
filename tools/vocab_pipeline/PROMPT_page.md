You are transcribing photographed two-page spreads of a Korean travel phrasebook for Thai (태국어 여행회화집). Sections (tabs on the right edge): 기본회화, 맛집, 쇼핑, 뷰티, 관광, 엔터테인먼트, 호텔, 교통수단, 기본정보. Each spread shows a LEFT page and a RIGHT page; printed page numbers are at the bottom-left and bottom-right corners (e.g. 12 and 13).

Page contents: a big title line (e.g. "먼저 인사부터 시작해 봅시다."), an intro paragraph, sub-section pill labels (e.g. "식당에 들어갑니다", "주문해 봅시다"), dialogue entries consisting of Korean sentence / Thai sentence (red or dark-red bold) / Hangul reading (gray, e.g. "커-하이뻬-ㄴ완티-디-") / English line, reply bubbles (answers), "TIP" note boxes, "한마디 표현" boxes (short phrases: Korean / Thai / reading), "도움이 되는 단어장" mini glossaries (Korean / Thai / reading), grid tables (e.g. 때·시간 tables, unit conversion tables), photo captions and short explanatory paragraphs, and "참고 P.150"-style cross references.

For EACH image: read it with the Read tool, then write a faithful Markdown transcription with the Write tool (UTF-8) to
C:\Users\Johnjeon\talkverse\th\tools\vocab_pipeline\pages\<image basename>.md
IMMEDIATELY after reading that image, before reading the next one.

Markdown format (follow exactly):
- Start each physical page with a line `<!-- PAGE N -->` (N = printed page number; use the left page number then the right page number; if a number is not visible, infer from the neighbouring page).
- Title line → `## 제목`. Intro paragraph → plain text. Sub-section pill label → `### 라벨`.
- Dialogue/phrase entries → one Markdown table per sub-section with columns `| 한국어 | 태국어 | 독음 | 영어 |`. Reply/answer bubbles go in the same table with the Korean cell prefixed by `↳ ` (e.g. `↳ 15분 정도입니다.`). If the English line is absent leave the cell empty. Keep "A / B" alternatives joined with " / ".
- "한마디 표현" box → `#### 한마디 표현` followed by a table `| 한국어 | 태국어 | 독음 |`.
- "도움이 되는 단어장" box → `#### 도움이 되는 단어장` followed by a table `| 한국어 | 태국어 | 독음 |`.
- Word grids (e.g. 때/시간/요일/숫자 tables, labelled diagrams like the clock) → `#### 라벨` + table `| 한국어 | 태국어 | 독음 |`, one row per cell.
- Numeric conversion tables → transcribe as a Markdown table with the printed headers, values as printed.
- TIP / note boxes → blockquote: `> **TIP 제목**: 본문`.
- Photo captions / explanatory text / speech-bubble comments → plain paragraphs (italic for small captions is fine).
- Cross references like "참고 P.150" → append `(참고 P.150)` at the end of the relevant row's Korean cell.
- Ignore the vertical section tabs on the right edge, page furniture, and any mirrored bleed-through text from the reverse side.
- Escape `|` inside cells as `\|`.

Be meticulous with Thai spelling (tone marks ่ ้ ๊ ๋, vowels ะ ั า ิ ี ึ ื ุ ู เ แ โ ใ ไ ำ, silent mark ์) and copy Hangul readings exactly as printed, including hyphens and standalone jamo (ㄴ ㅁ ㅇ ㄱ ㅅ ㅂ). Do not translate or add anything that is not printed. Completeness is the priority: transcribe EVERY entry, box, caption and table on both pages. If something is unreadable, transcribe your best reading and mark it `(?)`.

When all images are done, reply with one line per image: filename → page numbers, number of table rows.

Images to process, in order:
