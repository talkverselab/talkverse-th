#!/usr/bin/env python3
"""편 JSON 들 → 사용자 리뷰용 단일 HTML(폰 열람). python tools/review_html.py <출력.html> <편.json>..."""
import json, sys, html, datetime
from pathlib import Path
out = Path(sys.argv[1]); eps = [json.load(open(p, encoding='utf-8')) for p in sys.argv[2:]]
css = """body{font-family:-apple-system,'Noto Sans KR','Hiragino Sans',sans-serif;max-width:720px;margin:0 auto;padding:16px;background:#fff;color:#0a2540;line-height:1.5}
h1{font-size:20px}h2{font-size:17px;margin:28px 0 4px;color:#b77548}.meta{font-size:12px;color:#6b7c93;margin-bottom:12px}
.t{margin:10px 0;padding:10px 12px;border-radius:12px;background:#f6f8fb;border:1px solid #e6ebf1}.t.A{background:#fff7f0}
.sp{font-size:11px;color:#6b7c93}.ja{font-size:17px;font-weight:600}.rd{font-size:13px;color:#635bff}.ko{font-size:14px}
.ok{display:inline-block;font-size:11px;padding:1px 6px;border-radius:8px;background:#e6f4ea;color:#1b7f3b}.dr{display:inline-block;font-size:11px;padding:1px 6px;border-radius:8px;background:#fff1e0;color:#b77548}
.nav a{display:inline-block;margin:2px 6px 2px 0;font-size:12px;color:#635bff}
.rv{display:flex;gap:6px;margin-top:8px}.rv textarea{flex:1;min-height:38px;border:1px solid #cfd8e3;border-radius:8px;padding:6px 8px;font:inherit;font-size:14px;background:#fff;color:#0a2540;resize:vertical}
.rv button{border:0;border-radius:8px;padding:0 12px;background:#635bff;color:#fff;font-size:13px;cursor:pointer}.rv button.ok{background:#1b7f3b}.rv button.err{background:#b42318}
.rs{font-size:11px;color:#6b7c93;margin-top:2px}.ep{margin:0 0 6px}.ep textarea{min-height:46px}"""
parts = [f"<!doctype html><html lang=ko><head><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'><title>일본어 회화 리뷰</title><style>{css}</style></head><body>",
         f"<h1>일본어 회화 리뷰 시트</h1><div class=meta>갱신 {datetime.datetime.now():%Y-%m-%d %H:%M} · 턴마다 일본어 / 한글 독음 / 한국어 · 고칠 곳은 편 id·턴 번호로</div><div class=nav>"]
parts += [f"<a href='#{e['id']}'>{html.escape(e['title'])}</a>" for e in eps] + ['</div>']
for e in eps:
    tag = f"<span class=ok>통과 {html.escape(e['approved'])}</span>" if e.get('approved') else "<span class=dr>리뷰 대기</span>"
    sp = ' · '.join(f'{k}={v}' for k, v in e['speakers'].items())
    parts.append(f"<h2 id='{e['id']}'>{html.escape(e.get('emoji',''))} {html.escape(e['title'])} <small>{e['id']}</small></h2>"
                 f"<div class='rv ep'><textarea data-k='{e['id']}:all' placeholder='이 편 전체 리뷰 — 통과 / 다시 / 턴이 너무 짧다 등…'></textarea><button onclick=\"sv(this)\">저장</button></div><div class=rs data-s='{e['id']}:all'></div>"
                 f"<div class=meta>{tag}<br>{html.escape(e['scene'])}<br>{e['region']} · {e.get('register')} · 턴 {len(e['turns'])} · 반전 {e.get('twist')}턴 · {html.escape(sp)}</div>")
    for t in e['turns']:
        key = f"{e['id']}:{t['num']}"
        parts.append(f"<div class='t {t['speaker']}'><div class=sp>{t['num']} {t['speaker']}{' · '+t['at'] if t.get('at') else ''}</div><div class=ja>{html.escape(t['ja'])}</div><div class=rd>{html.escape(t.get('rd',''))}</div><div class=ko>{html.escape(t['ko'])}</div>"
                     f"<div class=rv><textarea data-k='{key}' placeholder='이 턴 리뷰…'></textarea><button onclick=\"sv(this)\">저장</button></div><div class=rs data-s='{key}'></div></div>")
    if e.get('review', {}).get('final'):
        parts.append(f"<div class=meta>최종: {html.escape(e['review']['final'])}</div>")
parts.append("""<script>
const API='https://talkverse.uk/api/review/ja';  // uk 세션이 여는 저장 API(POST {key,text,at} / GET → {key:{text,at}})
const LS='review_ja_v1';
function ld(){try{return JSON.parse(localStorage.getItem(LS)||'{}')}catch(e){return {}}}
function st(k,m,c){const el=document.querySelector(`[data-s="${k}"]`);if(el){el.textContent=m;}const b=document.querySelector(`[data-k="${k}"]`).nextElementSibling;b.className=c||'';}
function fill(d){for(const k in d){const t=document.querySelector(`[data-k="${k}"]`);if(t&&!t.value){t.value=d[k].text||'';const s=document.querySelector(`[data-s="${k}"]`);if(s)s.textContent='저장됨 '+(d[k].at||'');}}}
async function sv(btn){const ta=btn.previousElementSibling,k=ta.dataset.k,text=ta.value.trim(),at=new Date().toLocaleString('ko-KR',{hour12:false});
 const d=ld();d[k]={text,at};try{localStorage.setItem(LS,JSON.stringify(d))}catch(e){}
 st(k,'저장 중…','');
 try{const r=await fetch(API,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({key:k,text,at})});
  if(!r.ok)throw new Error(r.status);st(k,'서버 저장됨 '+at,'ok');}
 catch(e){st(k,'폰에만 저장됨 '+at+' (서버 연결 안 됨)','err');}}
(async()=>{fill(ld());try{const r=await fetch(API);if(r.ok){fill(await r.json());}}catch(e){}})();
</script></body></html>""")
out.write_text('\n'.join(parts), encoding='utf-8'); print(out, len(eps))
