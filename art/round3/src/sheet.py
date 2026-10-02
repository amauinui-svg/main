#!/usr/bin/env python3
# contact sheet: sheet.py out.png size cols files...
import sys
from PIL import Image
out,size,cols=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]);fs=sys.argv[4:]
rows=(len(fs)+cols-1)//cols
sh=Image.new('RGBA',(cols*size,rows*size),(58,52,48,255))
for i,fn in enumerate(fs):
    im=Image.open(fn).convert('RGBA');im.thumbnail((size,size),Image.LANCZOS)
    sh.alpha_composite(im,((i%cols)*size+(size-im.width)//2,(i//cols)*size+(size-im.height)//2))
sh.save(out)
