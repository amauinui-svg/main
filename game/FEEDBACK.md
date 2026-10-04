# Idle Country: Kash's feedback log
Every request Kash makes is written here so he never has to repeat it. Status: OPEN / ASKED / DONE.

## 1 Oct 2026 (after first playable build: "working very flawlessly")
1. OPEN - Map: a sent convoy shows only its icon. Wants a clear dotted line from origin to destination with a clean
   animation, so travel feels like visible progress (not an icon jumping every tick).
2. OPEN - Laws unlock too fast: 4-5 laws available on join. Rule: ONE law per level at most, never more than one.
3. OPEN - Battle: rivals are placeholders (fine for now). At launch every server gets ~3 AI players so new players can
   try attacking. Battle list must NOT be refreshable; players can only attack the people in their own server.
4. OPEN - Bank: players can DEPOSIT cash; each deposit costs a 10% fee; deposited cash cannot be stolen by other players.
5. OPEN - Daily tasks: needs ~3x the variety. Add WEEKLY challenges with very good rewards that take a lot of playtime.
6. OPEN - Return pop-up with a daily login sheet: a reward every day the player comes back; day 7 is a big reward.
7. OPEN - Monetization: lean on repeatable developer products (like eggs in his best game, buyable free-to-play or
   with Robux). Wants a limited-time crate players can buy. Find more ideas like this.
8. Process: Studio is closed, no build work now. Ask questions ONE BY ONE before building.

## Answers (1 Oct)
- Q1 Raids: YES, cash is stolen from real players. Winner takes 10% of the defender's cash on hand, with a cap
  (planned: at most ~1 hour of the defender's own law income per raid), banked cash is safe, the defender is notified,
  and each player can be raided at most once every 15 minutes. The 3 AI players per server follow the same rules.
- Q1b Raid cooldown: about 1 MINUTE (not 15). Read as: the same player can be raided again after ~1 min.
- Q2 AI players FIGHT BACK (raid real players too) so every server feels alive even when people don't attack each other.
  NO "bank your cash" nudge: players should discover the bank on their own.
  YES a REVENGE nudge: the raid notice offers a one-tap revenge attack on whoever raided you.
- Q3 Bank: withdraw is free (yes). Players EARN INTEREST on their bank balance (yes). NO deposit cap.
  NO buying straight from the bank: players must withdraw first. Loan system stays as is.
  UI rule (all screens): cut descriptions down. Put details behind a small "i" icon (letter i in a circle) that
  players hover or tap to open a short tab explaining that system.
- Q4 Bank interest: 1.5% per hour (planned: paid every minute online, half rate offline, offline capped at 12 h).
- NEW (Kash idea): alliance leaders can set a JOIN FEE (cash to join, goes to the treasury) and optional DUES
  (a rate charged for staying in the alliance). Goal: more diverse kinds of alliances.
- Q5 Dues: PERCENTAGES confirmed by Kash. Percentage of members' earnings (0-10%, to the treasury). PLUS a political option: the leader chooses
  whether higher levels pay more, lower levels pay more, or everyone pays the same.
  Planned: leader sets a base % and a style (Flat / Progressive: higher levels pay more / Regressive: lower levels
  pay more), each member's rate scaling from half to double the base by level within the alliance, never above 15%.
  Join fee is a flat amount shown on the alliance list. Both change at most once a day.
- Q6 Daily login sheet: PAUSE, not reset. A missed day keeps your place; day 7 = big gold reward + free crate.
- Q7 Crates: YES to collectible advisors/leaders/generals (name not decided). Details from Kash:
  * Military tab soldiers stay as they are.
  * SOLDIERS DIE after battles (attacking AND defending); losses depend on how the battle went
    (close fight, sweep, loss or win).
  * ADVISORS NEVER DIE in battle. Advisors give % boosts and can be equipped with WEAPONS and ARMOR.
  * THE PLAYER IS ALSO AN ADVISOR (their own leader slot that can wear gear).
  * Crates give advisors and gear (weapons, armor). Kash feels something else is missing that crates could give.
- Q8 Name: OFFICERS (chosen). Map cosmetics (convoy skins, pins, flag emblems, titles) = YES as monetization, but Kash
  wants ONE MORE system that actually BENEFITS the player (beyond alliance, laws, buildings, army, officers+gear).
  He feels something is still missing. (Options proposed in Q9.)
- Q9 Kash likes RESEARCH but worried about complexity. Proposed: merge Skill Points INTO Research (same tab count).
  Awaiting decision (Q10).
- NEW: INVENTORY tab to track all gear owned (weapons, armor, officers...).
- NEW (later): PLAYER-DRIVEN MARKET. Gear has no fixed value; buyers place BUY ORDERS (bids) for a specific item at
  their price; sellers just click their item -> SELL, and it instantly sells to the HIGHEST bid (no choosing between
  orders). "Something is only as valuable as someone is willing to pay for it." Kash: trading rounds out the game.
- Q10 RESEARCH: NOT now (maybe later). Skill Points stay as they are.
- Q11 Robux: ALL repeatable products approved, INCLUDING Revenge Strike: limited-time weekly crate (1/3/10, 10-pack
  guarantees Epic+), gold packs (50/250/1000), Treasury Grant (~2 h income, level-scaled), Supply/Influence refills,
  Raid Shield (4 h), Instant Army, Finish Convoy, Revenge Strike. Passes: existing 4 + Officer slot, VIP, 2x crate luck.
  Free path: cash-bought basic crate, gold from bosses/tasks/login/weekly.
  Crates: Kash is fine with either two variants (gold crate + Robux crate) or ONE crate with TWO PRICES (Robux or gold).
  Chosen: one crate, two prices (gold OR Robux), so free and paying players chase the same items.
- Q12 Weekly challenges: APPROVED as proposed (5 per week, reset Monday, big gold + crate each, weekly chest with
  guaranteed Rare+ for all 5; daily pool grows to ~20).
  NEW monetization: REFRESH a challenge. One FREE refresh per day (swap one task you don't want); extra refreshes
  cost a small repeatable product (~25 Robux).
- Q13 Soldier losses APPROVED: sweep winner ~2% / loser ~20%; clear win 5% / 15%; close fight 10% / 12%.
  Defenders lose too. Cheapest soldiers die first. Losses shown on the result screen and raid notice with REBUILD.
- Q14 OFFICERS (Kash's design, replaces my circle layout):
  * Plain stacked PANELS: the PLAYER is always the top panel; officer slots listed below.
  * Start with 1 officer slot. Each extra slot costs money, and every slot costs more than the last.
  * Officers are generated: a RARITY plus a set of random TRAITS (more money, attack, defense, fewer soldier deaths,
    etc.). Number/size/type of traits scale with rarity; rarer = better.
  * HIRING has 3 options: CHEAP, MEDIUM, EXPENSIVE. Same prices for every player (NOT level-scaled); EXPENSIVE is
    extremely late game. Better tiers = better odds of rarer officers and different traits.
  * NO duplicates and no merging: every hire is a unique officer with its own name.
  * Players can FIRE officers; firing gives nothing back.
  * So both unlocking slots and hiring officers cost money.
  (Assumed "money" = in-game cash; confirm. Weapons/armor still equip on the player and officers.)
- Q15 "Money" = IN-GAME CASH: officer slots and hires cost cash.
  Crates: mainly REALLY COOL GEAR, but can still give officers. The FIRST crate includes officers, gear, etc.
  NEW: STARTER/LIMITED BUNDLE at 999 Robux: a limited gear piece with good buffs + a limited officer.
  PRICING RULES (all Robux prices): charm prices ending in 9 (9 not 10, 99 not 100, 999 not 1000).
  Bulk must be cheaper per unit to push the bigger option, e.g. 1 crate 25 -> 5 crates 99 (not 125).
- Q16 PRICE SHEET APPROVED, except Revenge Strike raised 29 -> 49 Robux.
  Products: crate 1/3/10 = 29/79/229; gold 50/250/1000 = 49/199/699; Treasury Grant 49; Influence/Supply refill 19;
  Raid Shield 4h 39; Instant Army 49; Revenge Strike 49; Finish convoy 9/19/29/49; Challenge refresh 19;
  Move Capital 99; Limited Bundle 999.
  Passes: Express 249, Auto Dispatch 399, +2 Convoys 199, +3 Lots 149, Bonus Officer slot 299, VIP 499, 2x Crate Luck 349.
- Q17 ART: crates, gear and officers in the SAME art style, but they must look really cool and STAND OUT from
  everything else: add VFX / auras (rarity glow, shimmer).
- GO (1 Oct, 16:20): start the autonomous pass. Kash asked me to create ALL game passes and developer products in the
  Creator Dashboard via the built-in browser, and wire their ids into the game. Studio is open.
- NEW (16:40): a COUNTRY tab. Shows a nice image of what your country looks like (changes with the ERA), your level and
  a few other stats, and the stat upgrades (skill points) live here, so there is no separate Skills tab.
- NEW (16:45) REFERENCE SCREENSHOTS from the competitor (Idle Mafia): loading screen, Safehouse, Crew, locked slot,
  hire tiers, hire odds, inventory, properties. What Kash wants copied:
  * COUNTRY tab like their SAFEHOUSE: a big wide scene image on top, then a title bar ("DOCKSIDE WAREHOUSE",
    "SAFEHOUSE LEVEL 5 OF 16", "+12% income/attack/defense", NEXT: ... REQUIRES LEVEL 30), then daily playtime
    rewards row, then YOUR STATS / YOUR UPGRADES.
  * OFFICERS like their CREW: header with count, +ATTACK, +DEFENSE, size bonus; UNEQUIP ALL / AUTO EQUIP BEST;
    one ROW per member (YOU on top, gold border): portrait, name + rarity, attack/defense, a box per equipment
    slot (item image + name + rarity, border in rarity color), AUTO ROLL, DISMISS, move up/down arrows.
    EMPTY SLOT row: HIRE ODDS + 3 tier buttons (Street $10K / Professional $10M / Elite $10B).
    LOCKED SLOT row: "Each slot costs more than the last" + UNLOCK SLOT $price.
  * HIRE ODDS popup with 8 rarities: common, uncommon, rare, epic, legendary, mythic, secret, forbidden, and an
    "Increase your luck!" button (their luck pass is 520 Robux). Copy their odds.
  * INVENTORY: filter tabs (All, Weapons, Armor, Crates, ...), rarity dropdown, a grid of cards: type tag, item
    IMAGE, xN count, name, stat line, rarity bar at the bottom, border in rarity color.
  * PROPERTIES: square tiles with illustrated isometric buildings on a dark textured ground, name tag on top, $/hr
    + progress at the bottom; HOVER LIFTS the building off the ground; nice FOR SALE (+ Tap to Build) and LOCKED
    (fence + padlock) tile backgrounds.
  * ALL items are real IMAGES. Art should look like painted/generated illustrations ("actual photos that are either
    generated or designed"), not flat vector icons. My round 2 images were "not the greatest".
  * Make the game feel much more polished/published. Use Claude Design if possible, otherwise find a better way.
- ART DECISION (16:46): BOTH. I ship detailed drawn art now so the game works; I also write a prompt pack so Kash can
  generate painted images (ChatGPT/Gemini/Midjourney) and I swap them in as they arrive.
- NEW (16:47) ALLIANCE tab like their FAMILY > TAKEDOWN (our own version):
  * Sub tabs (Overview, Members, Perks, Takedown, War, Audit log, Manage, Browse).
  * WEEKLY TAKEDOWN: a big illustrated scene with enemy characters (name + HP bar each), YOU portrait + HP and a big
    ATTACK button (GET TICKETS when out), 5 STAGES along the bottom with progress.
  * Header boxes: FREE ATTACKS 7/10 (+1 per hour), TICKETS (used after free attacks), YOUR WEEKLY DAMAGE + rank in
    the alliance. Buttons: REWARDS, LEADERBOARDS, RECENT ATTACKS (popup log, "BIG HIT" crits).
  * TICKETS come from a separate task currency: their CONTRACTS tab has Daily (easy/medium/hard + a bonus for all 5)
    and Weekly tasks (+ bonus for all 5) that pay SEALS + cash, a free REPLACE per task, and a CONTRACTS SHOP where
    seals buy tickets etc. Seals are separate from gold and are not tradable.
- NEW (16:50) POLISH + MASTERY:
  * Building a property shows a construction image (tarp-covered frame) that bobs up and down with image-based smoke
    puffs and a BUILDING progress bar. Small detail, big feel. Copy this kind of polished animation everywhere.
  * JOB MASTERY (copy for our LAWS): each law has Bronze/Silver/Gold medals (little metal medal icons, hover shows a
    tooltip). Their numbers: Bronze ~ +5% cash; Silver (50 times) +10% cash, 5% less energy; Gold (100 times) +15% cash,
    5% less energy, +1 SKILL POINT. A "Mastery 47/50 to Silver" bar under each job. Gives a reason to do every law.
  * IMAGE GENERATION must be AUTONOMOUS: find an app/API so I generate, review, import and wire images myself,
    instead of Kash generating by hand.
- NEW (16:54) TWO VIP PASSES (both give a VIP CHAT TAG):
  * VIP ~499 Robux: more cash and faster Influence/energy regen.
  * MEGA VIP ~899 Robux: +25% cash, +25% energy (Influence) regen, and a unique LIMITED officer.
  * PLAYER PROFILE popup (like theirs): big avatar with level badge (VIP badge, ranking border frames, cool themed
    backgrounds), EQUIPPED gear tiles, alliance + role, STATS (power, attack, defense, officers), ALLIANCE
    CONTRIBUTIONS, rankings chips, LAST ACTIVE / ONLINE NOW, SCOUT button, red ATTACK button. You can attack anyone
    from the RANKINGS (Players / Weekly / Alliances; Top power/cash/property value/level/wins; podium for top 3,
    "Your standing", ranking border rewards Top 1/2/3/10/100 giving +attack/+defense). "You were scouted" toast.
  * Asked if OpenAI is the easiest/cheapest autonomous route; he got OpenAI free daily tokens.
- NEW (17:22) CONVOYS + META:
  * Distance alone should NOT mean more pay. Pay depends on going to a DIFFERENT REGION with different resources
    (Europe->Asia, Americas->Asia, Asia->Africa pay a lot).
  * WANTS change with player activity: each convoy sent to a capital adds a tick for that good; after enough ticks
    the capital switches to wanting something else. The payout is LOCKED when you send, so it never changes en route.
  * Convoy icon by terrain: land icon on land, boat on water; later eras use trains, cars, better ships, rockets.
  * LATER (once tuned): scale everything into multiple stages for hours of progression.
  * PREMIUM bonus for Roblox Premium players. A GAME DESCRIPTION. GROUP bonus + join-group popup.
  * FAVORITE popup: shown behind the scenes after a big achievement (also on later sessions, e.g. day 3, 5th visit),
    max once per session, never if already in the group/favorited.
  * SETTINGS button top-right: many quality-of-life settings, a CHANGELOG (date + version per entry) and a GAME
    INFO/mechanics guide that uses images and colors as much as possible. All polished and clean.
- NEW (18:33) MAP: the Capitol world map must LOOP horizontally like a globe: scroll past the left edge and you see
  the right side, and routes (dotted paths) that cross the edge continue across it (moving left works too).
- NEW (18:41) POLISH ROUND:
  * Pop-in animations (crate reveal, officer hire, etc.) grow from the TOP-LEFT corner to the bottom-right. They must
    scale from the CENTER ("from far away towards me"). Fix for ALL animations. Kash likes the animations otherwise.
  * The settings button overlaps text on Capitol, Laws and other tabs (panel subtitle, map city panel).
  * $4.7B after a few hours: check that Auto Dispatch convoys aren't too strong (much of that was test money).
  * The pulsing circle aura (e.g. Day 7 Founder's Crate) looks AI-made. Use the classic Roblox ROTATING BEAMS
    (sunburst rays behind the item, like game pass art), tinted, rotating. Open to a better idea.
  * SOUND: find top-quality SFX in the Roblox Creator Store (the kind top games use, popular ones from other games),
    picked meticulously, and background MUSIC (no per-era switching). Non-copyright preferred, but quality and theme
    fit beat non-copyright.
- NEW (18:44) LIVING PROPERTIES: competitor's property images have small animated details (lights flicker or pulse
  slowly, sparks from a broken car). Add subtle effects like this to our buildings.
- NEW (18:47) RAID FIGHT SCREEN (like their FIGHT popup): both icons (my avatar + the target's), level badges,
  attack (attacker) / defense (defender) power, equipped WEAPON image beside each (FISTS if none; AI/enemy show
  theirs). Three exchanges: attacker hits, defender hits, x3. Usually on the third hit either the attacker finishes
  them before the defender's 3rd hit, or the defender lands the killing 3rd hit. Crits rolled per hit. Damage
  flashes the icon red, shows the number and an impact effect (bullet hole / slash). Each side shows a damage RANGE
  (e.g. 225 to 337) with a marker for where each roll landed. TAP TO SKIP. End: VICTORY/DEFEAT + rewards + DONE.
- BALANCE (18:47): the $4.7B in Studio was mostly my test money (I set cash to $5B), but I still halved convoy pay
  (K .05/.055/.06, property share of trade value .25 -> .15): 6 convoys now ~30-40% of law+property income.
- NEW (18:49) RENT + CAPITAL TIERS:
  * Players pay a % RENT on their property income to the alliance that owns the capital they live in (their home).
    The owning alliance sets the rate. New players never pay for their first 48 hours. After that rent is also
    taken from offline earnings. Completely SILENT: no notification, not in the offline summary.
  * Capitals need different perks AND tiers (strong vs weak), by real-world importance: New York, Los Angeles,
    London, Tokyo are top tier and worth fighting over.
- NEW (18:51) RAID NOTICE + SPYING:
  * The "you were raided" popup has two buttons: ATTACK (opens Raids and attacks them back normally) and REVENGE
    (the Robux Revenge Strike).
  * Players can NEVER see another player's stats (attack, defense, cash) unless they SPY on them. Spying reveals
    cash on hand, stats, etc. The spied player is NOTIFIED that someone spied on them.
- NEW (19:19) PLAYTEST ROUND:
  * Fight: each weapon has its own SOUND and ANIMATION: guns aim at the enemy and fire, melee weapons swing.
  * The VICTORY text overlaps the reward pills/buttons on the fight screen. Fix.
  * Limited bundles last only SEVEN DAYS.
  * Sound when a Robux purchase prompt opens, and a special sound when a purchase completes.
  * The WEEKLY TAKEDOWN belongs INSIDE the Alliance tab (everyone in the alliance takes part), not its own nav tab.
  * BUG: after clearing a takedown stage, it rolled back to an older stage. Investigate.
  * Not enough Influence for a law -> a REFILL popup. The FIRST refill purchase is cheap (~9 Robux).
  * Military units and properties are listed in order of how strong / how much money they make.
  * "LOCKED" text on ALL locked property tiles.
  * Properties: an income bar under each tile, all filling IN SYNC (~7 s); when full, each tile pops "+$X" (its income
    for those 7 s) with a little animation (like the reference).
  * OFFICERS go inside the MILITARY tab: the "MILITARY" title becomes a button with an "OFFICERS" button next to it
    (switch between ARMY and OFFICERS). No separate Officers tab.
  * Don't call the task currency "Seals": rename it.
  * Every property should have its OWN unique image (all 144), flawless.
- NEW (19:24) TOP BAR + MISC:
  * Description: simpler, with a short emoji bullet list rundown, and mention PREMIUM benefits (Roblox recommends it).
  * Top bar: label the bars "INFLUENCE" and "SUPPLY"; the gold icon must look like real GOLD BARS and be bigger;
    use the empty space; show the task currency (ex-Seals) up there too.
  * NEW PASS (99 Robux), in the Country tab: CUSTOM FLAG: many more flag options, or import your own flag image.
  * AI nations must NOT be labeled "AI" anywhere (they should look like any other nation).
- GROUP ID (20:35): 3735672 (wired into Config.Group: +10% cash, join popup).
- NEW (2 Oct 10:56) ART QUALITY PASS NEEDED (logged only; Studio closed, no big changes now):
  * People look inconsistent: enemy_general has no visible eyes; tiny people in country scenes (e.g. country_era1)
    have animal-like faces. REWORK enemy_general and country_era1, and audit every image for the same problems.
  * officer_founder and officer_megavip look good (keep that style as the reference for people).
  * country_era5 (industrial): the steam train looks like it is morphing into the building. Rework.
  ART AUDIT (2 Oct, my review of every character + scene image) — rework list for next session:
  * enemy_general: tiny/dark eyes, face reads off. REWORK.
  * enemy_guard, enemy_soldier: acceptable alone but faces don't match the officer style; redo all three enemies
    together so they share one face style (use officer_founder / officer_megavip as the face reference).
  * country_era1: crowd faces are blank/animal-like. Regenerate with NO close-up people (or tiny silhouettes only).
  * country_era2: tiny odd figures on the plaza; regenerate without people too (keep the composition).
  * country_era5: train melts into the factory and bridge. Regenerate: a clearly separate locomotive on the bridge.
  * shop_army: three identical-face soldiers + a real-world (French-like) flag. Redo with a fictional flag.
  * loading_bg: the cap badge looks like an eye; minor, redo the cap badge as a star if regenerating.
  * Fine as is: country_era3, 4, 6, 7, 8, takedown_bg, officer_founder, officer_megavip, all props/gear/icons.
  Rule for all future people art: no crowds, every face clearly drawn in the officer portrait style.
  DONE (2 Oct 16:15): reworked + live: enemy_guard/soldier/general, country_era1/2/5, shop_army. Still open: loading_bg cap badge (minor).
- NEW (2 Oct 16:26): rename the CAPITOL tab/map to WORLD everywhere. DONE.
- NEW (2 Oct 16:43) DECISIONS:
  * Raiding: players can attack ANYONE in ANY server (or offline). The RAIDS tab list stays "people in your server"
    (+ the 3 nations). The cross-server attack lives in RANKINGS (SPY + ATTACK on every player row). DONE: war cards
    (published every 2 min + on leave) and a hit queue applied by the defender's server (MessagingService, else on login).
  * Game description: APPROVED as written (the emoji list + Premium line).
  * "Merits" is the approved name for the task currency (ex-Seals).
  * Kash will make the game public himself later (do NOT switch the audience).
  * NEW TASK: a game ICON + THUMBNAILS for running ADS. Generate with ChatGPT/OpenAI. Research what works in Roblox ads
    first (competitors + our mechanics). Key lesson from his mural board: SHOW THE MAIN MECHANIC + an EMOTION
    (examples: Hole Fishing, Defend Your Treehouse wave 1 -> 15 -> 99 progression, Lift a Cube struggling with a
    huge number, Car Duels PvP, building with a big number). Use big readable numbers and progression shots.
- NEW (2 Oct 17:10-17:18) AD ART DIRECTION:
  * The ChatGPT (gpt-image-1) concepts looked AI-generated (yellow LEGO-like figures). Use GOOGLE FLOW (Nano Banana Pro)
    with REFERENCE IMAGES instead; stop using ChatGPT for this unless it clearly improves.
  * Avatars must look like real Roblox avatars, 1:1: BACON HAIR or classic NOOBS. Leader = bacon hair (Brown Charmer
    Hair 376548738, Blue and Black Motorcycle Shirt 144076358, Black Jeans 382537569, Golden Crown 1081300) with real
    face decals (Joyful Smile 209995366, Check It 7074786 smug, Frightful 7699193 scared). Rendered as R6 in Studio and
    used as Flow references (art/ads/refs). Match the art style of the competitor thumbnails (Build a Country, Steal An
    Egg, Sell Lemons, Run a Restaurant).
  DONE (2 Oct 17:35): 2 icons (16:9, design in centre square, + 512 crops) and 6 thumbnails with code-added numbers in
  art/ads/final and IdleCountryArt/ads on Kash's PC. Flow project "Oct 02 - 17:20" holds every generation.
- NEW (2 Oct 21:15) FEEDBACK (with screenshots):
  * RAIDED popup ("YOU HELD OFF X" / "X RAIDED YOU") is too big: make it a SMALL notice that does not take over the
    screen, players will be attacked often. (Kash: note for a future change.) Also "1 soldiers lost" grammar.
  * Every RNG box (Founder's Crate, Supply Crate, hires, any crate/box opening) must show its DROPS and their % RATES
    in its info popup.
  * NO officer BENCH. Officers can only be obtained when there is an OPEN SLOT (block hires/crate officer drops when
    full). LIMITED gamepass officers (VIP/Mega VIP/bundle) get their OWN EXCLUSIVE slot (extra, not using normal slots).
  * FOUNDER'S CRATE must never give officers; it can give SPECIAL TROOPS instead (plus gear).
  * STARTER PACK for new players: a decent property + decent troops.
  * BUG: the red RAID button shows a cooldown for some targets but not others even after Kash raided them (the
    per-attacker cooldown is not shown on the button; only the target's "just raided" cooldown is).
  * Passes with several unlocks (MEGA VIP etc.): the card image should ROTATE between images of each thing unlocked;
    the aura/rays must sit BEHIND the image.
  * Generated thumbnails need MORE DETAIL in the background.
  * Does NOT like the Takedown concept or its tickets: remove Takedown + tickets (and the ticket items in the Merits shop).
  * Disable SHIFT LOCK.
  * ALLIANCE tab needs more: a tab showing the cities the alliance holds; OVERVIEW shows members, contribution and
    perks; alliances have LEVELS and earn rewards for completing levels; add a WAR tab marked COMING SOON.
  * Asked: what other concepts would make the game really cool? (answered in chat)
- NEW (2 Oct 21:16) Kash LOVES the Idle Mafia style ad thumbnails (BUILD YOUR NATION, title card): keep making those.
  The full title is "IDLE COUNTRY GAME" (not "IDLE COUNTRY") everywhere (titles, title cards, logo).
- NEW (2 Oct 21:24):
  * ERAS: players advance to the next era by PAYING MONEY (not just reaching a level). The price should be about what
    reaching that era's level costs (roughly equivalent).
  * FOUNDER'S CRATE price -> 49 Robux each (update the packs to match, charm pricing, bulk cheaper per unit).
  * PLAYER PROFILES like the competitor's (screenshot shown earlier): another way for players to feel progress.
  * ALLIANCES need more progression feel: alliance tasks/quests (clan quests), levels, rewards.
  * Asked: what can players DO while waiting for property income and Influence to refill? (answered in chat)
- NEW (2 Oct 21:39) DECISIONS on new concepts:
  * GOVERNMENT TYPE: likes it (random, rerollable like races in other games) but ON HOLD for now.
  * WONDERS: yes. A Wonder is added to PROPERTIES, unlocked after the player's FIRST ERA UPGRADE. Needs an EPIC visual.
  * WORLD EVENTS on the WORLD MAP: yes. Every 30-60 min an event appears; players send a CONVOY to it for a big payout.
  * Approved (keep small for now): quick choice events, expeditions, research, property boosts, achievements + titles,
    player profile, alliance XP/levels/quests/tabs (War = coming soon), season pass idea.
  * PRIORITY: alliances and the main game must be fine-tuned: NO exploits, NO bugs. Research the bugs games like this
    usually have (Kash's notes on his PC from his other games + online) and audit everything.
- NEW (2 Oct 21:58): TESTER PANEL for Kash: a nice admin panel with lots of test options, plus a command box
  (e.g. /reset fully resets his progress as a brand new player). Owner-only (his UserId), never for other players.

## 2 Oct 22:30 (Kash)
- Onboarding: players choose their government (democracy, monarchy, etc.) with specific bonuses (property income, less energy, stronger troops...). A developer product lets them change it later.
  - Done: 6 governments (Democracy +10% property income, Monarchy +10% law cash, Federation +10% convoy pay, Military Junta +10% ATK/DEF, Theocracy Influence and Supply refill 10% faster, Technocracy +10% XP). Change Government product (R$ 99, needs creating in Creator Hub; id 0 until then) from the Country screen.

## 2 Oct 22:32 (Kash)
- Rules Kash gives (like "Founder's Crate never gives officers") are design notes for the code, NOT text for players. Never copy them into descriptions. Fixed the crate/shop texts.
- Visible pity system for crates. Done: meter fills with every crate that is not Legendary+; full meter = guaranteed Legendary+ (Founder 30, Supply 50). Shown on crate cards, shop and the drop rates popup.

## 2 Oct 22:39 (Kash)
- Onboarding capital step: recommend the 6 capitals where most players live at the top, so new players get busier trade. Done: live counts per home capital (OrderedDataStore IC_HomePop, refreshed every 10 min), starting list New York, London, Sao Paulo, Los Angeles, Mexico City, Jakarta until 30+ players have picked. Default pick is the top one.

## 2 Oct 22:41 (Kash)
- Onboarding asks if the player wants a tutorial. Done: after FOUND MY COUNTRY a WELCOME popup (YES, SHOW ME / NO THANKS). The tutorial is a small guide card with a pulsing frame on the tab to open: open Laws, pass a law, reach level 2, open Properties, build, open World, send a convoy. Skippable, resumes after rejoin. Tester: /tutorial restarts it.
- Tabs unlock by level so players are not overwhelmed; at first only LAWS and WORLD. Done (Config.NavUnlock): Properties 2, Shop 3, Country 4, Orders 5, Military 6, Inventory 7, Bank 8, Raids 10, Bosses 12, Rankings 12, Alliance 15. A dim "LV x" row teases the next tab; unlocking shows a toast and a badge.
- Also fixed: brand new players never ran the screen inits until they rejoined.

## 2 Oct 22:43 (Kash)
- Like the game / join the group popup, disguised as a FREE GIFT button in a tab players visit a lot; stays until they join. Done: pulsing gold FREE GIFT button on the LAWS screen; popup with LIKE THE GAME, JOIN GROUP, CLAIM GIFT (100 gold, 1 Founder's Crate, +10% cash). The server checks the group fresh; the button disappears once claimed.
- Robux purchases show in chat with stars and what was bought for how much. Done: products and passes, server-wide, e.g. "⭐ Testland bought 10 Founder's Crates for R$399! ⭐". Ad rewards are not announced.
- Watch an ad to refill Influence. Done: WATCH AD · FREE on the out-of-Influence popup (only when Roblox has an ad for the player), 5 min cooldown. Uses the 9 R$ refill product as the reward (Roblox rule: 3-10 R$ value). Needs the game public with rewarded ads enabled (2,000+ monthly visitors, verified ID).

## 2 Oct 22:53 (Kash)
- Game copied into a new experience owned by Kash's personal account (universe 10769117926, place 104255655483582) so his personal ad credit can be used; ownership transfers to Tabby Studios later. All 9 passes and 22 products recreated there with the same names, prices and pass art; Config ids switched to the new ones. Studio work now happens in the new place.

## 2 Oct 23:03 (Kash) PUBLIC LAUNCH SETUP
- Badges: one easy, the rest very hard; art made (Flow, game icon style; OpenAI credits ran out). Free quota is 5 a day: created Founding Father, Wonder of the World, To the Stars, Warlord, Trade Empire; the other 5 (Richest Nation on Earth, Supreme Lawgiver, Tyrant Slayer, Legendary Alliance, Forbidden Power) get created when the quota resets (scheduled).
- Analytics: onboarding funnel (14 steps), level/era progression, gold + Merits economy, per-item shop funnels, custom events.
- Description, name, 30 players per server, devices Computer/Phone/Tablet, 6 new thumbnails.

## 2 Oct 23:23 (Kash)
- Music and SFX did not play during onboarding: fixed (sound starts before onboarding).
- Onboarding flag step offers the Custom Flag pass with its extra layouts, colours and emblems shown locked until bought.
- Tutorial: darken everything except what to press, with a snug rounded gold frame (the old outline sat badly on the tab). Done with a spotlight that also points at the PASS button and an empty lot.

## 2 Oct 23:26 (Kash)
- Normal players must never see or use TEST: it only shows for the owner account (or anyone in Studio); every command is checked on the server.
- SHOP gets a GEAR SHOP tab: restocks every 5 minutes, 3 random items of every rarity, 1 of each per player per restock, rarer gear needs high levels (Common 1, Uncommon 10, Rare 25, Epic 50, Legendary 80, Mythic 110, Secret 140, Forbidden 170). Cash prices scale with level.

## 2 Oct 23:29-23:35 (Kash)
- Property income bar redesigned (fixed pill + separate bar), UPGRADES button in the top bar opens the skill upgrades popup from any tab (level 4+), music and SFX volume sliders.
- Global chat: "/g message" (or /global) shows in every server's chat as "[GLOBAL] Name: message" (filtered, 1 per 4 s).
- Convoys must be BOUGHT: the first is free; each extra convoy is bought with cash (about an hour of law income) once its level (5, 12, 20, 30, 45) is reached. Existing saves keep the convoys they already had.
- World events were already game wide (same clock in every server). City WANTS are now game wide too (shared MemoryStore + cross-server messages).
- Overlaps and off-style buttons/pills/panels (e.g. ARMY/OFFICERS sub tabs over the subtitle, the LIMITED "always active" pill) must be fixed across the whole game.

## 2 Oct 23:38 (Kash)
- Bots (and players) can't raid a country until it has the RAIDS tab (level 6).
- Tabs unlocked too late: lowered so everything is open by level 9 (Properties 2, Shop 3, Country 3, Orders 4, Military 4, Inventory 5, Bank 5, Raids 6, Bosses 7, Rankings 8, Alliance 9).
- Off-style pills/progress bars/buttons and overlaps: whole-client pass onto the UI kit (chips, tags, bars, info buttons), composite sub tabs fixed, LIMITED plate, crate card layout, pity bars.

## 2 Oct 23:43 - 3 Oct 00:11 (Kash)
- Owned one-time passes/products in the shop get a grey kit cover: OWNED + THANK YOU FOR YOUR SUPPORT!
- Code-drawn outlines never lined up with the art (corners): every highlight on a kit plate now uses UI.outline (matched to the plate border), many removed. No colored accent stripes on cards/toasts.
- Defeat gets a new sound; Mythic/Secret/Forbidden reveals get their own stings. SOUND BOARD in the tester panel to preview every sound and candidate picks (tell Claude the letter).
- Never tell players internal rules ("your sheet pauses, it never resets"). All player text rewritten short and motivating ("Come back every day for a reward.").
- Progress too fast: levels need about twice the XP (XpFirst 1.0, XpBase 2.5, XpStep 0.4, XpCap 10).
- Laws: every era tab is shown; eras you don't have show only a lock and the level (no name).
- AFK CHAMBER: idle 15 min -> full-screen chamber with the world map, income, earnings while away, time away, and finds; every 60 s an 8% chance to find gear (rare+ lottery-low); RETURN goes back; prevents the 20 min idle kick.

## 3 Oct 00:16 (Kash)
- Gold is 1:1 with Robux: gold packs give 49/199/699 gold for R$49/199/699; Founder's Crate 49 gold; Influence and Supply refills 19 gold (same as Robux); finishing a convoy 9/19/29/49 gold by time left (same tiers as Robux); boss skip 9 gold. All gold prices live in Config.GoldPrices / Config.FinishGold.
- New icon: Kash's no-text Flow image (crowned bacon hair), uploaded.
- Wants a list of every gold source to decide how strong the currency is (sent in chat).

## 3 Oct 00:23 (Kash)
- Bulk bonus approved: R$49 = 49 gold, R$199 = 210 gold, R$699 = 775 gold.
- Fine that a casual player can afford a Founder's Crate with gold; it is a launch-only crate.
- Launch timers reset to 7 days from now: Founder's Crate and Limited Bundle end 10 Oct 2026 10:23 UTC (Config.Limited.ends = 1791627808).

## 3 Oct 00:30 (Kash)
- Tutorial pointed one row too high (LAWS instead of PROPERTIES, MASTERY instead of PASS): the spotlight used raw screen positions while the HUD ignores the top bar inset. Now measured from the HUD root. Dim made stronger, strips snapped to whole pixels (no seams), BUILD step points at the cheapest BUILD button on the building list and says how much cash is missing when the player cannot afford it yet.
- Wants a desktop + mobile test of onboarding and overlaps across the game. Added Studio-only test hooks: IC_Cmd "vp:WxH" (emulate a screen size) and "audit" (lists text that overflows, goes off screen or overlaps other text).

## 3 Oct 00:36 (Kash)
- 2x convoy speed pass at R$499, shown where the convoys are (like Auto Dispatch). Reused the existing 2x pass (id 2005160720), renamed "2x Convoy Speed", R$499. Convoy dock now shows a 2X CONVOY SPEED buy button (or 2X SPEED ACTIVE when owned) and an AUTO DISPATCH buy button when not owned.

## 3 Oct 00:37 (Kash)
- Level 3 was too hard to reach: first levels are gentler (level 2 needs 1.4 Influence bars of XP, level 3 needs 2.2, normal climb from level 4).
- Army training (MILITARY) and attacking other players (RAIDS) now unlock at level 3, together with the shop. AI nations still leave players alone until level 5.

## 3 Oct 00:38 (Kash)
- Level progression better but still a bit too hard (tested with VIP and Mega VIP): eased the whole curve to about 1.45x the original (was 2x). XpBase 1.9, XpStep 0.3, cap 7.5; level 2 = 1.2 bars, level 3 = 1.7 bars.

## 3 Oct 00:39 (Kash)
- New passes: 2x Influence Regen R$499 (id 2005478758, the big one) and 2x Supply Regen R$199 (id 2006054752). Influence pass doubles the whole regen rate (stacks with VIP, officers, government); Supply pass doubles Supply regen. Theocracy's +10% now also applies to Supply as its card says. Both are first/third in the GAME PASSES list.
- Mobile test: nav now starts below the Roblox menu buttons on phones; tutorial card scales with the HUD.

## 3 Oct 00:43 (Kash, iPhone 16 Pro emulator)
- Right side was cut off, Studio background showing left/right/bottom, top bar crowded. Fixes: a full-screen backdrop behind the safe-area HUD (no more 3D world around the edges); on phones the flag/name/level block moves to the top of the nav column so the top bar only holds money, energy, upgrades and settings at a readable size; law era tabs rebuild on resize so they never run under FREE GIFT. Smaller phone model next, after this push.

## 3 Oct 00:47 (Kash, smaller phone 666x374)
- Ran the overlap audit on every tab and screenshots of Country, Raids, Inventory, Alliance. Fixed: UPGRADES label wrapping to "UPGRADE S", nation names in the nav and the Raids list now shrink to fit instead of cutting to "Empire of...".

## 3 Oct 00:52 (Kash, iPhone 7 emulator)
- Fix all the small things too, and the phone top bar (bars not aligned, buttons not using the space, gold/merit icons outside their chips). Desktop must not change.
- Phone-only top bar: Influence and Supply stacked as two equal, aligned bars with their icon on the left and the timer inside the bar; cash and income on the left with the gold and merit chips stacked beside them, icons fully inside the chips; bigger + button. Desktop geometry and text sizes are restored exactly when not on a phone.
- Officer cards show one bonus per line (second bonus no longer cut). Raid names keep a gap before DEFENSE. Alliance tab opens at level 8 (same level founding one needs). Phone tutorial card is smaller and the final "You are ready" card closes itself after 8 seconds on phones.

## 3 Oct 00:57 (Kash)
- Asked me to change the 2x Convoy Speed price myself: Roblox price is now R$499 (confirmed on the API), matches the game. Kash publishing.

## 3 Oct 01:01 (Kash)
- Didn't know how to get gold bars; Game Guide was missing info. Added guide sections: GOLD BARS (every free source with amounts, what to spend it on), LEVELS & ERAS (when tabs open, era advance), GOVERNMENT, BOSSES, ALLIANCES, AFK CHAMBER; plus Wonder (Properties), pity and Gear Shop (Crates), world events and convoy passes (Convoys). Values read from Config so they stay correct.
- Update the in-game changelog: added Alpha 0.4 (3 Oct) with everything since Alpha 0.3; version shown is now Alpha 0.4.

## 3 Oct 08:14 (Kash)
- Rankings show players, not countries: Roblox avatar headshot + display name and @username (fetched in one batch on the server, cached). Country, flag and the rest stay on the profile, which now also shows the @username.

## 3 Oct 08:17 (Kash)
- His own profile must not appear on the leaderboards: Config.HiddenFromRankings (his user id) is filtered out of the Level and Wealth boards.

## 3 Oct 08:42 (Kash)
- 12 people in his server but nobody raidable: other players were protected until level 5 (the AI rule). Players can now raid each other from level 3 (when RAIDS opens); AI nations still wait until level 5. The Raids list says how many players in the server are still too low to raid.
- Show the owner of each country in Raids: Roblox avatar + @username under the country name.
- Heard Roblox footsteps: nobody can move or jump anymore (walk speed 0, jump 0, character anchored, keyboard and touch movement off).

## 3 Oct 08:43 (Kash)
- Raid history: every raid you made and every raid on you (last 40, saved). RAIDS tab > HISTORY chip opens it: who, VICTORY/DEFEAT or DEFENDED/RAIDED, cash won/lost, soldiers lost, how long ago; tap a player row for their profile.

## 3 Oct 08:45 (Kash)
- SHOP moved up the nav (right after PROPERTIES). Every GEAR SHOP restock (5 min) puts a red ! on SHOP and on the GEAR SHOP tab until the player opens the Gear Shop.

## 3 Oct 08:49 (Kash)
- Could spam beat the Bandit King and skip the wait: skip is now 3 times a day max, and a boss you skipped to pays no gold (still cash and XP). Skip button showed "3 GOLD" but charged 9: label now reads the real price.
- Wants occasional chat tips (every 5 to 10 min) that sound typed by him. Draft list sent for approval before building.

## 3 Oct 08:56 (Kash)
- Chat tips: his own 5 lines, word for word, shown as [Kash] in chat every 5 to 10 minutes, shuffled; the group tip stops after the FREE GIFT is claimed.
- Asked for a detailed throne room image with his avatar sitting in a thinker pose (to see what it looks like).

## 3 Oct 08:57 (Kash)
- PASS LAWS thumbnail has very high CTR: make more in that style, plus a better convoy thumbnail with a map, in Google Flow.

## 3 Oct 09:00 (Kash)
- Alliance leaders need a MANAGE tab with lots of settings; perks need their own tab, and members and leaders see different things.
  - New tabs: OVERVIEW · PERKS · CITIES · QUESTS · WAR · MANAGE (MANAGE only for leader and officers).
  - PERKS: treasury, alliance level bonus, city perks, upgrades. Leaders/officers get UPGRADE buttons; members see what the next level gives and how close the treasury is. Overview keeps a one-line perks summary with VIEW PERKS.
  - MANAGE (leader): announcement (filtered, shown at the top of OVERVIEW), open / invite only, minimum level to join (enforced on join), join fee and dues with style (once a day, the server rule already existed but had no buttons), alliance colour, officer permissions (buy upgrades, remove members, enforced on the server), member management (promote, demote, remove, make leader, moved out of OVERVIEW). Officers get the announcement and can remove members if allowed.
- Thumbnails are for the game, not with his avatar; competitor style. Never use his Roblox avatar.

## 3 Oct 09:03 (Kash)
- Asked whether the group reward still works if the game isn't owned by the group: yes, it checks membership of the configured group, ownership doesn't matter.
- Nano Banana Pro hit its usage limit: switched Flow to Nano Banana 2.

## 3 Oct 09:07 (Kash)
- Purchase shout-out showed the country name: now the Roblox name (Display (@user)). Purchases now rain confetti: a full burst for the buyer, a small one for everyone else in the server.

## 3 Oct 09:17 (Kash)
- More thumbnail concepts with the title overlaid on the art (no split background), many variations, showing game mechanics. Made 14 concepts x2 (art/ads/v4): pass laws, get rich, trade the world, world event x2.5, raid players, spy first, legendary drop, hire officers, defeat bosses, hut to empire, capture cities, earn while AFK, build wonders, bank your cash.

## 3 Oct 09:41 (Kash)
- v3/v4 art style drifted away from what he wants (too grungy/painted). Keep the layouts and concepts, but match the 2 Oct thumbnails (N04 Steal Their Cash, the Idle Country icon): those used real references. Variants can be better too. Plan in art/ads/v5/PROMPTS.md. Blocked: Flow usage limit on both Nano Banana Pro and Nano Banana 2.

## 3 Oct 09:53 (Kash)
- Nano Banana 2 has no limit (Pro was the limited one). Use the references from yesterday / the live thumbnails, not the image I used last (he dislikes its style). Uploaded the live thumbnails (art/ads/v2 N04-N10) to Flow as thumbref_* and made 16 concepts x2 in that style (art/ads/v5). trade_world_a has a typo ("VORLD"): do not use.

## 3 Oct 10:20 (Kash)
- Alliance target capital: leader/officers tap SET AS ALLIANCE TARGET on a city's map panel; every member sees a red banner on OVERVIEW (ATTACK IT jumps to the city) and a pulsing red ring on the map. Clears itself when the alliance captures it.
- New MEMBERS tab (everyone): strongest member card, sort by strength / XP this week / all time / last active, avatar, online dot, level, power (attack + defense), contribution, donations. Leader promotes, demotes, removes, hands over leadership; officers remove members if allowed. Moved out of OVERVIEW and MANAGE.
- Favorite popup: only shows if the game isn't already favorited (GetFavoriteAsync), and at most once per player.
- Boss images for all 8 bosses: made in Nano Banana 2 (square, live thumbnails as style refs, art/bosses), uploaded as boss_1..8 and shown as a big portrait on the BOSSES screen plus small ones in the boss list.

## 3 Oct 10:21 (Kash)
- Chat tips label "[Tip]" instead of "[Kash]".

## 3 Oct 10:25 (Kash)
- Tapping your flag at the top left opens your profile.

## 3 Oct 10:28 (Kash)
- New alliance perk HEADQUARTERS: +6 member slots per level, 10 levels, so up to 100 members (level 10 alliance + HQ 10). Cost 4M, x2.6 a level (about 35B for all 10). Asked for more perk ideas: suggested in chat.

## 3 Oct 10:31 (Kash)
- Territories now cover 100% of the land and follow real country borders (Natural Earth 1:50m). A country with several cities is split between them (nearest city); a country with no city joins the city nearest its centre as a whole (north Canada -> Toronto, most of Africa -> Lagos / Cairo / Nairobi / Johannesburg, Siberia -> Moscow). New map image draws country borders lightly and territory borders darker. Alliance-held territory is tinted in the alliance colour (terrain still visible) with a solid border in that colour. Generator: game/assets/mkmap2.py + countries_raster.py.

## 3 Oct 10:33 (Kash)
- Convoy RECALL: a travelling convoy can be turned around for free. The way back takes half the time it already travelled, cargo cost is refunded, one recall per trip. RECALL HOME for parked convoys is now free too.

## 3 Oct 10:41 (Kash)
- Roblox moderated IC_boss_rogue_general (103274986913008) as "Illegal and Regulated Content" (the cigar = tobacco) and the account is temporarily moderated. Removed boss_5 (Robber Baron, also had a cigar) and boss_6 from the game; those bosses show the skull icon until clean versions exist. RULE for all future art: no tobacco/cigars, alcohol, drugs, weapons-making, or real-world extremist symbols/armbands in anything uploaded to Roblox. Asked Kash to delete/archive 117230554201741 (Robber Baron) before it gets reviewed.

## 3 Oct 10:50 (Kash)
- Map didn't load: the new map upload (131032198234520) never loaded in Studio. Uploaded a 2x version (1536x584, 114973255343938) that loads; map_world points at it.
- Remade Robber Baron (money sack + cane) and Rogue General (binoculars, gold star cap, no armband) with no cigars or insignia; uploaded as boss_5/boss_6. Cigar versions deleted from the repo.

## 3 Oct 10:53 (Kash)
- Boss takes-damage animation: each hit shows slash marks (1/2/3 for x1/x5/ALL), a red flash, a squash punch, a shake and a big damage number on the portrait, with a blade or crit sound. A killing blow shakes harder and greys the portrait out.

## 3 Oct 11:02 (Kash)
- Boss slash effect looked cheap and sat left of centre (bug: slash k was offset by (k-2)*16%). Replaced with a glowing sword-slash sprite (fx_slash, transparent PNG drawn in code, game/assets/fx) that pops in centred on the portrait: x1 one cut, x5 an X, ALL three fanned cuts.

## 3 Oct 11:09 (Kash)
- Recall can be cancelled: CANCEL RECALL · CONTINUE TO <city> turns the convoy around again with its original cargo at normal speed. The cargo refund now happens when a recalled convoy actually gets home, so cancelling never charges again.

## 3 Oct 11:11-11:12 (Kash)
- TREASURY tab for elders and up: balance, 7-day income / spending / net, breakdown by source (dues, city tax, city rent, donations, join fees, perk upgrades) with bars, a by-day table and the last 30 donations / join fees / upgrades. New ELDER rank between member and officer (leader promotes member -> elder -> officer and demotes back; officers can remove members and elders; leadership passes officer -> elder -> member). Members below elder don't receive the ledger at all (PS.AllyView).

## 3 Oct 11:13 (Kash)
- Asked whether raids should go global instead of server only: answered in chat (not changed).

## 3 Oct 11:14 (Kash)
- Auto Dispatch always takes the best net pay per second of travel: every load on every route (not just each route's top load), world events included for live sends (locks the event bonus like a manual send), no more fleet spreading penalty.

## 3 Oct 11:16 (Kash)
- The "[Kash] if youre stuck on cash..." chat line is his own tip #2; the live game still shows [Kash] because the [Tip] change isn't published yet.
- Players in an alliance can browse other alliances: new BROWSE tab (rank, badge, level, leader, cities, members/cap, invite only / min level). Also fixed the join list showing 30 as the cap instead of each alliance's real cap.

## 3 Oct 11:21 (Kash)
- Alliance emblems: 46 icons to pick from in MANAGE (leader), drawn on the alliance colour as a badge everywhere (overview, join list, browse, rankings). With the Custom Flag pass the leader can use their own image instead.
- Asked what Revenge Strike does and noted confetti on someone else's purchase: answered in chat.

## 3 Oct 11:24 (Kash)
- "They were just raided" blocked everyone once anyone raided a nation. Removed the shared cooldown: the whole lobby can raid the same nation, each attacker only has their own cooldown on it. (AI rivals still can't pile onto one player.)

## 3 Oct 11:58 (Kash)
- Likes the art style of the current set (v5 + live thumbnails); wants better concepts, layouts and variations. Made 16 new concepts x2 in art/ads/v6 (Nano Banana 2, refs: Rule the World, Steal Their Cash, Raise Your Army, Raid VS): plan your attack, biggest empire, capture capitals, defeat the boss, earn while AFK, evolve your nation, pass laws get rich, hut to empire, legendary officers, choose your government, protect your cash, send convoys, spy on rivals, be number 1, win the war, world events. Don't use: top_the_leaderboard_a (typo NUMRER), monarchy_democracy_a (seal on the podium looks like a real one), get_rich_laws_a ("ROBUX" printed on the cash).

## 3 Oct 14:09 (Kash)
- INVITE A FRIEND quest on top of ORDERS for every player: INVITE FRIENDS opens the Roblox invite prompt with launch data { ref = inviter }. A brand new player who joins through it and reaches level 3 counts as a referral (queued in DataStore IC_Referrals, pulled by the inviter on join and every 2 min). Tiers, each claimed once: 1 friend 50 gold, 3 friends 100 gold, 5 friends 150 gold (Config.Invite). Level 3 requirement stops alts that never play.

## 3 Oct 15:52 (Kash)
- Alliance tabs ran off the screen (9 tabs at a fixed width, measured before UI scale). Tabs now share the row width evenly (UI.tabs fill, max 160 px each), so any number fits on desktop and phones.

## 3 Oct 16:45 (Kash)
- Thumbnails like competitor Fleet Empire: real in-game screenshots with a big title on top. Made 6 in art/ads/v7 (generator make.py, Anton font): build your empire (properties), send trade convoys worldwide (map), defeat bosses for gold, hire legendary officers, join an alliance & conquer (alliance target), raise your army.

## 3 Oct 20:25 (Kash)
- Concepts like Idle Mafia's territory thumbnail (their FIGHT FOR TERRITORY map: raised faction-coloured districts, flags, clashing arrows, gold burst). Pulled their live thumbnails (art/ads/v8/idlemafia) and made 6 concepts x2 on our world map in art/ads/v8: expand your territory, capture capitals, fight for territory, conquer the world, join an alliance, tax the cities. Skip join_an_alliance_a (copies their city map, eagle flag) and fight_for_territory_b (USA shape garbled).

## 3 Oct 20:34 (Kash)
- Liked fight_for_territory_b; wants it in our thumbnail style, looking like our in-game map, with an accurate North America. Remade with refs: that thumbnail (layout), a crop of our pixel world map (coastline + map look) and our current thumbnail style. 3 layouts x2 in art/ads/v9: title left, title top on a war table, title left with the bacon hair pointing at the clash.

## 3 Oct 20:41 (Kash)
- More thumbnails like PASS LAWS (moody desk still life, only a suited hand, no Roblox avatar, big white title on black on the left). 12 concepts x2 in art/ads/v10: bank your cash, send convoys, hire officers, raise your army, capture capitals, open crates, build wonders, defeat bosses, collect taxes, spy on rivals, join an alliance, earn while AFK. Skip collect_taxes_b (lorem ipsum text under the title) and hire_officers_a (realistic faces on cards).

## 4 Oct (scheduled follow-up)
- Free badge quota reset: created the last 5 badges (Richest Nation on Earth, Supreme Lawgiver, Tyrant Slayer, Legendary Alliance, Forbidden Power) for free; all 10 badges now have ids in Config.Badges.

## 4 Oct 07:41 (Kash)
- ~10 variants like Idle Mafia's BUILD YOUR EMPIRE ad (title across the top with the centrepiece poking through EMPIRE, two suited hands placing a gold building on a miniature board). Made 10 x2 in art/ads/v11 for a country: capital palace, world globe, country map, era tower, properties grid, fortress city, trade port, wonder, blueprint, night capital. Skip night_capital_b (a third arm appears) and wonder_a (modern yacht).

## 4 Oct 08:46 (Kash)
- v11 and earlier copied Idle Mafia's art style 1:1. Wants their concepts, not their style. Collect countless concepts from many Roblox simulator, strategy, history and country games (their game thumbnails and the ads they run on the homepage) into a reference chart document for making our ads and thumbnails. Art style comes from his desktop thumbnails (copied to art/ads/style_refs); those don't sell the game well enough, so analyse the audience through Idle Mafia and country games and think as that player: "control my country, take over land and rule the world with the army". Feed refs to Google Flow with very specific prompts.
