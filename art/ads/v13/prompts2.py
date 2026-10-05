import json
P=json.load(open('/home/claude/main/art/ads/v12/prompts.json'))
STYLE=P[0]['prompt'][len(P[0]['scene'])+1:]
CLEAN=(" Keep it clean and hand-drawn like the references: few, large, clearly drawn shapes, simple flat cel shading, no tiny repeated crowd detail, no mushy textures, no glossy 3D or airbrushed look.")
MAP=(" The map is drawn like an old hand-inked campaign map on aged parchment in the comic style of the references: inked coastlines, small drawn mountain ranges, forests and rivers, "
     "tiny castle icons on capital cities, a compass rose in a corner, sea drawn with ink wave lines. Seen straight from above, bird's-eye view, zoomed in so the land fills the frame. "
     "No glossy 3D arrows, no neon glow, no characters.")
X=[
 ("raid_notext",["v13ref_raid.jpg","sref_04.jpg"],
  "Redraw the scene from the first attached image with NO title and NO text anywhere: a Roblox bacon hair character with a sly grin sprints toward the viewer out of a rival nation's broken stone treasury, carrying two bulging gold coin sacks, coins spilling. "
  "Behind him a smashed round vault door, crimson banners with a white star, torches. On the right a classic yellow Roblox noob king in a crimson robe and crown grabs his head in panic. Frame it slightly wider so both characters fit fully with space around them. Only these two characters."),
 ("conquer_europe",["v13ref_namap.jpg","sref_16.jpg"],
  "Big title text \"CONQUER THE WORLD\" across the top in the reference title lettering. Below, a zoomed-in map of Europe. The western half is painted royal blue with gold crown flags planted on its capitals; the eastern countries are crimson red with white star flags. "
  "One thick hand-painted brush-stroke arrow in dark blue ink, rough edged like a general drew his battle plan, sweeps from the blue land into the red, ending at a red capital whose star flag is burning and being replaced by a blue crown flag." ),
 ("conquer_namerica",["v13ref_namap.jpg","sref_16.jpg"],
  "Big title text \"CONQUER THE WORLD\" across the top in the reference title lettering. Below, a zoomed-in map of North America. The USA is royal blue with gold crown flags on its cities and the blue colour is visibly spreading into crimson red Canada and Mexico like fresh paint soaking across the border, "
  "with small flames and smoke along the border line and red white-star flags falling over. No arrows at all."),
 ("conquer_world_ink",["v13ref_namap.jpg","sref_03.jpg"],
  "Big title text \"CONQUER THE WORLD\" across the top in the reference title lettering. Below, a map of Europe, Africa and the Middle East. Royal blue empire with gold crown flags covers most of it; a few crimson red countries with white star flags remain in the east. "
  "Small inked war details on the map: tiny drawn cannons and soldier icons along the front line, a burning red city, gold coins on the captured capitals. No arrows."),
 ("defeat_the_warlord",["v13ref_boss.jpg","sref_12.jpg"],
  "Big title text \"DEFEAT THE WARLORD\" across the top in the reference title lettering. The barbarian warlord boss from the first attached image, drawn huge and filling the right half: horned helmet, red braided beard, war axe, angry. Above his head a red boss health bar that is almost empty. "
  "On the left a Roblox bacon hair character with the classic Roblox smirk face leaps at him swinging a sword, with a big gold slash effect across the boss. Burning wooden fort and red banners in the background. Only these two characters."),
]
json.dump([[r,s+(MAP if k.startswith('conquer') else '')+CLEAN+" "+STYLE] for k,r,s in X],open('v5c.json','w'))
json.dump([k for k,_,_ in X],open('keys2.json','w'))
