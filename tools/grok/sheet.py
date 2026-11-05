"""검수 시트: sheet.py <out.jpg> <편id...> — 한 줄에 2편(컷 4장씩). 저장소 루트에서 실행, Pillow 필요."""
import sys, os
from PIL import Image, ImageDraw
out, ids = sys.argv[1], sys.argv[2:]
W, H, cols = 400, 267, 2
rows = (len(ids) + cols - 1) // cols
sheet = Image.new('RGB', (cols * (4 * W + 20), rows * (H + 24)), 'white'); d = ImageDraw.Draw(sheet)
for i, id in enumerate(ids):
    r, c = divmod(i, cols); x0 = c * (4 * W + 20); y0 = r * (H + 24)
    d.text((x0 + 4, y0 + 4), id, fill='black')
    for k in range(4):
        p = f'data/review/scene/{id}/img{k + 1}.jpg'
        if os.path.exists(p):
            im = Image.open(p); im.thumbnail((W, H)); sheet.paste(im, (x0 + k * W, y0 + 22))
sheet.save(out, quality=82); print(out, sheet.size)
