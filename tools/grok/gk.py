"""고정 방(tools/grok/room_th.txt)에서 Grok 한 건: gk.py <prompt> <out.md> [--attach m4path,..] [--img outdir] [--new]  — 끝나면 탭 닫음.
사용자 지시 2026-11-06: 새 방을 만들지 말고 한 방에서 이어 쓴다(통일성·토큰). --new 는 새 방이 꼭 필요할 때만. 포트 = GROK_CDP_PORT(기본 9226)."""
# 2026-11-05 tools/grok 로 옮김(/tmp 스크래치패드가 재부팅으로 지워져 복구) — 의존: ~/Hanja/tools/grok_cdp.py, 터널 9226(ssh -fN -L 9226:127.0.0.1:9226 macmini4)
import sys, time, json, base64, urllib.request, re, os
os.environ.setdefault('GROK_CDP_PORT','9226')
sys.path.insert(0,'/Users/talkverse/Hanja/tools'); import grok_cdp as g
a=sys.argv[1:]; src,dst=a[0],a[1]
att=a[a.index('--attach')+1].split(',') if '--attach' in a else []
imgdir=a[a.index('--img')+1] if '--img' in a else None
room=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'room_th.txt')).read().strip()
url='https://grok.com/' if '--new' in a else 'https://grok.com/c/'+room
t=json.load(urllib.request.urlopen(urllib.request.Request(g.BASE+'/json/new?'+url,method='PUT')))
try:
    time.sleep(10); c=g.CDP(t); c.call('Page.bringToFront')
    for _ in range(15):
        if c.ev("!!document.querySelector('.ProseMirror')"): break
        time.sleep(2)
    time.sleep(6)  # 기존 대화가 다 그려진 뒤 기준선을 잡는다
    IMGJS="[...document.querySelectorAll('img')].filter(e=>e.src.includes('/generated/')&&e.naturalWidth>300).map(e=>e.src)"
    MDJS="document.querySelectorAll('.response-content-markdown').length"
    base_imgs=set(c.ev(IMGJS) or []); base_md=c.ev(MDJS) or 0
    if att:
        doc=c.call('DOM.getDocument',depth=1)
        q=c.call('DOM.querySelector',nodeId=doc['root']['nodeId'],selector='input[type=file]')
        c.call('DOM.setFileInputFiles',nodeId=q['nodeId'],files=att); time.sleep(5+2*len(att))
    c.ev("document.querySelector('.ProseMirror').focus()")
    c.call('Input.insertText',text=open(src,encoding='utf-8').read().strip()); time.sleep(1)
    c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='제출');if(b)b.click()})()")
    time.sleep(3)
    if c.ev("document.querySelector('.ProseMirror').innerText.trim().length")>5:
        for typ in ('keyDown','keyUp'): c.call('Input.dispatchKeyEvent',type=typ,key='Enter',code='Enter',windowsVirtualKeyCode=13,nativeVirtualKeyCode=13)
    time.sleep(20)
    for i in range(int(a[a.index('--polls')+1]) if '--polls' in a else 100):
        c.call('Page.bringToFront'); body=c.ev("document.body.innerText")
        tail=body[-1500:]
        if ('한도' in tail or 'limit' in tail.lower()) and re.search('초기화|업그레이드|upgrade|SuperGrok',tail):
            print('LIMIT', re.sub(r'\s+',' ',tail[-300:])); sys.exit(3)
        busy=('작업 중' in body) or ('생성 중' in body) or c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
        imgs=[u for u in dict.fromkeys(c.ev(IMGJS) or []) if u not in base_imgs]
        ans=c.ev("(()=>{const x=[...document.querySelectorAll('.response-content-markdown')];return x.length?x[x.length-1].innerText:''})()")
        done = not busy and (imgs if imgdir else (c.ev(MDJS) or 0)>base_md and len(ans)>150)
        cur=(ans,len(imgs))
        if done and cur == globals().get('_prev'):
            break
        globals()['_prev'] = cur if done else None
        time.sleep(12)
    else:
        open(dst+'.body.txt','w',encoding='utf-8').write(body); print('TIMEOUT', t['id']); sys.exit(4)
    open(dst,'w',encoding='utf-8').write(ans)
    if imgdir:
        import os; os.makedirs(imgdir,exist_ok=True)
        seen=[]
        for u in imgs:
            if u in seen: continue
            seen.append(u)
            r=c.call('Runtime.evaluate',expression="fetch(%s,{credentials:'include'}).then(r=>r.blob()).then(b=>new Promise(res=>{const f=new FileReader();f.onload=()=>res(f.result);f.readAsDataURL(b)}))"%json.dumps(u),awaitPromise=True,returnByValue=True)
            open(f"{imgdir}/img{len(seen)}.jpg",'wb').write(base64.b64decode(r['result']['value'].split(',',1)[1]))
        print('IMGS',len(seen))
    print('OK',dst)
finally:
    if '--keep' in a: print('KEPT', t['id'])
    else:
      try: urllib.request.urlopen(g.BASE+'/json/close/'+t['id'])
      except Exception: pass
