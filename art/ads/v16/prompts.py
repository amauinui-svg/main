import json
exec(open('/home/claude/main/art/ads/v14/prompts.py').read().split("X=[")[0])
STY=STYLE.replace("no text, no letters, no numbers anywhere","no other text besides the title and the small numbers described")
LAY=("Layout taken from the first attached reference (only its layout, not its art style): a big title across the top, below it a simple left-to-right game loop diagram on a dark wooden panel with gold trim: "
     "on the left a framed card with a small cost badge and a play button, a big gold arrow in the middle, and on the right the rewards stacked. Clean, readable, few large objects. "
     "Draw everything in the hand-inked comic art style of the second attached image.")
X=[
 ("laws_paid",["v16ref_jobs.jpg","v16ref_laws.jpg"],"Big title \"PASS LAWS. GET PAID.\" "+LAY+" The left card shows a parchment law scroll with a red wax seal and a gold quill, its cost badge is a small purple influence gem with the number 5. On the right: a big stack of green cash bundles, a round gold XP medallion, and a wooden treasure crate with gold trim."),
 ("property_paid",["v16ref_jobs.jpg","v16ref_laws.jpg"],"Big title \"BUY PROPERTY. EARN FOREVER.\" "+LAY+" The left card shows a charming little brick bank building with a royal blue crown flag on its roof. On the right: piles of gold coins and cash with a small clock icon showing it keeps earning, and a gold XP medallion."),
 ("convoy_paid",["v16ref_jobs.jpg","v16ref_laws.jpg"],"Big title \"SEND CONVOYS. GET RICH.\" "+LAY+" The left card shows a horse-drawn supply wagon loaded with crates under a royal blue crown flag on a small parchment map route. On the right: a big stack of cash bundles, a gold XP medallion and a wooden crate."),
 ("raid_paid",["v16ref_jobs.jpg","v16ref_laws.jpg"],"Big title \"RAID RIVALS. TAKE THEIR CASH.\" "+LAY+" The left card shows a crimson enemy treasury vault with a white star banner and a cracked door. On the right: two bulging gold coin sacks, a big cash stack and a gold XP medallion."),
]
json.dump([[r,s+" "+STY] for k,r,s in X],open('/home/claude/main/art/ads/v16/v5.json','w'))
json.dump([k for k,_,_ in X],open('/home/claude/main/art/ads/v16/keys.json','w'))
