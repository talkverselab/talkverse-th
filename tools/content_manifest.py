"""assets/data/content_manifest.json 생성 — 앱이 APK 없이 받아 갈 콘텐츠 목록과 sha1.

version = 만든 시각(분 단위 정수). 앱은 원격 version 이 자기 것보다 크면 sha1 이 바뀐 파일만 받는다.
대상 파일을 늘리려면 FILES 에 추가하고, 앱에서 그 파일을 ContentStore.loadString 으로 읽게 할 것.
"""
import hashlib
import io
import json
import os
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = [
    "assets/data/course/questions.json",
    "assets/data/course/scripts_th.json",
    "assets/data/grammar/lessons.json",
    "assets/data/grammar/sfp.json",
]
OUT = os.path.join(ROOT, "assets", "data", "content_manifest.json")


def main():
    files = {}
    for f in FILES:
        b = io.open(os.path.join(ROOT, f), "rb").read()
        files[f] = hashlib.sha1(b).hexdigest()
    old = {}
    if os.path.exists(OUT):
        old = json.load(io.open(OUT, encoding="utf-8"))
    if old.get("files") == files:
        print("content_manifest: 변경 없음 (version %s)" % old.get("version"))
        return
    ver = int(time.time() // 60)
    json.dump({"version": ver, "files": files}, io.open(OUT, "w", encoding="utf-8"), indent=1)
    print("content_manifest: version %d · 파일 %d" % (ver, len(files)))


if __name__ == "__main__":
    main()
