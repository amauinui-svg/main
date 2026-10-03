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
