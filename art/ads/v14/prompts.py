import json
P=json.load(open('/home/claude/main/art/ads/v12/prompts.json'))
STYLE=P[0]['prompt'][len(P[0]['scene'])+1:]
STYLE=STYLE.replace("Title lettering is heavy condensed cream-white serif capitals with a thick dark brown outline and slight drop shadow, exactly like the reference titles. ","").replace("no extra text besides the title","no text, no letters, no numbers anywhere")
CLEAN=(" NO TEXT anywhere in the image. One dominant subject filling most of the frame, readable even as a tiny 110 pixel wide tile on a phone. "
       "Clean hand-drawn look like the references: bold ink outlines, flat cel shading, few large shapes, no tiny repeated crowd detail, no glossy 3D or airbrushed AI look. "
       "Roblox characters use the classic Roblox smirk face decal.")
X=[
 ("throne_close_a",["sref_01.jpg","v13ref_rule.jpg"],
  "Close-up of a Roblox bacon hair ruler sitting on a grand golden throne, filling about 70 percent of the frame, seen from slightly below so he looks powerful. Gold crown, navy military coat with gold epaulettes and a red sash, one hand resting on the throne arm, smug confident grin. "
  "Behind him a huge old world map on the wall covered in small royal blue crown flags, royal blue banners with gold crown emblems on each side, warm candle and window light, a few gold coins and a treasure chest at the throne's feet."),
 ("throne_close_b",["sref_06.jpg","sref_01.jpg"],
  "A Roblox bacon hair emperor lounging on a red and gold throne, framed from the knees up so he is very big in the picture, leaning forward and pointing straight at the viewer with a confident grin. Gold crown, navy coat with medals and red sash. "
  "Behind the throne, a tall arched window showing his royal blue crown flags flying over a conquered city at sunset, royal blue banners hanging on the stone walls."),
 ("rule_world_big",["v13ref_rule.jpg","sref_03.jpg"],
  "Recreate the first attached image as a closer shot with NO title: the Roblox emperor with the gold crown, navy coat and red sash stands on top of the blue globe planting a royal blue crown flag, but the camera is much closer so he is about three times bigger and fills the upper half of the frame, "
  "the top of the blue globe with a few crimson patches fills the bottom, golden god rays and blue crown banners in a dramatic sunset sky behind him."),
 ("capital_big",["v14ref_capital.jpg","sref_14.jpg"],
  "Recreate the first attached image as a closer shot with NO title: a Roblox bacon hair soldier with a big grin stands on top of a captured enemy castle tower planting a huge royal blue crown flag, a crimson star flag falling and burning beside him. "
  "He and the flag are large and fill most of the frame; behind him the conquered capital burns orange at sunset and small blue soldiers climb the walls."),
 ("empire_globe",["v14ref_empire.jpg","sref_03.jpg"],
  "Remake the first attached image with NO title and a closer camera: a Roblox bacon hair ruler in a gold crown, navy coat and flowing red cape stands proudly on top of a large globe covered in royal blue crown flags, arms crossed, smug grin, "
  "sunrise sky with golden light behind, gold coins and blue banners around the base of the globe. The ruler fills most of the frame."),
 ("namerica_flag",["v14ref_namerica.jpg","sref_16.jpg"],
  "Remake the first attached hand-inked parchment map of North America with NO title, zoomed in on the USA: the whole USA is royal blue and a single huge royal blue crown flag is planted in the middle of it, the biggest thing in the image. "
  "Fire and smoke burn along the borders as the blue spreads into crimson red Canada and Mexico, crimson white-star flags toppling. Bird's-eye view, inked mountains and compass rose, no characters."),
 ("fight_territory_big",["v13ref_namap.jpg","sref_16.jpg"],
  "Remake the first attached FIGHT FOR TERRITORY map image with NO title text: the North America map is zoomed in to fill the whole frame, royal blue USA with a blue crown flag versus crimson red Canada with a red flag, one big red arrow and one big blue arrow colliding at the border in a bright gold explosion. "
  "Dark navy sea with inked wave lines, bold borders, bird's-eye view, no characters."),
]
json.dump([[r,s+CLEAN+" "+STYLE] for k,r,s in X],open('v14/v5.json','w'))
json.dump([k for k,_,_ in X],open('v14/keys.json','w'))
print(len(X))
