#!/usr/bin/python3
"""편 내용을 짧게 보여 준다(감정 계획 작성용). python3 tools/tts/show_ep.py <편id>..."""
import json, glob, sys, os
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
for ep in sys.argv[1:]:
    p = glob.glob(f'{R}/assets/data/dialogues/*/*/{ep}.json')[0]
    d = json.load(open(p, encoding='utf-8'))
    print(f"\n## {ep} | {d['title']} | {d['scene']} | {d['speakers']} | {d.get('register')} | kind={d.get('kind')}")
    for t in d['turns']:
        print(t['num'], t['speaker'], t['th'], '||', t.get('rd', ''), '||', t['ko'])
