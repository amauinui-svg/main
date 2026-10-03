# Idle Country: Ad Creative Research (icon + thumbnails)

Researched 2026-10-02. Sources are linked inline. Confidence tags: [official] = Roblox docs or DevForum staff post, [3rd] = third-party blog (treat numbers as directional), [observed] = I pulled the live Roblox thumbnails via the public Roblox thumbnail API and looked at them.

## 1. Ad formats and exact asset specs

### Formats available
- **Sponsored Experiences (the only one that matters for us).** Bought in Ads Manager, cost-per-play auction, a "play" = click, land on the detail page, then enter the game within 1 hour. [official: [Sponsored Experiences moving to Ads Manager](https://devforum.roblox.com/t/sponsored-experiences-moving-to-ads-manager/2661756)]
- Placements: tiles on **Home** (the "Sponsored" sort, personalised to sit anywhere from row 2 to row 10, which gave +13.4% quality plays) and **search results**. Sponsored in Search was announced as "future" in mid 2025 and the current docs list both Home and search. [official: [Ads Manager docs](https://create.roblox.com/docs/production/promotion/ads-manager), [Ads Manager Updates](https://devforum.roblox.com/t/ads-manager-updates-acquire-new-users-continuous-campaigns-and-more/3862159)]
- Objectives: Maximize Plays (avg cost per play about $0.008 in Roblox's own table), Drive Retention ($0.007), Reactivate Users ($0.011), Acquire New Users (not visited in 180 days), and Maximize Earnings (only for games over a monetization threshold, added May 2026). [official: [May 2026 update](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762)]
- Featured Home tile: managed beta, $5K minimum spend, application only. Not for us yet.
- Other formats exist (Immersive Ads / Portal Ads, rewarded video) but they are for brands advertising inside other games, not for promoting a game. Ignore.
- No separate "image ad" or "video ad" product for game promotion. Video thumbnails exist on the experience page only (3 uploads per month, real gameplay only). [official: [Thumbnails docs](https://create.roblox.com/docs/production/publishing/thumbnails)]
- Third-party guides that say "your icon is the ad creative" and quote $0.10 to $0.50 per click are out of date (they predate the 16:9 switch and the cost-per-play auction). Ignore their pricing. [3rd: [bloxg](https://bloxg.com/guides/roblox-ads-guide)]

### Asset specs
| Asset | Spec | Where it shows | Source |
|---|---|---|---|
| Ad thumbnail | **16:9**, ideally **1920x1080**, png/jpg (also gif, tga, bmp), under 3 MB. Non-16:9 is stretched or auto-resized, so never rely on it. | Sponsored tile on Home and in search. Roblox moved sponsored units from 1:1 (icon) to 16:9 thumbnails: "+57% estimated quality play-through rate" and "up to +40% PTR in Sponsored Sort". | official |
| Thumbnails per campaign | Limit was 5, then 10, **now 25** (May 2026). Roblox splits traffic evenly at first, then shifts spend to winners per audience segment. Asset library accepts 10 files per upload. Over 40% of campaigns already use custom thumbnails (so default art means you compete against the minority that does not bother). | | official |
| AI thumbnails | Ads Manager can generate 3 variations from a text prompt. Not needed, we make our own. | | official |
| Experience icon | **512x512 square**, png/jpg. Roblox's own docs give no icon guidance beyond "thumbnails supplement the game icon". Shown in search results grid, Home recommendation rows, game detail page, favourites, mobile list views, share cards. Renders as small as about 150x150 (in practice less on phones). | Organic discovery. Not the sponsored tile any more. | [3rd: vizzbees](https://vizzbees.com/blog/roblox-thumbnail-size-guide) |
| Experience page thumbnails | Up to **10** images or videos on the page. The first (or the video) is the hero. | After the click. This is the "convince" step, so these are the pictures that must show the mechanics. | official |
| Personalization | Active from **2 or more** active thumbnails, 2 to 5 recommended; Roblox reports **+8.5% average qPTR, some games +50%**. Newer behaviour: a new thumbnail gets a small share of traffic while the existing winner keeps most, so always keep your best performer active when adding tests. Total thumbnails in personalization pool: 5. There is an Open Cloud API for it. No native icon A/B test (as of the May 2026 third party report). | | official: [personalization update](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665), [Thumbnails docs](https://create.roblox.com/docs/production/publishing/thumbnails), [Open Cloud APIs](https://devforum.roblox.com/t/new-opencloud-apis-for-analytics-events-experiments-and-thumbnail-personalization/4828676) |

Note on conflicting numbers: the thumbnail doc page I fetched says "10 per experience page", the Ads Manager docs say 10 per campaign, a 2025 post says 5 per campaign, and the May 2026 post says 25. The newest official post wins for campaigns (25). If the UI shows a lower cap, trust the UI.

### Safe areas
- **Do not put anything important along the bottom edge** of a thumbnail. Roblox overlays metadata (player count, like %) there. [official: Thumbnails docs]
- Practical rule I recommend: keep all key content inside the central 80% (inset about 150 px left/right, 110 px top, and nothing critical in the bottom 20%, about 216 px). Sponsored tiles also carry a "Sponsored" label, so keep the top-left corner clean.
- Icon: Roblox's tile crops and rounds corners. Keep the subject inside the central circle (about 80% of the width). Per Kash's own preference: deliver icons as 16:9 images with the full design inside the centre square and only filler on the left and right.

### Moderation and content rules
From [Advertising Standards](https://en.help.roblox.com/hc/en-us/articles/13722260778260-Advertising-Standards) and the Ads Manager docs [official]:
- No deceptive or unrealistic claims. Explicitly: **no "free Robux"** style offers. Treat any "FREE", "win Robux", "giveaway" text as a rejection risk. Also avoid Robux logo imagery in the ad art; I found no explicit ban on the Robux icon, but no rule says it is allowed in ad creative either, and it reads as a Robux lure. Do not use it.
- Do not mimic system UI: no fake buttons, notifications, "Play" or "Join" buttons, fake chat or fake reward popups that look like they belong to Roblox itself. (In-game UI showing your own game's cash counter is fine and is standard.)
- Must show the game truthfully. For the experience page, video rules say no misrepresented mechanics, no artificially enhanced graphics, no advertisement text or subjective claims ("best game ever", "#1"). Apply the same standard to still images: only show things that exist in the game.
- Content bans: violence or gore, weapons, gambling, sexual or romantic content, hate. **Our FIGHT screen needs care:** show cartoon impact stars, damage numbers and a crit burst, not blood, realistic guns or a character being hit in the face. Cartoon swords, cannons and flags are fine; realistic modern firearms are the risk. Ads shown to under 18 cannot say "only" or "just" about prices.
- Moderation takes up to 24 hours per ad and up to 48 hours for assets uploaded to the library. Rejected assets can be appealed.
- Games whose metadata and place files closely resemble existing games are deprioritised. Idle Country is explicitly modelled on Idle Mafia, so the icon, title and thumbnails must be visibly different from Idle Mafia's (see section 3).

## 2. What drives CTR on Roblox icons and thumbnails

### Benchmarks (all rough)
- Roblox official: 16:9 sponsored tiles +57% qPTR vs the old 1:1; personalization +8.5% avg qPTR (up to +50%); personalised thumbnails cut impressions on losing thumbnails by 21%. [official]
- Typical organic qPTR about 2 to 2.4%, top games about 3.6%. [3rd: [vizzbees](https://vizzbees.com/blog/how-to-make-a-roblox-thumbnail)]
- One developer's anecdote: a winning thumbnail got 2% QCTR, and 9 other attempts all sat near 0.65%, meaning one concept can be 3x better than the rest, so test concepts, not tweaks. [3rd: [DevForum](https://devforum.roblox.com/t/roblox-game-thumbnails-how/4158217)]
- Third party ad guide: 1 to 2% CTR good, 3%+ great, 5%+ exceptional, and a 1 point CTR lift can halve cost per player. Directional only. [3rd: bloxg]

### Patterns that consistently show up
1. **One focal point, one action.** One character or object dominates; a six-tile row on Home punishes busy art. [3rd: [qptr.io blog](https://qptr.io/blog), vizzbees]
2. **Mechanic in one glance.** The icon must signal genre (a thumbnail that is "impressive but vague" and an invisible genre signal are the top two icon mistakes). [3rd: [creatorxp](https://creatorxp.gg/guides/roblox-game-icon-mistakes)]
3. **Exaggerated emotion on a face.** Wide eyes, open mouth, smug grin. Faces and dynamic poses convert better than static scenes. [3rd: vizzbees]
4. **Progression and big numbers for simulators and tycoons.** The qptr.io analysis of simulation thumbnails calls the formula "the tiny starter next to the absurd endgame", with big numbers, glowing upgrades and before/after contrast. [3rd: [qptr.io](https://qptr.io/thumbnails/simulation)] This is exactly the owner's "Wave 1 to Wave 99" and "971,567,854" notes.
5. **Saturated colour, high contrast, simple background.** Blue sky, green grass, gold, red. Dark realistic palettes blend into the feed. [3rd]
6. **Text: none, or 2 to 4 huge words.** Tiny text disappears at feed size. Numbers count as text; make them huge with thick outline.
7. **Design for the smallest size first.** Test the icon at 128x128 (or smaller). Test thumbnails at about 384x216 in a row of competitors. Free preview tool: [qptr.io](https://qptr.io/blog) shows your art on a fake Home page next to real games.
8. **Title and icon must match, and the first 60 seconds must deliver the promise.** Over-promising hurts retention, and weak retention hurts recommendations and ad efficiency. [3rd: creatorxp]
9. **Do not copy a hit too closely** (clone perception) and Roblox deprioritises near-duplicate games. [official + 3rd]
10. **Keep a consistent look across icon, thumbnails and in-game UI**, so players who click from an ad feel the same game. [3rd]

### Roblox-avatar style vs painted art
My own look at the live competitors (see section 3) says: the cash-simulator and tycoon leaders that sell on mass appeal (Sell Lemons, Build a Country, Steal An Egg) all use **glossy, rendered 3D Roblox avatars (classic bacon-hair or simple default avatars) with bright backgrounds, arrows and big numbers**. The only strong painted/illustrated example in our space is Idle Mafia itself, and it is dark, vintage and text-led (and it has about 4,400 players concurrent, vs hundreds of thousands for the avatar-style hits). Painted art is fine for the experience page gallery, but the **icon and the first thumbnail should lean toward the bright, avatar-with-emotion look** that the Home feed rewards. A blend works: Roblox-style avatar characters in our painted-cartoon world.

### Red arrows, text and A/B testing
- Red arrows and "YOU!" or "!!" marks are the current dominant trope on high-traffic Roblox tycoon thumbnails (Steal An Egg uses a curved red arrow plus "YOU!" on every thumbnail). Per Kash's own rule: at most one arrow, running from the text to the character.
- A/B: use the thumbnail personalization (2 to 5 active, or up to 25 in an ad campaign). Keep the current winner active. There is **no native icon test**; the workaround is to upload the icon concept as a 16:9 thumbnail and let the thumbnail test decide, or run small sponsored budgets per icon variant and read PTR. Do not change the icon mid-launch without noting the date, or analytics become unreadable. [3rd: creatorxp] Budget approach from a third party: start small ($10 to $20 per day for 3 to 5 days), keep 80% on proven creative and 20% on new. [3rd: bloxg]
- Open Cloud has a thumbnail personalization API for scripted rollout. Experiments in Creator Hub are in-game config tests only, not creative tests.

## 3. Competitors: what their art actually shows

Pulled live from the Roblox thumbnail API and viewed. Concurrent players are as of today.

| Game | Players | Icon | Thumbnails | Take-away |
|---|---|---|---|---|
| **Idle Mafia Game** (our model, 4.4K CCU, 25.6K likes) | 4.4K | Flat vintage-poster: huge cream title "IDLE MAFIA GAME" with gold outline, over a dark red room and a gold-outlined pistol. No characters, no emotion. | 1. Same title card. 2. Real UI screenshot of the territory map. 3. "BUILD YOUR EMPIRE" with hands over a miniature isometric city. 4. "COLLECT LOOT" with gacha cards (Secret, Epic, Rare, Legendary) and a glowing chest. Moody dark red/black/gold. | Strong text-led pitch but cold. A bright, emotional, character-led icon will contrast with it. Reuse the idea: one thumbnail per pillar (build, loot cards, map) with a 2 word headline. Do NOT reuse dark red/gold or a gun. |
| **Sell Lemons** (13.6K) | | 3D avatar from behind, standing on a mountain of cash and lemons, black hole and UFOs in the sky, logo top. | Same hero scene, then plain in-game screenshots with logo top-right. | Hero-from-behind staring at an absurd mountain of money = "huge wealth, you are small". Great fit for our number-goes-up promise. |
| **Build a Country** (1.6K, "SOON") | | Avatar worker builds a fighter jet, "$6,782,567/s" huge top-left. | 1. Giant smirking avatar between two skyscrapers over a city. 2. PEACE (wheat farm, workers) vs WAR (rows of tanks and jets) split panel. 3. US tank firing an arc at a tiny Chinese tank labelled "1%". 4. Countryball (Philippines) giant over a small tiny island city vs a tiny US ball. | The closest competitor on theme. Borrow: split panel progression (peace to war = hut to skyscraper), giant-vs-tiny scale contrast, income number in the corner. Avoid: tanks on an empty green baseplate and the 1% gag. |
| **Rise of Nations** (1.7K, 268K likes) | | Flat black icon with a red globe and gold star, grey title. | Flag-shaped country with policy panels: "Lead your nation", "Expand your influence" (yellow arrow across a globe), "Research", "Reform the past". Real flag textures on country shapes; mostly UI-dense. | Flags on country silhouettes read instantly as "nations game". Their UI-dense, dark look is weak on emotion, so it is a differentiator for us to be bright and human. |
| **Military Tycoon** (2.4K, 1.28M likes) | | Photoreal jet over desert, gold winged logo bottom-left. | Realistic vehicles and avatar soldiers in painted-render style, logo overlay. | A logo plate in a corner is standard. Realistic weapons are fine there but we should not go that route (moderation and tone). |
| **WW3 Commander / Missile Tycoon** | | Missile launch against blue sky. | Missiles, silos, drones. | Shows how a single bold object (rocket arc) makes a clear icon. We can use a cannon or rocket-flag for the FIGHT beat only if cartoony. |
| **Countryball World** (3.4K) | | Cluster of cute country-ball faces in hats. | Cute scenes with characters. | Flag-faced mascots with big eyes are an easy way to put emotion on a "country". Optional: a flag-ball mascot as the icon character (but Build a Country already uses them). |
| **Steal An Egg** (1.7M CCU, outlier) | | Egg and hourglass "24 HOURS". | Every thumbnail: avatar with exaggerated emotion (smirk or panic), a creature, red curved arrow, "YOU!", "!!", income "$89,121/s", bright saturated backgrounds. | The current template for top-of-feed Roblox thumbnails: character emotion + threat + arrow + earnings number. Copy the grammar, not the content. |

What to borrow: (1) big per-second or total number in a corner; (2) hero avatar with a clear emotion; (3) peace/war or small/huge split panels for progression; (4) title logo plate in a corner, 2 words max; (5) one thumbnail per mechanic, as Idle Mafia does.
What to avoid: dark red and gold mafia palette; green empty baseplate; UI-wall screenshots as the lead image; realistic firearms.

## 4. Recommendation for Idle Country

### Shared visual rules (apply to everything)
- World: bright painted-cartoon, thick dark outlines, sunny sky gradient (cyan to warm cream), gold and royal blue accents, flags in saturated primaries. No dark palettes.
- Characters: Roblox-style blocky avatars (classic bacon hair or simple default) with a real-looking Roblox face decal (one face for all characters, per Kash's rule; only break it for an emotional contrast). A crown, sash or small flag cape marks "the leader". Maximum 1 or 2 avatars. No crowds.
- Only show things that exist in the game: income-bar buildings, cash numbers, the FIGHT screen, crates and officers, the world map, flags.
- Numbers and title are added in code (crisp). Reserve clean areas for them.
- Nothing key in the bottom 20%. Nothing in the top-left 12% (sponsored label).
- Text: max 1 headline of 1 to 3 words per image, or none. No "FREE", no "Robux", no "#1".

### Icon concept (primary): "The Tiny Leader"
- **Mechanic + emotion:** laws and growing economy, with wide-eyed delight.
- Composition: close-up of a Roblox-style avatar in a small gold crown, mouth open in an excited grin, holding up a giant glowing gold coin or a fistful of cash. Behind him a flag on a pole and one chunky isometric building stack rising from a hut at his feet to a skyscraper behind (the progression, in miniature). Warm sun burst behind the head. A single huge "$" or "+$" burst, no other text.
- Colours: sky cyan background, gold, royal blue sash, one red flag for contrast.
- Must read at 128 px: the face and crown, the gold coin, the sun burst. The buildings are secondary and may blur.
- Add in code: optional tiny "IDLE COUNTRY" logo plate in the lower third of the centre square (at icon size it is unreadable, so it is a nice-to-have only).
- Format: 16:9 file with design in the centre square (per Kash's rule), left and right filled with the same sky or flag pattern.

### Icon alternates (for A/B)
- **Alt A, "Flag on the Hill":** huge waving flag on a hilltop with a hut at the bottom and skyscrapers cresting the horizon; a tiny avatar planting the flag, arms up. Less face, more nation. Tests "nation" vs "face".
- **Alt B, "Cash vs Crown":** avatar from behind (like Sell Lemons) standing on a mountain of gold bars and cash looking at a glowing miniature world-map city skyline, with a sun burst. Tests "wealth awe" vs "emotion".

### Thumbnail set (5 to 6; keep to 2 to 5 active at a time for personalization, rotate winners in)

1. **Hero progression: "Hut to World Power"** (mechanic: build properties and eras; emotion: awe)
 - Subject: 3 panels left to right (like the owner's Wave 1 / Wave 15 / Wave 99 example): tribal hut with a small flag, then medieval castle, then glass skyscraper city. Same avatar leader in each, getting a bigger crown and cape, face going from worried to smug.
 - Number: income per second in a corner of each panel in code ($5/s, $5,400/s, $971,567,854/s).
 - Background: each panel has a different era sky (dawn, dusk, noon), bright. Thick white dividers.
 - Text: none, or "HUT TO SUPERPOWER". Must read small: the 3 size steps and the smug face.

2. **The Raid: "Steal Their Cash"** (mechanic: 3-hit FIGHT raid; emotion: panic vs glee)
 - Subject: split scene. Left: our avatar mid-swing with a cartoon mace or giant gavel, grin. Right: victim avatar scared (hands on cheeks) behind a wall of sandbags with a small flag. A crit starburst reading "CRIT!" and a big damage number mid-air, three cash bills flying toward our side.
 - Number: damage "-4,821,000" and stolen "+$2.4B" (code).
 - Colours: orange impact star, cyan sky, grass green. No blood, no realistic guns, no one hit in the face. Fits the owner's "scared noob behind a wall" note.
 - One red curved arrow from the text "YOUR CASH" to the victim only if needed (max 1).

3. **Gacha Reveal: "Rare Officer"** (mechanic: crates and officers; emotion: shock/joy)
 - Subject: avatar with eyes wide, jaw dropped, in front of an opening golden crate with a beam of rainbow light; an officer card (cartoon general with gold epaulettes) rising out, a "MYTHIC" ribbon on the card. Confetti.
 - Number: none (or card ATK number in code).
 - Style note: Idle Mafia shows loot cards on a dark background; ours is bright and the reaction face does the work. Rarity colour bar (grey, green, blue, purple, gold) along the card edge.

4. **World Map Conquest: "Capture New York"** (mechanic: alliance captures real cities; emotion: triumph)
 - Subject: stylised painted world map top-down with 3 glowing landmark icons (Statue of Liberty, Big Ben, Tokyo tower), our flag colour flooding outward from one city, rival colours shrinking. A giant avatar leader looks down from the top edge with an arms-crossed smirk (scale contrast like Build a Country).
 - Number: "12 / 40 cities" tiny alliance counter in code.
 - Safe area: landmarks in the centre band only.

5. **Number Go Up: "$971,567,854"** (mechanic: laws earn money; emotion: disbelief)
 - Subject: avatar half-submerged in a golden tide of cash, shocked face, holding a single stamped "LAW PASSED" scroll. Huge cash number floating above. Money rain.
 - Number: giant "$971,567,854" in code with thick outline, top centre.
 - This is the owner's "Lift a Cube 971,567,854kg" pattern. Probably the highest-CTR candidate; make it the first test.

6. **Weekly Boss Takedown / Alliance** (mechanic: alliance boss; emotion: teamwork and hype)
 - Subject: 4 avatars of different colours, all with the same face, standing on a hill facing one giant cartoon boss (a huge stone statue or a giant crowned dictator in a big top hat, cartoon) with a health bar over it. Shout "BOSS" tag.
 - Number: boss HP "98,000,000,000" in code. Keep avatars to 3 or 4 max since this is the one concept where a group is the mechanic (alliances).
 - Optional replacement: Convoy thumbnail (trucks and ships connecting NYC to London), but it is lower priority because it is hard to read in one glance.

Priority order for the first test: #5, #1, #2, then #3, #4, #6. Run 3 or 4 at once in an ad campaign with the same icon; read PTR after about 3 to 5 days.

### Prompting notes for gpt-image-1
- **Output size:** gpt-image-1 outputs 1024x1024, 1536x1024 (3:2) or 1024x1536. There is no native 16:9. Generate 1536x1024, leave the extra height as empty sky or ground, then crop to 1536x864 and upscale to 1920x1080 (or generate with generous top and bottom padding and crop). Do not ask the model for 16:9 text; it will not honour it.
- **Avatars:** ask explicitly for "Roblox-style blocky avatar, classic Roblox character proportions (cube head, rectangular torso, blocky arms and legs), glossy 3D render look like a Roblox GFX thumbnail" and specify the face: "simple Roblox default smile face decal, flat painted face, not realistic". For the shock/panic faces say "Roblox face decal with wide open eyes and open mouth". The model drifts toward realistic or AI-looking faces, which Kash's preference explicitly rules out, so prefer **passing a reference image** of the real Roblox face (images/edits endpoint with the face image) or compositing the real face decal in code afterwards.
- **Matching existing art:** per Kash's rule, feed the actual existing game screenshots or building icons as reference images to the images/edits endpoint rather than describing the style. Use the in-game building art (hut, castle, skyscraper) and flag art as references so thumbnails match the real game.
- **Text and numbers:** tell the model "no text, no letters, no numbers anywhere in the image" and "leave a clean empty area in the top third (sky only) for a headline, and a clean area above the character for a big number". Add all text, damage numbers, income numbers and the logo afterwards in code (Pillow or canvas) with a thick dark outline and drop shadow. gpt-image-1 garbles long numbers like $971,567,854.
- **Composition language:** "single focal character, three-quarter close-up, subject fills 60% of frame, centred in the middle 80%, nothing important in the bottom 20%, bright saturated colours, thick outlines, soft rim light, simple background, no clutter". Add "no crowds, no clones, no extra characters" unless the concept needs them.
- **Negative content:** "no blood, no realistic guns, no Robux logo, no fake UI buttons, no watermark".
- **Consistency:** reuse a locked style paragraph and the same reference images across all thumbnails; generate 3 to 4 variants per concept and reject any with extra limbs, odd faces or objects that do not exist in the game.
- **QA before upload:** (1) shrink to 384x216 and to 128x128 and check it still reads; (2) paste into a [qptr.io](https://qptr.io/blog) fake Home page beside Sell Lemons, Idle Mafia and Build a Country; (3) check against the safe areas; (4) check for moderation red flags (free offers, Robux, fake buttons, weapons, blood).

## Sources
- Roblox Creator Hub: [Ads Manager](https://create.roblox.com/docs/production/promotion/ads-manager), [Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails), [Experiments](https://create.roblox.com/docs/production/experiments)
- Roblox Help: [Advertising Standards](https://en.help.roblox.com/hc/en-us/articles/13722260778260-Advertising-Standards)
- DevForum: [Sponsored Experiences moving to Ads Manager](https://devforum.roblox.com/t/sponsored-experiences-moving-to-ads-manager/2661756), [Leveling Up Ads Manager](https://devforum.roblox.com/t/leveling-up-ads-manager-with-new-features/3587640), [Ads Manager Updates: Acquire New Users](https://devforum.roblox.com/t/ads-manager-updates-acquire-new-users-continuous-campaigns-and-more/3862159), [Ads Manager Updates May 2026](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762), [New Advertising Policies and Standards](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365), [Thumbnail personalization remembers winners](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665), [Testing personalized thumbnails](https://devforum.roblox.com/t/testing-personalized-thumbnails-in-home-this-july/3039419), [Open Cloud thumbnail personalization API](https://devforum.roblox.com/t/new-opencloud-apis-for-analytics-events-experiments-and-thumbnail-personalization/4828676), [Roblox game thumbnails, how?](https://devforum.roblox.com/t/roblox-game-thumbnails-how/4158217)
- Third party: [vizzbees thumbnail guide](https://vizzbees.com/blog/how-to-make-a-roblox-thumbnail), [vizzbees size guide](https://vizzbees.com/blog/roblox-thumbnail-size-guide), [creatorxp icon mistakes](https://creatorxp.gg/guides/roblox-game-icon-mistakes), [qptr.io simulation thumbnails](https://qptr.io/thumbnails/simulation), [qptr.io blog](https://qptr.io/blog), [bloxg ads guide](https://bloxg.com/guides/roblox-ads-guide)
- Competitor art: Roblox public search and thumbnail APIs (universe IDs: Idle Mafia 10643795368, Rise of Nations 918677693, Military Tycoon 2788648141, Countryball World 1954152886, Sell Lemons 7395930870, WW3 Commander 10299762956, Build a Country 10200442730, Steal An Egg 10563114921).
