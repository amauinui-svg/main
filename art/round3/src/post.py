#!/usr/bin/env python3
"""Post-process a rendered PNG: subtle monochrome grain (alpha preserved), then shrink under a byte limit by palette quantization."""
import sys, os, io
import numpy as np
from PIL import Image

src, dst, grain, opaque, limit = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4] == '1', int(sys.argv[5])
im = Image.open(src).convert('RGBA')
a = np.asarray(im).astype(np.float32)
if grain > 0:
    rs = np.random.default_rng(abs(hash(os.path.basename(dst))) % (2**32))
    n = rs.normal(0, grain, a.shape[:2]).astype(np.float32)
    # slightly blur-free fine grain, weaker on very dark & very bright pixels
    lum = a[..., :3].mean(axis=2) / 255.0
    w = 0.55 + 0.9 * lum * (1 - lum) * 2
    for c in range(3):
        a[..., c] += n * w
a = np.clip(a, 0, 255).astype(np.uint8)
if opaque:
    a[..., 3] = 255
im = Image.fromarray(a, 'RGBA')
if opaque:
    im = im.convert('RGB')

def save(img, **kw):
    b = io.BytesIO(); img.save(b, 'PNG', optimize=True, **kw); return b.getvalue()

data = save(im)
mode = 'full'
if len(data) > limit:
    if opaque:
        q = im.quantize(256, method=Image.Quantize.MEDIANCUT, kmeans=2)
    else:
        q = im.quantize(256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.FLOYDSTEINBERG)
    data = save(q); mode = 'pal256'
    for nc in (192, 128, 96):
        if len(data) <= limit: break
        q = im.quantize(nc, method=Image.Quantize.MEDIANCUT, kmeans=2) if opaque else im.quantize(nc, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.FLOYDSTEINBERG)
        data = save(q); mode = f'pal{nc}'
open(dst, 'wb').write(data)
print(f'{len(data)//1024}KB {mode}')
