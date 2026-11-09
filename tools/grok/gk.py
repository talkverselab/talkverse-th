"""고정 방(tools/grok/room_th.txt)에서 Grok 한 건: gk.py <prompt> <out.md> [--attach m4path,..] [--img outdir] [--new]  — 끝나면 탭 닫음.
사용자 지시 2026-11-06: 새 방을 만들지 말고 한 방에서 이어 쓴다(통일성·토큰). --new 는 새 방이 꼭 필요할 때만. 포트 = GROK_CDP_PORT(기본 9225 = 태국어 전용, M4 ~/chrome-grok-th)."""
# 2026-11-05 tools/grok 로 옮김(/tmp 스크래치패드가 재부팅으로 지워져 복구) — 의존: ~/Hanja/tools/grok_cdp.py, 터널 9225(ssh -fN -L 9225:127.0.0.1:9225 macmini4)
import sys, time, json, base64, urllib.request, re, os
os.environ.setdefault('GROK_CDP_PORT','9259')  # 2026-11-09(9258 은 de) PC 크롬(D:\chrome-grok-th, 터널 ssh -fN -L 9259:127.0.0.1:9259 pc), 전문가 모드
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
    # 사용자 지시 2026-11-09: 전문가 모드로만 — 탭마다 확인하고 아니면 바꾼다(방 탭은 열 때 빠른으로 돌아올 수 있음)
    MODE="(()=>{const b=[...document.querySelectorAll('button')].find(x=>/^(모델|Model):/.test(x.getAttribute('aria-label')||''));return b?b.getAttribute('aria-label'):''})()"
    OPEN="(()=>{const b=[...document.querySelectorAll('button')].find(x=>/^(모델|Model):/.test(x.getAttribute('aria-label')||''));if(!b)return 0;['pointerdown','pointerup'].forEach(t=>b.dispatchEvent(new PointerEvent(t,{bubbles:true})));b.click();return 1})()"
    PICK="(()=>{const it=[...document.querySelectorAll('[role=menuitem],[role=option],[role=menuitemradio],[role=menuitemcheckbox],button,div')].find(x=>/^(전문가|Expert)(\\s|$)/.test((x.innerText||'').trim())&&x.offsetParent&&!/^(모델|Model):/.test(x.getAttribute('aria-label')||''));if(!it)return 0;['pointerdown','pointerup'].forEach(t=>it.dispatchEvent(new PointerEvent(t,{bubbles:true})));it.click();return 1})()"
    for _ in range(3):
        if '전문가' in (c.ev(MODE) or '') or 'Expert' in (c.ev(MODE) or ''): break
        c.ev(OPEN); time.sleep(1.5); c.ev(PICK); time.sleep(1.5)
    if not ('전문가' in (c.ev(MODE) or '') or 'Expert' in (c.ev(MODE) or '')):
        print('NOTEXPERT', c.ev(MODE)); sys.exit(5)
    IMGJS="[...document.querySelectorAll('img')].filter(e=>e.src.includes('/generated/')&&e.naturalWidth>300).map(e=>e.src)"
    MDJS="document.querySelectorAll('.response-content-markdown').length"
    base_imgs=set(c.ev(IMGJS) or []); base_md=c.ev(MDJS) or 0
    LASTJS="(()=>{const x=[...document.querySelectorAll('.response-content-markdown')];return x.length?x[x.length-1].innerText:''})()"
    base_last=c.ev(LASTJS) or ''  # 방이 길면 목록이 가상화돼 상자 개수가 안 늘어난다 → 마지막 답 내용으로 판단(2026-11-09)
    if att:
        doc=c.call('DOM.getDocument',depth=1)
        q=c.call('DOM.querySelector',nodeId=doc['root']['nodeId'],selector='input[type=file]')
        c.call('DOM.setFileInputFiles',nodeId=q['nodeId'],files=att); time.sleep(5+2*len(att))
    c.ev("document.querySelector('.ProseMirror').focus()")
    c.call('Input.insertText',text=open(src,encoding='utf-8').read().strip()); time.sleep(1)
    c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>['제출','보내기','Submit','Send'].includes(e.getAttribute('aria-label')||''));if(b)b.click()})()")
    time.sleep(3)
    if c.ev("document.querySelector('.ProseMirror').innerText.trim().length")>5:
        for typ in ('keyDown','keyUp'): c.call('Input.dispatchKeyEvent',type=typ,key='Enter',code='Enter',windowsVirtualKeyCode=13,nativeVirtualKeyCode=13)
    t_sent=time.time(); MAXW=int(a[a.index('--maxwait')+1]) if '--maxwait' in a else 180  # 사용자 지시 2026-11-10: Grok 답은 3분까지만, 넘으면 생성 중지(토큰 낭비 방지)
    time.sleep(20)
    for i in range(10000):
        if time.time()-t_sent>MAXW:
            c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>/응답 중지|중지|Stop/.test(e.getAttribute('aria-label')||''));if(b){b.click();return 1}return 0})()")
            for typ in ('keyDown','keyUp'): c.call('Input.dispatchKeyEvent',type=typ,key='Escape',code='Escape',windowsVirtualKeyCode=27)
            open(dst+'.body.txt','w',encoding='utf-8').write(c.ev('document.body.innerText') or ''); print('TIMEOUT3m', t['id']); sys.exit(4)
        c.call('Page.bringToFront'); body=c.ev("document.body.innerText")
        tail=body[-1500:]
        if ('한도' in tail or 'limit' in tail.lower()) and re.search('초기화|업그레이드|upgrade|SuperGrok',tail):
            print('LIMIT', re.sub(r'\s+',' ',tail[-300:])); sys.exit(3)
        busy=('작업 중' in body) or ('생성 중' in body) or c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
        imgs=[u for u in dict.fromkeys(c.ev(IMGJS) or []) if u not in base_imgs]
        ans=c.ev("(()=>{const x=[...document.querySelectorAll('.response-content-markdown')];return x.length?x[x.length-1].innerText:''})()")
        done = not busy and (imgs if imgdir else ((c.ev(MDJS) or 0)>base_md or ans!=base_last) and len(ans)>150)
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
