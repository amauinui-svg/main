import numpy as np, json
from PIL import Image
from scipy import ndimage
from cities import CITIES
W,H=768,292
hi=np.asarray(Image.open('land_hi.png').convert('L'))
land=np.asarray(Image.fromarray(hi).resize((W,H),Image.BOX),dtype=np.float32)/255>0.42
S=W/(2*np.pi)
def proj(lon,lat): return ((lon+180)/360*W, S*np.radians(80-lat))
lat_of=lambda y: 80-np.degrees(y/S)
rng=np.random.default_rng(4)
def hexc(h):return np.array([int(h[i:i+2],16) for i in (0,2,4)],np.float32)
P={k:hexc(v) for k,v in dict(deep='18202a',sea='1d2631',sea2='202a36',shallow='283646',surf='34485a',paper='cdbb8f',paper2='c4b183',paper3='d6c79f',
 edge='a8956a',ink='3b3222',snow='e4ddca',sand='d7bd84',green='b9b585',grid='5d5340').items()}
img=np.zeros((H,W,3),np.float32)
seadist=ndimage.distance_transform_edt(~land); landdist=ndimage.distance_transform_edt(land)
img[:]=P['deep']; n=rng.random((H,W))
img[(~land)&(n<0.5)]=P['sea']; img[(~land)&(n<0.06)]=P['sea2']
img[(~land)&(seadist<=4)]=P['sea2']; img[(~land)&(seadist<=3)]=P['shallow']; img[(~land)&(seadist<=2)]=P['surf']
low=ndimage.gaussian_filter(rng.random((H,W)),3); low=(low-low.min())/(low.max()-low.min())
yy=np.arange(H)[:,None].repeat(W,1); xx=np.arange(W)[None,:].repeat(H,0); lat=lat_of(yy)
img[land]=P['paper']; img[land&(low<0.35)]=P['paper2']; img[land&(low>0.68)]=P['paper3']
mid=ndimage.gaussian_filter(rng.random((H,W)),6); mid=(mid-mid.min())/(mid.max()-mid.min()); fine=rng.random((H,W))
img[land&(abs(lat-23+(mid-0.5)*14)<8+(mid-0.5)*6)&(fine<0.85)]=P['sand']
img[land&(abs(lat+(mid-0.5)*10)<11)&(fine<0.8)]=P['green']
snowline=62+(mid-0.5)*14
img[land&(lat>snowline+2)]=P['snow']; band=land&(lat>snowline-2)&(lat<=snowline+2)&(fine<(lat-(snowline-2))/4); img[band]=P['snow']
img[land&(low>0.55)&(low<0.62)&(((yy+xx)%2)==0)]=P['paper2']
img[land&(landdist<=1)]=P['edge']
img[(~land)&(seadist<=1)]=P['ink']*0.9
img[(~land)&np.roll(np.roll(land,1,0),1,1)&(seadist>1)&(seadist<=2.3)]=P['deep']*0.7
for lon in range(-180,181,15):
    x=int(round(proj(lon,0)[0]))
    if 0<=x<W:
        for y in range(0,H,2):
            if not land[y,x]: img[y,x]=img[y,x]*0.55+P['grid']*0.45
for la in range(75,-60,-15):
    y=int(round(proj(0,la)[1]))
    if 0<=y<H:
        for x in range(0,W,2):
            if not land[y,x]: img[y,x]=img[y,x]*0.55+P['grid']*0.45
pts=np.array([proj(c[2],c[3]) for c in CITIES])
gx,gy=np.meshgrid(np.arange(W)+0.5,np.arange(H)+0.5)
# Kash 3 Oct: territories cover 100% of the land and follow real country borders.
# Every land cell gets a country (nearest country for slivers the raster missed). A country with cities is split
# between them (nearest city); a country without a city joins the city nearest to its centre as a whole.
cg=np.load('country_grid.npy')
from scipy import ndimage as ndi
idx=ndi.distance_transform_edt(cg==0,return_distances=False,return_indices=True)
cgf=cg[idx[0],idx[1]]
cgf=np.where(land,cgf,0)
dd=np.stack([np.hypot(gx-px,gy-py) for px,py in pts])
cityC=[int(cgf[int(py),int(px)]) or int(cg[idx[0][int(py),int(px)],idx[1][int(py),int(px)]]) for px,py in pts]
groups={}
for ci,k in enumerate(cityC): groups.setdefault(k,[]).append(ci)
cell=np.full((H,W),-1,np.int32)
for k in np.unique(cgf[land]):
    m=land&(cgf==k)
    if k in groups:
        g=groups[k]; sub=dd[g][:,m]; cell[m]=np.array(g)[sub.argmin(0)]
    else:
        ys,xs=np.nonzero(m); cx,cy=xs.mean()+0.5,ys.mean()+0.5
        cell[m]=int(np.argmin([np.hypot(cx-px,cy-py) for px,py in pts]))
edge=np.zeros((H,W),bool); cedge=np.zeros((H,W),bool)
for dy,dx in((0,1),(1,0),(0,-1),(-1,0)):
    nb=np.roll(cell,(-dy,-dx),(0,1)); nbc=np.roll(cgf,(-dy,-dx),(0,1))
    edge|=(cell!=nb)&(cell>=0)&(nb>=0)
    cedge|=(cgf!=nbc)&(cell>=0)&(nb>=0)&(cell==nb)
img[cedge&~edge]=img[cedge&~edge]*0.72+P['ink']*0.28
img[edge]=img[edge]*0.45+P['ink']*0.55
Image.fromarray(img.clip(0,255).astype(np.uint8)).save('out/IC_map_world.png')
# territory runs per city: [y, x0, x1] horizontal runs of the cell; edge runs separately for an outline overlay
terr={}
for i,c in enumerate(CITIES):
    runs=[];eruns=[]
    for y in range(H):
        row=cell[y]==i; er=edge[y]&row
        for arr,out in ((row,runs),(er,eruns)):
            x=0
            while x<W:
                if arr[x]:
                    s=x
                    while x<W and arr[x]: x+=1
                    out.append([y,s,x-1])
                else: x+=1
    terr[c[0]]={'runs':runs,'edge':eruns}
cityout=[{'name':c[0],'country':c[1],'lon':c[2],'lat':c[3],'land':c[4],'px':round(float(px),2),'py':round(float(py),2)} for c,(px,py) in zip(CITIES,pts)]
json.dump({'w':W,'h':H,'cities':cityout,'terr':terr},open('out/map_data.json','w'))
print('runs',sum(len(v['runs']) for v in terr.values()),'edge',sum(len(v['edge']) for v in terr.values()))
