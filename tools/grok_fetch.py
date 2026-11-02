#!/usr/bin/python3
"""Grok 프로젝트 챗의 마지막 답을 그대로 저장(이미 끝난 답 다시 받기).  grok_fetch.py <url조각> <저장파일> [n=-1]
이미지 생성이 포함된 답은 grok_send 가 생성 중간에 저장할 수 있어, 끝난 뒤 이 스크립트로 다시 받는다. 이미지 주소도 뒤에 붙인다."""
import sys
import os
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9225')  # 이 세션 전용 Chrome(프로필 ~/chrome-grok-th, 사용자 지시 2026-11-02) — 공용 9222 를 쓰려면 GROK_CDP_PORT=9222
frag, dst = sys.argv[1], sys.argv[2]
n = int(sys.argv[3]) if len(sys.argv) > 3 else -1
c = g.CDP(g.tab(frag))
busy = c.ev("document.body.innerText.includes('작업 중') || document.body.innerText.includes('이미지 생성 중') || !![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
els = c.ev("[...document.querySelectorAll('.response-content-markdown')].map(e=>e.innerText)")
imgs = c.ev("[...document.querySelectorAll('.response-content-markdown')].map(e=>[...e.querySelectorAll('img')].map(i=>i.src))")
if not els: print('EMPTY'); sys.exit(1)
txt = els[n]
# 그림이 아직 data: 썸네일(흐린 자리표시)이면 생성 중 — assets.grok.com 주소가 될 때까지 BUSY 로 본다(2026-11-02 태국어 시트 건)
if imgs and imgs[n] and any(u.startswith('data:') for u in imgs[n]): busy = True
if imgs and imgs[n]: txt += '\n\n[images]\n' + '\n'.join(imgs[n])
open(dst, 'w', encoding='utf-8').write(txt)
print('BUSY' if busy else 'OK', len(txt), len(imgs[n]) if imgs else 0)
