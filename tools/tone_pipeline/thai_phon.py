r"""태국어 음절 → (초성 부류, 모음, 장단, 받침, 성조) 분석 + 한글/우리 로마자 생성.

규칙(표준 성조 규칙):
  무표 : 중·저자음 평음절→평성, 고자음 평음절→상성, 중·고자음 사음절→저성,
         저자음 사음절 단모음→고성, 장모음→하성
  ่    : 중·고→저성, 저→하성      ้ : 중·고→하성, 저→고성
  ๊    : 고성                     ๋ : 상성
ห นำ(ห+저자음 유성) → 고자음 취급, อ นำ(อย่า อยู่ อย่าง อยาก) → 중자음 취급.
"""
import re

HIGH = set('ขฃฉฐถผฝศษสห')
MID = set('กจฎฏดตบปอ')
CONS = set('กขฃคฅฆงจฉชซฌญฎฏฐฑฒณดตถทธนบปผฝพฟภมยรลวศษสหฬอฮ')
SONORANT = set('งญนมยรลวณ')
TONE_MARKS = {'่': 'ek', '้': 'tho', '๊': 'tri', '๋': 'chattawa'}
KARAN = '์'
MAITAIKHU = '็'
PINTHU = 'ฺ'

# 초성 음소
INIT_PHON = {
    'ก': 'g', 'ข': 'k', 'ฃ': 'k', 'ค': 'k', 'ฅ': 'k', 'ฆ': 'k', 'ง': 'ng', 'จ': 'j', 'ฉ': 'ch', 'ช': 'ch', 'ซ': 's',
    'ฌ': 'ch', 'ญ': 'y', 'ฎ': 'd', 'ฏ': 'dt', 'ฐ': 't', 'ฑ': 't', 'ฒ': 't', 'ณ': 'n', 'ด': 'd', 'ต': 'dt', 'ถ': 't',
    'ท': 't', 'ธ': 't', 'น': 'n', 'บ': 'b', 'ป': 'bp', 'ผ': 'p', 'ฝ': 'f', 'พ': 'p', 'ฟ': 'f', 'ภ': 'p', 'ม': 'm',
    'ย': 'y', 'ร': 'r', 'ล': 'l', 'ว': 'w', 'ศ': 's', 'ษ': 's', 'ส': 's', 'ห': 'h', 'ฬ': 'l', 'อ': '', 'ฮ': 'h',
}
FINAL_PHON = {
    'ก': 'k', 'ข': 'k', 'ค': 'k', 'ฆ': 'k', 'ง': 'ng', 'จ': 't', 'ช': 't', 'ซ': 't', 'ญ': 'n', 'ฎ': 't', 'ฏ': 't',
    'ฐ': 't', 'ฑ': 't', 'ฒ': 't', 'ณ': 'n', 'ด': 't', 'ต': 't', 'ถ': 't', 'ท': 't', 'ธ': 't', 'น': 'n', 'บ': 'p',
    'ป': 'p', 'พ': 'p', 'ฟ': 'p', 'ภ': 'p', 'ม': 'm', 'ย': 'y', 'ร': 'n', 'ล': 'n', 'ว': 'w', 'ศ': 't', 'ษ': 't',
    'ส': 't', 'ฬ': 'n', 'ฮ': '',
}
CLUSTER_SECOND = set('รลว')
CLUSTERS = set('กร กล กว ขร ขล ขว คร คล คว ตร ปร ปล ผล พร พล ฟร ฟล บร บล ดร'.split())

# 한글 초성 (ng 는 별도 처리)
KO_INIT = {
    'g': 'ㄲ', 'k': 'ㅋ', 'ng': 'ㅇ', 'j': 'ㅉ', 'ch': 'ㅊ', 's': 'ㅆ', 'y': 'ㅇ', 'd': 'ㄷ', 'dt': 'ㄸ', 't': 'ㅌ',
    'n': 'ㄴ', 'b': 'ㅂ', 'bp': 'ㅃ', 'p': 'ㅍ', 'f': 'ㅍ', 'm': 'ㅁ', 'r': 'ㄹ', 'l': 'ㄹ', 'w': 'ㅇ', 'h': 'ㅎ', '': 'ㅇ',
}
CHO = list('ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ')
JUNG = list('ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ')
JONG = [''] + list('ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ')
KO_FINAL = {'k': 'ㄱ', 't': 'ㅅ', 'p': 'ㅂ', 'n': 'ㄴ', 'm': 'ㅁ', 'ng': 'ㅇ', '': ''}
# 모음 음소 → 한글 (블록 목록: 첫 블록은 초성과 결합, 이후는 ㅇ 초성)
KO_VOWEL = {
    'a': ['ㅏ'], 'i': ['ㅣ'], 'eu': ['ㅡ'], 'u': ['ㅜ'], 'e': ['ㅔ'], 'ae': ['ㅐ'], 'o': ['ㅗ'], 'aw': ['ㅓ'], 'er': ['ㅓ'],
    'ia': ['ㅣ', 'ㅏ'], 'eua': ['ㅡ', 'ㅏ'], 'ua': ['ㅜ', 'ㅏ'],
}
# y/w 초성 + 모음 결합
Y_VOWEL = {'a': 'ㅑ', 'e': 'ㅖ', 'ae': 'ㅒ', 'o': 'ㅛ', 'aw': 'ㅕ', 'er': 'ㅕ', 'u': 'ㅠ', 'i': 'ㅣ', 'eu': 'ㅡ'}
W_VOWEL = {'a': 'ㅘ', 'e': 'ㅞ', 'ae': 'ㅙ', 'i': 'ㅟ', 'aw': 'ㅝ', 'er': 'ㅝ', 'o': 'ㅗ', 'u': 'ㅜ', 'eu': 'ㅡ'}

TONE_KO_MARK = {'mid': '', 'low': 'ˋ', 'falling': 'ˆ', 'high': 'ˊ', 'rising': 'ˇ'}
TONE_ACCENT = {'mid': '', 'low': '̀', 'falling': '̂', 'high': '́', 'rising': '̌'}


def compose(cho, jung, jong=''):
    return chr(0xAC00 + CHO.index(cho) * 588 + JUNG.index(jung) * 28 + JONG.index(jong))


class Syl:
    def __init__(self):
        self.init = ''        # 초성 음소 (예: 'k', 'kr')
        self.cls = 'low'
        self.vowel = 'a'
        self.long = False
        self.final = ''       # 받침 음소
        self.glide = ''       # 이중모음 뒤 y/w 등 (예: ai → vowel a + glide y)
        self.mark = ''
        self.tone = 'mid'
        self.pre = False      # อร- 처럼 앞에 '아' 음절이 붙는 경우
        self.pre_ko = ''      # 선행 자음 음절 (싸-)
        self.pre_ro = ''

    def as_dict(self):
        return dict(init=self.init, vowel=self.vowel, long=self.long, final=self.final, tone=self.tone)


def _strip(s):
    return s.replace(PINTHU, '').replace('ๆ', '').replace('ๆ', '').strip()


def analyze(syl):
    """태국어 한 음절 문자열 → Syl. 분석 불가 시 None."""
    s = _strip(syl)
    if not s or not re.search(r'[ก-ฮ]', s):
        return None
    out = Syl()
    # 성조 부호
    for m, name in TONE_MARKS.items():
        if m in s:
            out.mark = name
            s = s.replace(m, '')
    # การันต์: 앞 자음 묵음
    while KARAN in s:
        i = s.index(KARAN)
        j = i - 1
        while j >= 0 and s[j] not in CONS:
            j -= 1
        s = s[:j] + s[i + 1:] if j >= 0 else s[:i] + s[i + 1:]
    # ฤ
    if s.startswith('ฤ'):
        out.init, out.cls, out.vowel = 'r', 'low', 'eu'
        rest = s[1:]
        if rest.startswith('ๅ'):
            out.long = True
            rest = rest[1:]
        out.final = FINAL_PHON.get(rest[:1], '') if rest else ''
        out.tone = _tone(out)
        return out
    prefix = ''
    if s and s[0] in 'เแโใไ':
        prefix, s = s[0], s[1:]
    # 초성
    i = 0
    initials = []
    while i < len(s) and s[i] in CONS:
        initials.append(s[i])
        i += 1
        if len(initials) == 2:
            break
    if not initials:
        return None
    body = s[i:]
    # ห นำ / อ นำ / 겹자음 판단
    c1 = initials[0]
    c2 = initials[1] if len(initials) > 1 else ''
    if c1 == 'ห' and c2 and c2 in SONORANT:
        out.init, out.cls = INIT_PHON[c2], 'high'
    elif c1 == 'อ' and c2 == 'ย':
        out.init, out.cls = 'y', 'mid'
    elif c1 == 'อ' and c2 == 'ร':
        out.init, out.cls, out.pre = 'r', 'mid', True
    elif c2 and c1 + c2 in CLUSTERS and not (c2 == 'ว' and len(body) == 1 and body in CONS):
        out.init = INIT_PHON[c1] + INIT_PHON[c2]
        out.cls = 'high' if c1 in HIGH else ('mid' if c1 in MID else 'low')
    elif c2 and c1 + c2 not in CLUSTERS and not (prefix and c2 in 'ยว' and not body) and (
            re.search(r'[ะัาิีึืุูำ]', body) or prefix or
            (body and body[0] in CONS and not (c2 == 'ว' and len(body) == 1))):
        # 선행 자음이 내재모음 'a'로 한 음절을 이룸: สวัส=sa-wàt, ถนน=ta-nǒn, ขนม=ka-nǒm, แสดง=sa-daeng
        cls1 = 'high' if c1 in HIGH else ('mid' if c1 in MID else 'low')
        out.pre_ko = compose(KO_INIT.get(INIT_PHON[c1], 'ㅇ'), 'ㅏ') if INIT_PHON[c1] != 'ng' else '응아'
        out.pre_ro = INIT_PHON[c1] + 'a-'
        out.init = INIT_PHON[c2]
        out.cls = cls1 if (c2 in SONORANT and cls1 in ('high', 'mid')) else (
            'high' if c2 in HIGH else ('mid' if c2 in MID else 'low'))
    elif c2:
        # 두 번째 자음은 모음 없는 음절의 받침 (คน, ผม)
        out.init = INIT_PHON[c1]
        out.cls = 'high' if c1 in HIGH else ('mid' if c1 in MID else 'low')
        body = c2 + body
    else:
        out.init = INIT_PHON[c1]
        out.cls = 'high' if c1 in HIGH else ('mid' if c1 in MID else 'low')
    _vowel(out, prefix, body)
    out.tone = _tone(out)
    return out


def _vowel(out, prefix, body):
    """prefix(เแโใไ) + body(모음부호·받침) → vowel/long/final/glide."""
    b = body
    fin = ''
    short_mark = MAITAIKHU in b
    b = b.replace(MAITAIKHU, '')

    def take_final(rest):
        rest = rest.strip()
        if not rest:
            return ''
        return FINAL_PHON.get(rest[-1], '') if rest[-1] in CONS else ''

    if prefix in ('ไ', 'ใ'):
        out.vowel, out.glide, out.long = 'a', 'y', False
        # ไทย 처럼 ย 가 남는 경우 무시
        return
    if prefix == 'เ':
        if b.endswith('าะ'):
            out.vowel, out.long = 'aw', False; return
        if b.endswith('า'):
            out.vowel, out.glide, out.long = 'a', 'w', False; return
        if b.endswith('ือะ'):
            out.vowel, out.long = 'eua', False; return
        if 'ือ' in b:
            out.vowel, out.long = 'eua', True
            out.final = take_final(b.split('ือ', 1)[1]); return
        if b.endswith('อะ'):
            out.vowel, out.long = 'er', False; return
        if b.endswith('อ'):
            out.vowel, out.long = 'er', True; return
        if b.endswith('ียะ'):
            out.vowel, out.long = 'ia', False; return
        if 'ีย' in b:
            out.vowel, out.long = 'ia', True
            out.final = take_final(b.split('ีย', 1)[1]); return
        if b.endswith('ือะ'):
            out.vowel, out.long = 'eua', False; return
        if 'ือ' in b:
            out.vowel, out.long = 'eua', True
            out.final = take_final(b.split('ือ', 1)[1]); return
        if 'ิ' in b:  # เงิน
            out.vowel, out.long = 'er', False
            out.final = take_final(b.split('ิ', 1)[1]); return
        if b.endswith('ะ'):
            out.vowel, out.long = 'e', False; return
        # เC / เCC
        fin = take_final(b)
        out.vowel, out.final = 'e', fin
        out.long = not short_mark
        if fin == 'w':
            out.vowel, out.glide, out.final, out.long = 'e', 'w', '', True
        if fin == 'y' and len(b) == 1:
            out.vowel, out.glide, out.final, out.long = 'er', 'y', '', True
        return
    if prefix == 'แ':
        if b.endswith('ะ'):
            out.vowel, out.long = 'ae', False; return
        fin = take_final(b)
        out.vowel, out.final, out.long = 'ae', fin, not short_mark
        if fin == 'w':
            out.glide, out.final = 'w', ''
        return
    if prefix == 'โ':
        if b.endswith('ะ'):
            out.vowel, out.long = 'o', False; return
        out.vowel, out.final, out.long = 'o', take_final(b), True
        return
    # 접두 모음 없음
    if b.endswith('ะ'):
        out.vowel, out.long = 'a', False; return
    if b.endswith('ำ'):
        out.vowel, out.final, out.long = 'a', 'm', False; return
    if 'ั' in b:
        rest = b.split('ั', 1)[1]
        if rest.startswith('ว'):
            out.vowel, out.long = 'ua', True
            out.final = take_final(rest[1:]); return
        fin = take_final(rest)
        out.vowel, out.long = 'a', False
        if fin == 'y':
            out.glide = 'y'
        elif fin == 'w':
            out.glide = 'w'
        else:
            out.final = fin
        return
    if 'า' in b:
        rest = b.split('า', 1)[1]
        fin = take_final(rest)
        out.vowel, out.long = 'a', True
        if fin in ('y', 'w'):
            out.glide = fin
        else:
            out.final = fin
        return
    for mark, vow, lng in (('ิ', 'i', False), ('ี', 'i', True), ('ึ', 'eu', False), ('ุ', 'u', False), ('ู', 'u', True)):
        if mark in b:
            rest = b.split(mark, 1)[1]
            fin = take_final(rest)
            out.vowel, out.long = vow, lng
            if fin in ('y', 'w') and vow in ('i', 'u'):
                out.glide = fin
            else:
                out.final = fin
            return
    if 'ื' in b:
        rest = b.split('ื', 1)[1]
        out.vowel, out.long = 'eu', True
        out.final = take_final(rest[1:] if rest.startswith('อ') else rest)
        return
    if 'รร' in b:
        rest = b.split('รร', 1)[1]
        fin = take_final(rest)
        out.vowel, out.long = 'a', False
        out.final = fin if fin else 'n'
        return
    if b.startswith('ว') and len(b) >= 2:
        # CวC → ua
        out.vowel, out.long = 'ua', True
        out.final = take_final(b[1:])
        return
    if b.startswith('อ'):
        rest = b[1:]
        fin = take_final(rest)
        out.vowel, out.long = 'aw', not short_mark
        if fin == 'y':
            out.glide = 'y'
        else:
            out.final = fin
        return
    # 모음 부호 없음: C(C) → 내재 모음 o 단모음
    fin = take_final(b)
    out.vowel, out.long = 'o', False
    out.final = fin
    if not b:
        # 모음도 받침도 없음 (예: 단독 자음) → 'aw'로 읽는 관습(ก = 꺼)
        out.vowel, out.long = 'aw', True


def _tone(o):
    dead = bool(o.final and o.final in ('k', 't', 'p')) or (not o.final and not o.glide and not o.long)
    if o.mark == 'ek':
        return 'falling' if o.cls == 'low' else 'low'
    if o.mark == 'tho':
        return 'high' if o.cls == 'low' else 'falling'
    if o.mark == 'tri':
        return 'high'
    if o.mark == 'chattawa':
        return 'rising'
    if not dead:
        return 'rising' if o.cls == 'high' else 'mid'
    if o.cls in ('mid', 'high'):
        return 'low'
    return 'falling' if o.long else 'high'


# ───────── 한글 ─────────
def to_hangul(o, tone=True):
    init = o.init
    cluster = ''
    if len(init) >= 2 and init not in ('ng', 'ch', 'dt', 'bp') and init[-1] in 'rlw' and len(init) > 1:
        # 겹자음: C1 + r/l/w
        first, second = init[:-1], init[-1]
        if second == 'w':
            init = first
            base = KO_INIT.get(first, 'ㅇ')
            jung = W_VOWEL.get(o.vowel, 'ㅘ')
            blocks = [compose(base, jung)]
            return _finish_ko(o, blocks, tone)
        cluster = compose(KO_INIT.get(first, 'ㅇ'), 'ㅡ')
        init = second
    base = KO_INIT.get(init, 'ㅇ')
    v = o.vowel
    blocks = []
    if init == 'ng':
        blocks.append('응')
        base = 'ㅇ'
    if init == 'y' and v in Y_VOWEL and v not in ('i', 'eu'):
        blocks.append(compose('ㅇ', Y_VOWEL[v]))
        rest = KO_VOWEL[v][1:]
    elif init == 'w' and v in W_VOWEL and v not in ('u', 'o'):
        blocks.append(compose('ㅇ', W_VOWEL[v]))
        rest = KO_VOWEL[v][1:]
    else:
        vs = KO_VOWEL.get(v, ['ㅏ'])
        blocks.append(compose(base, vs[0]))
        rest = vs[1:]
    for j in rest:
        blocks.append(compose('ㅇ', j))
    if cluster:
        blocks.insert(0, cluster)
    return _finish_ko(o, blocks, tone)


def _finish_ko(o, blocks, tone):
    # 활음 y/w
    if o.glide == 'y':
        blocks.append('이')
    elif o.glide == 'w':
        blocks.append('우' if o.vowel in ('a', 'e', 'ae', 'i') else '오')
    # 받침
    fin = KO_FINAL.get(o.final, '')
    if fin:
        last = blocks[-1]
        code = ord(last) - 0xAC00
        cho, jung, jong = code // 588, (code % 588) // 28, code % 28
        if jong == 0:
            blocks[-1] = chr(0xAC00 + cho * 588 + jung * 28 + JONG.index(fin))
        else:
            blocks.append(compose('ㅇ', 'ㅡ', fin))
    s = ''.join(blocks)
    if getattr(o, 'pre', False):
        s = '아' + s
    if getattr(o, 'pre_ko', ''):
        s = o.pre_ko + s
    if tone:
        s += TONE_KO_MARK[o.tone]
    return s


# ───────── 우리 로마자 ─────────
def to_roman(o, tone=True):
    v = o.vowel
    core = v
    if o.glide == 'y':
        core = v + ('i' if v == 'a' else 'y')
    elif o.glide == 'w':
        core = v + ('o' if (v == 'a' and not o.long) else 'w')
    if tone and o.tone != 'mid':
        # 첫 모음 글자에 악센트
        for k, ch in enumerate(core):
            if ch in 'aeiou':
                core = core[:k + 1] + TONE_ACCENT[o.tone] + core[k + 1:]
                break
    if o.long:
        core = '{' + core + '}'
    init = o.init
    pre = ('a-' if getattr(o, 'pre', False) else '') + getattr(o, 'pre_ro', '')
    return f"{pre}{init}{core}{o.final}"


def transcribe(syllables, tone=True):
    """음절 문자열 목록 → [{s, tone, ko, ro}]"""
    out = []
    for s in syllables:
        o = analyze(s)
        if o is None:
            out.append(dict(s=s, tone='', ko='', ro=''))
            continue
        out.append(dict(s=s, tone=o.tone, ko=to_hangul(o, tone), ro=to_roman(o, tone)))
    return out


if __name__ == '__main__':
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    tests = ['ข้าว', 'สวัส', 'ดี', 'ครับ', 'น้ำ', 'แข็ง', 'เครื่อง', 'บิน', 'ไม่', 'เป็น', 'ไร', 'แท็ก', 'ซี่', 'ผม', 'ชื่อ',
             'กรุง', 'เทพ', 'ปลา', 'สวัส', 'ถนน', 'ขนม', 'แสดง', 'สบาย', 'สวน', 'ควร', 'ตลาด', 'ไทย', 'เขา', 'เก้า', 'สอง', 'เคย', 'เรา', 'หิว', 'ยาก', 'วัน', 'หมู', 'อยาก', 'หนู', 'อยู่', 'เงิน', 'รถ', 'คน', 'มา', 'ไก่', 'ไข่', 'ควาย', 'เรือ', 'เสือ', 'ตัว', 'รอ', 'เธอ', 'ขวด', 'อร่อย', 'ร้อน', 'สวย', 'พูด', 'เก่ง', 'มาก', 'เลย']
    for t in transcribe(tests):
        print(t['s'], t['tone'], t['ko'], t['ro'])
