import json
P=json.load(open('/home/claude/main/art/ads/v12/prompts.json'))
STYLE=P[0]['prompt'][len(P[0]['scene'])+1:]
CLEAN=(" Keep it clean and hand-drawn like the references: few, large, clearly drawn shapes, simple flat cel shading, no tiny repeated crowd detail, no mushy textures, "
       "no glossy 3D or airbrushed look, so it never looks AI generated.")
X=[
 ("rule_the_world_edit",["v13ref_rule.jpg"],
  "Recreate this exact image unchanged, same composition, characters, globe, flags, title and colours, but completely remove the WORLD CONTROLLED 99% bar at the bottom and replace that area with more saluting blue soldiers and the stone platform, matching the rest of the image."),
 ("conquer_birdseye",["sref_16.jpg","sref_03.jpg"],
  "Big title text \"CONQUER THE WORLD\" across the top in the reference title lettering. Below it, a flat top-down bird's-eye view of the whole world map, seen straight from above like a strategy game map, filling the frame edge to edge. "
  "Countries have thick dark borders. Most of the world is painted royal blue with small gold crown flags pinned on capital cities; the remaining countries are crimson red with white star flags. "
  "One single huge glowing blue arrow sweeps from the blue land into the biggest red country, ending in a bright gold impact burst where the border is cracking. No characters at all."),
 ("conquer_birdseye_tokens",["sref_16.jpg","sref_14.jpg"],
  "Big title text \"CONQUER THE WORLD\" across the top in the reference title lettering. Below it, a flat top-down bird's-eye view of the world map seen straight from above, like the map reference, filling the frame. "
  "The royal blue empire with gold crown flags covers the Americas, Europe and Africa; Asia and Australia are crimson red with white star flags. Three small blue soldier unit tokens march across the border into red Asia following one thick glowing blue arrow, "
  "with a gold impact burst and a red star flag falling where they cross. No large characters, the map is the hero."),
 ("declare_war",["sref_07.jpg","sref_12.jpg"],
  "Big title text \"DECLARE WAR\" across the top in the reference title lettering. Split VS layout like the CHOOSE YOUR GOVERNMENT reference: on the left a Roblox bacon hair ruler in a navy uniform and gold crown slams his fist on a war table under royal blue crown banners, "
  "on the right a classic yellow Roblox noob ruler in a crimson coat and crown glares back under crimson white-star banners. A big gold VS medallion in the centre. Between them on the table, a top-down map with little blue and red army figurines facing each other across a border. Only these two characters."),
 ("raid_their_treasury",["sref_04.jpg","sref_12.jpg"],
  "Big title text \"RAID THEIR TREASURY\" across the top in the reference title lettering. A Roblox bacon hair character with a sly grin sprints out of a rival nation's broken-open vault door carrying two bulging gold coin sacks, gold coins spilling behind him. "
  "Behind the vault, crimson banners with a white star. In the background a classic yellow Roblox noob ruler in a crimson coat and crown holds his head in panic. Warm torchlight, stone treasury hall. Only these two characters."),
]
json.dump([[r,s+CLEAN+" "+STYLE if not k.endswith('edit') else s+" Keep the exact art style of the image."] for k,r,s in X],open('/home/claude/main/art/ads/v13/v5.json','w'))
json.dump([k for k,_,_ in X],open('/home/claude/main/art/ads/v13/keys.json','w'))
