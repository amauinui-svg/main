import json, numpy as np
from PIL import Image, ImageDraw
W,H=768,292; K=4
S=W/(2*np.pi)
fc=json.load(open('../wmap/countries.geojson'))
img=Image.new('I',(W*K,H*K),0); dr=ImageDraw.Draw(img)
names={}
def P(lon,lat): return ((lon+180)/360*W*K, S*np.radians(80-lat)*K)
bad=0
for i,f in enumerate(fc['features'],1):
    names[i]=f['properties'].get('name','?')
    g=f['geometry']
    if not g: continue
    polys=g['coordinates'] if g['type']=='MultiPolygon' else [g['coordinates']]
    for poly in polys:
        for ri,ring in enumerate(poly):
            lons=[p[0] for p in ring]
            if names[i]=='Antarctica': continue
            if max(lons)-min(lons)>300:
                bad+=1
                pts=[P(p[0]+360 if p[0]<0 else p[0],p[1]) for p in ring]
                dr.polygon(pts, fill=(i if ri==0 else 0))
                dr.polygon([(x-W*K,y) for x,y in pts], fill=(i if ri==0 else 0))
                continue
            pts=[P(*p) for p in ring]
            dr.polygon(pts, fill=(i if ri==0 else 0))
a=np.asarray(img).reshape(H,K,W,K).transpose(0,2,1,3).reshape(H,W,K*K)
# majority non-zero id per cell
out=np.zeros((H,W),np.int32)
for y in range(H):
    for x in range(W):
        v=a[y,x]; v=v[v>0]
        if len(v): out[y,x]=np.bincount(v).argmax()
np.save('country_grid.npy',out); json.dump(names,open('country_names.json','w'))
print('bad rings',bad,'cells',(out>0).sum())
