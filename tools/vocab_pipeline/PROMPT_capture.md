You are transcribing photographed pages of a Korean→Thai vocabulary glossary (단어장) from a Korean phrasebook. Each photo is a two-page spread. Each page has 3 column-pairs; each entry consists of: Korean meaning (small black text, left), Thai word (red bold text, right), and a Hangul pronunciation reading (gray text under the Thai word, e.g. "파낙응아-ㄴ", "라-카", "야-께-왓"). Entries are sorted in Korean alphabetical order. Some entries list two Thai variants separated by "/" — keep them joined as "A / B" and readings likewise "a / b". Sometimes an entry spans two lines; merge it. Ignore the vertical section tabs on the right edge (기본회화/맛집/쇼핑 etc.) and page numbers.

For EACH image, read it with the Read tool, then transcribe carefully column by column (left page: column 1, 2, 3 top-to-bottom; then right page: column 1, 2, 3), transcribing EVERY entry — typically 90–130 entries per spread. Be meticulous with Thai spelling (tone marks ่ ้ ๊ ๋, vowels ะ ั า ิ ี ึ ื ุ ู เ แ โ ใ ไ ำ, ์ silent marks). Copy the Hangul reading exactly as printed, including hyphens and standalone jamo like ㄴ ㅁ ㅇ ㄱ ㅅ ㅂ and "(f)" markers.

Write the result for each image IMMEDIATELY after reading it (before reading the next image) with the Write tool as a UTF-8 JSON file at:
C:\Users\Johnjeon\talkverse\th\tools\vocab_pipeline\captures\<image basename>.json
with this shape:
{"image":"20260904_204333.jpg","pages":"182-183","entries":[{"ko":"가게 점원","th":"พนักงานของร้าน","reading":"파낙응아-ㄴ커-ㅇ라-ㄴ"}, ...]}
"pages" = the printed page numbers if visible, else "". If a spot is unreadable, still include the entry with your best reading and add "uncertain":true.
Do not skip entries — completeness is the priority. When done, reply with one line per image: filename → entry count, pages.

Images to process, in order:
