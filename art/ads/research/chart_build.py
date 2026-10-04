import json,os,html
R='/home/claude/main/art/ads/research/'; V='/home/claude/main/art/ads/v12/'
D='/tmp/claude-0/-home-claude-main/62ee7c29-3555-51be-b0ac-e51c354a3caf/scratchpad/chart/'
g=json.load(open(R+'games.json')); ads=json.load(open(R+'homepage_ads.json'))
P=json.load(open(V+'prompts.json'))
e=html.escape
def gi(i,k=0): return f'img/g{i}_{k}.jpg'
def card(i,k,note=''):
    x=g[i]; return f'<figure class="ref"><img loading="lazy" src="{gi(i,k)}" alt=""><figcaption><b>{e(x["n"][:38])}</b><span class="pl">{x["pl"]:,} playing</span>{("<i>"+e(note)+"</i>") if note else ""}</figcaption></figure>'
PATTERNS=[
 ("Map conquest with arrows","Your country's colour pours outward over neighbours on a real map. This is the single most common image in country games and it is the exact fantasy: take land.",
  [(2,0,"Arrows burst out of one country"),(2,2,"Grinning flag nation grabs neighbours"),(1,0,"Map as hero art, top game at 27k"),(10,1,"Glowing territory pushes borders"),(22,0,"Rival nation looks scared"),(20,0,"Crowned nation reaches for the next one")],
  "Use our own world map style, blue crown territory, glowing arrows, rival land in crimson. Show the ACT of capturing, not a static map."),
 ("Army scale","A sea of soldiers reaching the horizon. Players read it instantly as power. The #1 game in the set (34k) uses it on every thumbnail.",
  [(0,0,"Wall of soldiers, no text"),(0,4,"One avatar commanding a huge army"),(3,2,"Endless marching column"),(32,1,"King points at his army"),(34,3,"Rows of clones")],
  "Rows of blue soldiers under crown banners, low camera, golden hour, one commander in front."),
 ("Before and after progression","Small start, huge finish, arrow between. Sells the grind as a promise: you will get this big.",
  [(43,0,"DAY 1 / DAY 999"),(15,2,"$0 to $999,999"),(42,3,"LVL 1 / LVL 99"),(40,1,"1 + 1 = 500"),(31,1,"Start as a peasant, become the king"),(19,1,"PEACE / WAR split")],
  "Same bacon character on both sides: rags and a hut on the left, crown, palace and army on the right."),
 ("Rivalry and VS","Two sides, one winner. Percentages and faces make the stakes readable at thumbnail size.",
  [(36,0,"0.67% vs 99.9%"),(20,2,"King VS king"),(46,0,"USA 99% vs BRAZIL 1%"),(11,0,"Country vs country fight"),(4,0,"Happy vs angry nation")],
  "Blue crown nation vs crimson star nation. Use numbers like WORLD CONTROLLED 99% and a panicking rival noob."),
 ("Capital siege and city destruction","A city getting hit is the payoff moment of conquest.",
  [(16,2,"City under missile fire"),(15,4,"Big red button, city target"),(23,3,"BATTLE / EXPAND"),(30,1,"Empire borders burning")],
  "Storm the rival capital: ladders, broken gate, our flag going up, their flag falling. No modern missiles, our game is crowns and armies."),
 ("Premium dark key art","Dark, moody, high-detail illustration. Stands out on a homepage full of bright cartoon ads, and signals depth to strategy players.",
  [(5,0,"Idle Mafia, dark gold"),(37,0,"Napoleonic Wars"),(18,0,"Frontline Commander"),(5,4,"Territory map, dark")],
  "This is where Kash's desktop style already lives. Keep the inked dark warmth, but put conquest content inside it."),
 ("Real UI screenshots","Shows exactly what you will do. Works for players who already want a strategy game.",
  [(17,0,"Load board with title on top"),(9,2,"Research tree next to the map"),(4,2,"Economy numbers over France"),(5,1,"Territory UI")],
  "Use for secondary thumbnails (slots 3 to 5) after the hook images: real map screen, army screen, alliance screen."),
]
desk_keep=["Hand-inked comic style with heavy outlines and crosshatching","Warm amber light, crimson, gold and navy palette","Blue banners with the gold crown as the player's nation","Cream condensed serif title with a dark outline","Bacon hair and classic noob drawn in that style"]
desk_fix=["Most are indoors (throne room, desk, office). Nothing shows land, armies or a map being taken","Titles describe menus (DAILY ORDERS, HIRE OFFICERS, CUSTOM FLAGS) instead of the fantasy","One character posing, no enemy, no stakes, no before and after","Low contrast at small size: dark brown on dark brown, title is the only readable thing","FIGHT FOR TERRITORY and RAISE YOUR ARMY are the two closest to what sells; build from those"]
persona=[("Control my country","I pick a nation and it is MINE. My flag, my colour on the map."),("Take over land","I want to watch my colour spread over the map, country by country."),("A big army","The army has to look huge. Thousands of soldiers, not five."),("Beat someone","There has to be an enemy who loses. Real players are better than bots."),("Grow from nothing","Show me where I start and where I end up. Numbers going up."),("Rule the world","The end goal is the whole map. 100%.")]
roles={"conquer_the_world":"Main game thumbnail #1 and homepage ad","day1_vs_day100":"Main thumbnail #2, best ad for progression players","raise_a_million":"Ad creative, army scale","your_army_vs_theirs":"Ad creative, action","take_their_capital":"Thumbnail #3, capitals feature","rule_the_world_globe":"Icon source and ad","expand_your_borders":"Thumbnail, territory feature","from_peasant_to_king":"Ad creative, progression","alliance_war":"Thumbnail, alliances feature","defend_your_nation":"Ad creative, raids and defence"}
sources={"conquer_the_world":"Pixel Conquest, Conquer The World WW2, Country War RTS","day1_vs_day100":"2 Player Raid Tycoon, Nuke A Country","raise_a_million":"Merge a Mini Army, [MONGOLS] Command An Army","your_army_vs_theirs":"Build a Medieval Army, Medieval Strategy","take_their_capital":"Be the King, Missiles vs Cities","rule_the_world_globe":"Rule The World, World.io","expand_your_borders":"Pixel Conquest, World at War, our own FIGHT FOR TERRITORY","from_peasant_to_king":"Medieval Life, 2 Player Raid Tycoon","alliance_war":"Mini War (flags side by side), our JOIN AN ALLIANCE","defend_your_nation":"Medieval Strategy DEFEND, Build a Military Base RAIDS"}
def outs(k):
    fs=[f for f in sorted(os.listdir(D+'img'),key=lambda f:(f[-6:-4]!='r2',f)) if f.startswith('v12_') and f[4:].startswith(k+'_')]
    return ''.join(f'<img loading="lazy" src="img/{f}" alt="">' for f in fs)
STYLE=P[0]['prompt'][len(P[0]['scene'])+1:]
concepts=''.join(f'''<article class="concept" id="c-{p["key"]}"><div class="cimgs">{outs(p["key"])}</div><div class="cbody"><h3>{e(p["title"])}</h3><p class="role">{e(roles[p["key"]])}</p><dl><dt>Concept from</dt><dd>{e(sources[p["key"]])}</dd><dt>Flow refs</dt><dd>{", ".join(e(r) for r in p["refs"])} <span class="muted">(art/ads/style_refs)</span></dd></dl><details><summary>Scene prompt</summary><p class="prompt">{e(p["scene"])}</p></details></div></article>''' for p in P)
pat=''.join(f'''<section class="pattern"><h3>{e(t)}</h3><p>{e(w)}</p><div class="strip">{"".join(card(i,k,n) for i,k,n in ex)}</div><p class="ours"><b>Our version:</b> {e(o)}</p></section>''' for t,w,ex,o in PATTERNS)
GROUPS=[("Country and map strategy",[1,2,4,9,10,12,20,22,25,27,28,29,30,46,47,35,36]),("Armies and war tycoons",[0,3,6,7,8,11,15,16,18,19,21,23,24,26,32,33,34,37,38,39,40,44,45]),("Idle, incremental and empire sims",[5,13,14,17,31,41,42,43,48,49])]
gal=''.join(f'<h3 class="gh">{e(n)}</h3><div class="grid">'+''.join(card(i,k) for i in sorted(ids,key=lambda i:-g[i]['pl']) for k in range(3) if os.path.exists(D+gi(i,k)))+'</div>' for n,ids in GROUPS)
adg=''.join(f'<figure class="ref"><img loading="lazy" src="img/a{a["u"]}.jpg" alt=""><figcaption><b>{e(a["n"].strip()[:34])}</b><span class="pl">{a["genre"]} · {a["pl"]:,} playing</span></figcaption></figure>' for a in sorted(ads,key=lambda a:-a['pl']) if os.path.exists(D+f'img/a{a["u"]}.jpg'))
desk=''.join(f'<img loading="lazy" src="img/s{n:02d}.jpg" alt="">' for n in range(1,17))
li=lambda xs:''.join(f'<li>{e(x)}</li>' for x in xs)
pers=''.join(f'<div class="want"><b>{e(a)}</b><span>{e(b)}</span></div>' for a,b in persona)
H=open(D+'template.html').read()
for k,v in dict(PATTERNS=pat,CONCEPTS=concepts,GALLERY=gal,ADS=adg,DESK=desk,KEEP=li(desk_keep),FIX=li(desk_fix),PERSONA=pers,STYLE=e(STYLE),NG=str(len(g)),NA=str(len(ads)),NT=str(sum(len(x['thumbs']) for x in g))).items():
    H=H.replace('{{'+k+'}}',v)
open(D+'index.html','w').write(H); print(len(H))
