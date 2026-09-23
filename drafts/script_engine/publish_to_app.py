"""초안 → 앱 에셋 복사. build_scripts.py 를 돌린 뒤 실행. (검수 전 초안이 그대로 들어간다 — 배포 전에 REVIEW 를 끝낼 것)"""
import io, json, os, shutil
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "..", "..", "assets", "data", "course")
os.makedirs(OUT, exist_ok=True)
q = json.load(io.open(os.path.join(D, "questions.json"), encoding="utf-8"))
for x in q["questions"]:
    x.pop("status", None)
json.dump(q, io.open(os.path.join(OUT, "questions.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
s = json.load(io.open(os.path.join(D, "scripts_th.json"), encoding="utf-8"))
for x in s["scripts"]:
    x.pop("changed", None)
json.dump(s, io.open(os.path.join(OUT, "scripts_th.json"), "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
import subprocess, sys
subprocess.run([sys.executable, os.path.join(D, "..", "..", "tools", "content_manifest.py")], check=True)
print("앱 에셋 갱신:", len(s["scripts"]), "편,", os.path.getsize(os.path.join(OUT, "scripts_th.json")) // 1024, "KB")
