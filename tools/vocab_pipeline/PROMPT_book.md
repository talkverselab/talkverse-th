You are converting noisy OCR Markdown of a Korean-published Thai vocabulary book ("나혼자 끝내는 태국어 단어장", 30 days/일차) into clean structured JSON. Work in C:\Users\Johnjeon\talkverse\th\tools\vocab_pipeline\book\. Process the listed files IN ORDER, one at a time, writing each output JSON BEFORE reading the next file (checkpointing — the environment may disconnect).

Book structure per 일차 (day): a title page with "วันที่ NN <theme>", an MP3 preview table of a few words, then the MAIN numbered entries (3-digit numbers, continuing across the whole book up to ~411) each with: Thai headword, Hangul reading (e.g. "바-ㄴ", "뜨-ㄴ 뗀"), Korean meaning, and an example sentence (Thai, its Hangul reading, Korean translation). The example often has "[blanked out text]" or "□ □ □" or "^" where the headword was blanked for practice — restore the headword in ex_th where obvious. Then a "플러스 단어" section: extra words (Thai / meaning / reading), sometimes grouped by sub-topic. Then a "미니 테스트" (quiz) — SKIP quizzes entirely. OCR noise: tables with "<br>", stray "r"/"y"/"f"/"n" letters appended to Hangul readings (keep them as printed), "ครับ(ค่ะ)" polite endings inside examples (keep), page footers like "วันที่ 08 감정과 느낌 표현 57" (ignore), page numbers (ignore). Day 30 may be followed by the book's back matter / alphabetical index — do NOT transcribe an index, only real vocabulary sections.

Output JSON shape (UTF-8, ensure_ascii=false), file name dayNN.json next to dayNN.md:
{
 "day": 12, "theme": "우리집",
 "entries": [
  {"kind":"main","day":12,"num":146,"th":"บ้าน","reading":"바-ㄴ","ko":"집","ex_th":"จากบ้านถึงโรงเรียนไม่ไกลครับ(ค่ะ)","ex_reading":"짜-ㄱ 바-ㄴ 틍 로-ㅇ리-얀 마이 끌라이 크랍 카","ex_ko":"집에서 학교까지 멀지 않아요."},
  {"kind":"plus","day":12,"group":"침실","th":"หมอน","reading":"머-ㄴ","ko":"베개"}
 ]
}
Rules: "th" must contain only the Thai headword (no numbers, no Korean). "reading" is the Hangul reading as printed (trim; keep hyphens/jamo). If a field is truly absent, use "". Add "uncertain":true when OCR is garbled and you had to guess. Keep entry order as in the book. Do not drop entries; a day typically has 13–18 main entries and 20–60 plus words. Use Read for the md and Write for the json. When finished, reply with one line per file: filename → main count / plus count, theme.

Files to process, in order:
