# Fleet Empire style: big two-tone title on top, real in-game screenshot in a framed panel below (Kash 3 Oct)
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np, os
TR='/root/.claude/projects/-home-claude-main/62ee7c29-3555-51be-b0ac-e51c354a3caf/tool-results/mcp-remote-devices-blob-'
UP='/root/.claude/uploads/62ee7c29-3555-51be-b0ac-e51c354a3caf/'
F='/tmp/claude-0/-home-claude-main/62ee7c29-3555-51be-b0ac-e51c354a3caf/scratchpad/fonts/'
W,H=1920,1080
GOLD=(246,196,72); GOLD2=(255,226,128); WHITE=(255,255,255)
def font(sz): return ImageFont.truetype(F+'Anton.ttf', sz)
def bg():
    y,x=np.mgrid[0:H,0:W]
    d=np.sqrt(((x-W/2)/W)**2+((y-H*0.55)/H)**2)
    base=np.array([22,30,46],float); edge=np.array([8,11,18],float)
    t=np.clip(d*1.6,0,1)[...,None]
    img=(base*(1-t)+edge*t)
    # faint diagonal stripes like the competitor
    stripes=((x+y)//28)%2==0
    img[stripes]*=1.04
    return Image.fromarray(img.clip(0,255).astype(np.uint8)).convert('RGBA')
def text_w(t,f):
    b=f.getbbox(t); return b[2]-b[0]
def draw_line(im, parts, y, sz, shadow=True):
    f=font(sz)
    total=sum(text_w(t,f) for t,_ in parts)+ (len(parts)-1)*int(sz*0.22)
    x=(W-total)//2
    layer=Image.new('RGBA',im.size,(0,0,0,0)); d=ImageDraw.Draw(layer)
    sh=Image.new('RGBA',im.size,(0,0,0,0)); ds=ImageDraw.Draw(sh)
    for t,col in parts:
        if shadow: ds.text((x+6,y+10),t,font=f,fill=(0,0,0,200))
        d.text((x,y),t,font=f,fill=col,stroke_width=max(3,sz//28),stroke_fill=(14,18,28))
        x+=text_w(t,f)+int(sz*0.22)
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))
    im.alpha_composite(layer)
def gold_gradient_text(im, text, y, sz):
    # title word with a vertical gold gradient fill
    f=font(sz); w=text_w(text,f)
    return w
def panel(im, shot, box, crop=None, label=None):
    src=Image.open(shot).convert('RGB')
    if crop: src=src.crop(crop)
    bx,by,bw,bh=box
    s=min(bw/src.width, bh/src.height)
    src=src.resize((int(src.width*s),int(src.height*s)),Image.LANCZOS)
    px=bx+(bw-src.width)//2; py=by+(bh-src.height)//2+10
    # glow
    glow=Image.new('RGBA',im.size,(0,0,0,0)); dg=ImageDraw.Draw(glow)
    dg.rounded_rectangle((px-14,py-14,px+src.width+14,py+src.height+14),28,fill=(246,196,72,90))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(26)))
    # frame
    fr=Image.new('RGBA',im.size,(0,0,0,0)); df=ImageDraw.Draw(fr)
    df.rounded_rectangle((px-8,py-8,px+src.width+8,py+src.height+8),22,fill=(16,22,34,255),outline=GOLD,width=5)
    im.alpha_composite(fr)
    mask=Image.new('L',src.size,0); ImageDraw.Draw(mask).rounded_rectangle((0,0,src.width,src.height),16,fill=255)
    im.paste(src,(px,py),mask)
    if label:
        f=font(40); tw=text_w(label,f)
        lx=px+(src.width-tw)//2-30; ly=py-34
        d=ImageDraw.Draw(im)
        d.rounded_rectangle((lx,ly,lx+tw+60,ly+62),14,fill=GOLD,outline=(120,80,20),width=3)
        d.text((lx+30,ly+4),label,font=f,fill=(40,26,6))
    return py+src.height
def make(name, line1, line2, shot, crop=None, label=None, panel_top=360):
    im=bg()
    draw_line(im, line1, 18, 170)
    draw_line(im, line2, 205, 92)
    panel(im, shot, (70, panel_top, W-140, H-panel_top-40), crop, label)
    out=f'/home/claude/main/art/ads/v7/{name}.png'
    im.convert('RGB').save(out); print(out)
TITLE=[('IDLE',WHITE),('COUNTRY',GOLD)]
make('ic_properties', TITLE, [('BUILD YOUR',WHITE),('EMPIRE!',GOLD)], TR+'1790915250626-ww5jcb.jpg', (215,85,1850,818), 'YOUR PROPERTIES')
make('ic_convoys', TITLE, [('SEND',WHITE),('TRADE CONVOYS',GOLD),('WORLDWIDE!',WHITE)], TR+'1791061166093-ankg68.jpg', (205,75,1762,808), 'WORLD MAP')
make('ic_boss', TITLE, [('DEFEAT',WHITE),('BOSSES',GOLD),('FOR GOLD!',WHITE)], TR+'1791061183507-86bshr.jpg', (225,140,1840,580), 'BOSS FIGHT')
make('ic_officers', TITLE, [('HIRE',WHITE),('LEGENDARY',GOLD),('OFFICERS!',WHITE)], TR+'1790915290773-1agb4x.jpg', (215,85,1850,818), 'YOUR CABINET')
make('ic_alliance', TITLE, [('JOIN AN',WHITE),('ALLIANCE',GOLD),('& CONQUER!',WHITE)], TR+'1791059261851-ucn9rb.jpg', (225,305,1840,690), 'ALLIANCE TARGET')
make('ic_army', TITLE, [('RAISE YOUR',WHITE),('ARMY!',GOLD)], TR+'1790921636915-g9i72i.jpg', (215,85,1850,818), 'MILITARY')
