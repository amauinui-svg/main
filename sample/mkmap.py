import numpy as np, json
from PIL import Image
from scipy import ndimage
from cities import CITIES
W,H=768,292
hi=np.asarray(Image.open('land_hi.png').convert('L'),dtype=np.float32)/255
land=np.asarray(Image.fromarray((hi*255).astype(np.uint8)).resize((W,H),Image.BOX),dtype=np.float32)/255>0.42
land=ndimage.binary_opening(land,iterations=0) if False else land
def proj(lon,lat):  # same projection as world.svg, scaled 768/1240
    s=W/(2*np.pi); return ((lon+180)/360*W, s*np.radians(80-lat))
lat_of=lambda y: 80-np.degrees(y/(W/(2*np.pi)))
rng=np.random.default_rng(4)
def hexc(h):return np.array([int(h[i:i+2],16) for i in (0,2,4)],np.float32)
P={k:hexc(v) for k,v in dict(deep='18202a',sea='1d2631',sea2='202a36',shallow='283646',surf='34485a',
 paper='cdbb8f',paper2='c4b183',paper3='d6c79f',edge='a8956a',ink='3b3222',snow='e4ddca',sand='d7bd84',green='b9b585',grid='5d5340').items()}
img=np.zeros((H,W,3),np.float32)
seadist=ndimage.distance_transform_edt(~land); landdist=ndimage.distance_transform_edt(land)
# sea: deep with sparse dither, shallow bands near coast
img[:]=P['deep']; n=rng.random((H,W))
img[(~land)&(n<0.5)]=P['sea']; img[(~land)&(n<0.06)]=P['sea2']
img[(~land)&(seadist<=4)]=P['sea2']; img[(~land)&(seadist<=3)]=P['shallow']; img[(~land)&(seadist<=2)]=P['surf']
# land: paper with low-freq noise patches (relief), latitude tints
low=ndimage.gaussian_filter(rng.random((H,W)),3); low=(low-low.min())/(low.max()-low.min())
yy=np.arange(H)[:,None].repeat(W,1); lat=lat_of(yy)
img[land]=P['paper']
img[land&(low<0.35)]=P['paper2']; img[land&(low>0.68)]=P['paper3']
mid=ndimage.gaussian_filter(rng.random((H,W)),6); mid=(mid-mid.min())/(mid.max()-mid.min())
fine=rng.random((H,W))
desert=land&(abs(lat-23+ (mid-0.5)*14)<8+(mid-0.5)*6)&(fine<0.85); img[desert]=P['sand']
tropic=land&(abs(lat+(mid-0.5)*10)<11)&(fine<0.8); img[tropic]=P['green']
snowline=62+(mid-0.5)*14
img[land&(lat>snowline+2)]=P['snow']; band=land&(lat>snowline-2)&(lat<=snowline+2)&(fine<(lat-(snowline-2))/4); img[band]=P['snow']
# relief hatching: checker dither in darker paper on noise ridges
ridge=land&(low>0.55)&(low<0.62)&(((yy+np.arange(W)[None,:])%2)==0); img[ridge]=P['paper2']
# coastline: land pixel touching sea -> edge, outer ink line on the sea side
img[land&(landdist<=1)]=P['edge']
outline=(~land)&(seadist<=1); img[outline]=P['ink']*0.9
shadow=(~land)&np.roll(np.roll(land,1,0),1,1)&(seadist>1)&(seadist<=2.3); img[shadow]=P['deep']*0.7
# graticule every 15 deg, dotted, sea only
for lon in range(-180,181,15):
    x=int(round(proj(lon,0)[0]));
    if 0<=x<W:
        for y in range(0,H,2):
            if not land[y,x]: img[y,x]=img[y,x]*0.55+P['grid']*0.45
for la in range(75,-60,-15):
    y=int(round(proj(0,la)[1]))
    if 0<=y<H:
        for x in range(0,W,2):
            if not land[y,x]: img[y,x]=img[y,x]*0.55+P['grid']*0.45
# city territories: nearest-city cells on land within radius, ink dotted borders between cells
pts=np.array([proj(c[2],c[3]) for c in CITIES])
gx,gy=np.meshgrid(np.arange(W)+0.5,np.arange(H)+0.5)
d=np.stack([np.hypot(gx-px,gy-py) for px,py in pts]); owner=d.argmin(0); dmin=d.min(0)
R=22; terr=land&(dmin<R); cell=np.where(terr,owner,-1)
OWN={'Rome':'c0392b','Paris':'c0392b','Berlin':'c0392b','Istanbul':'2e86c1','Cairo':'2e86c1','Tokyo':'d4a017','Osaka':'d4a017','Shanghai':'8e44ad'}
for i,c in enumerate(CITIES):
    if c[0] in OWN:
        col=hexc(OWN[c[0]]); m=cell==i; img[m]=img[m]*0.62+col*0.38
# borders: cell edges (vs other cell or no-cell) on land
edge=np.zeros((H,W),bool)
for dy,dx in((0,1),(1,0)):
    a=cell; b=np.roll(cell,(-dy,-dx),(0,1)); edge|=(a!=b)&(a>=0)
for i,c in enumerate(CITIES):
    m=edge&(cell==i)
    if c[0] in OWN: img[m]=hexc(OWN[c[0]])*0.65
    else:
        img[m]=img[m]*0.45+P['ink']*0.55
Image.fromarray(img.clip(0,255).astype(np.uint8)).save('world_pixel.png')
json.dump({c[0]:[round(float(px),1),round(float(py),1),c[1]] for c,(px,py) in zip(CITIES,pts)},open('cities_px.json','w'))
print('ok',land.mean())
