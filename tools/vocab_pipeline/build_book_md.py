r"""회화집 캡처 → Source_Books 용 한 권 MD 병합.

사용: python -X utf8 tools/vocab_pipeline/build_book_md.py [--out PATH]
- pages/<img>.md   : 본문 스프레드(12~153쪽) 비전 전사 → 파일명(촬영 순) 순서로 이어붙임
- captures/<img>.json : 뒤쪽 단어장(158~207쪽) 비전 추출 → 스프레드별 표로 변환
결과 기본 경로: C:\Users\Johnjeon\Source_Books\01.04_동남아시아어\01.04.02.태국어\01.04.02.20.기타태국어\태국어여행회화_캡처본.md
"""
import glob
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = (r"C:\Users\Johnjeon\Source_Books\01.04_동남아시아어\01.04.02.태국어"
               r"\01.04.02.20.기타태국어\태국어여행회화_캡처본.md")
TITLE = "태국어여행회화_캡처본"


def esc(s):
    return (s or "").replace("|", r"\|").strip()


def body_pages():
    parts, pages, rows = [], [], 0
    for md in sorted(glob.glob(os.path.join(HERE, "pages", "*.md"))):
        txt = io.open(md, encoding="utf-8").read().strip()
        if not txt:
            continue
        pages += re.findall(r"<!-- PAGE ([^>]+) -->", txt)
        rows += sum(1 for l in txt.splitlines()
                    if l.startswith("|") and not re.match(r"^\|[\s|:-]+\|$", l) and "| 한국어" not in l)
        parts.append(txt)
    return "\n\n".join(parts), pages, rows


def glossary_pages():
    parts, n = [], 0
    files = sorted(glob.glob(os.path.join(HERE, "captures", "*.json")))
    for jf in files:
        d = json.load(io.open(jf, encoding="utf-8"))
        pg = d.get("pages") or ""
        parts.append(f"<!-- PAGE {pg or '?'} -->\n")
        parts.append("| 한국어 | 태국어 | 독음 |\n|---|---|---|")
        for e in d.get("entries", []):
            mark = " (?)" if e.get("uncertain") else ""
            parts.append(f"| {esc(e.get('ko'))}{mark} | {esc(e.get('th'))} | {esc(e.get('reading'))} |")
            n += 1
        parts.append("")
    return "\n".join(parts), n, len(files)


def main():
    out = DEFAULT_OUT
    if "--out" in sys.argv:
        out = sys.argv[sys.argv.index("--out") + 1]
    body, pages, rows = body_pages()
    gloss, n_gloss, n_spreads = glossary_pages()
    nums = [int(x) for p in pages for x in re.findall(r"\d+", p)]
    span = f"{min(nums)}~{max(nums)}" if nums else "?"
    head = [
        f"# {TITLE}",
        "",
        rf"> 출처: Desktop\태국어단어\*.jpg 스마트폰 캡처(본문 스프레드 {len(pages)//2 if pages else 0}장 + 단어장 스프레드 {n_spreads}장)"
        f" · 분류: 동남아시아어 · 방법: vision_capture(Claude) · 페이지: 본문 {span} / 단어장 158~207"
        " · 비고: 책명 미확인(표지 미촬영) — 기본회화·맛집·쇼핑·뷰티·관광·엔터테인먼트·호텔·교통수단·기본정보·단어장 구성의 한국어→태국어 여행회화집",
        "",
        "---",
        "",
    ]
    doc = "\n".join(head) + body + "\n\n---\n\n## 단어장 (한국어 가나다순 · 158~207쪽)\n\n" + gloss
    os.makedirs(os.path.dirname(out), exist_ok=True)
    io.open(out, "w", encoding="utf-8", newline="\n").write(doc)
    print(f"본문 페이지 {len(pages)}개(p.{span}), 표 행 {rows}개 / 단어장 {n_gloss}개({n_spreads} 스프레드)")
    print(f"→ {out} ({os.path.getsize(out):,} bytes)")


if __name__ == "__main__":
    main()
