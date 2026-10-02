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
