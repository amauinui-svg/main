# Idle Country: sound list

Every sound used by `client/Sound.lua`. Each id was checked in Studio on 1 Oct 2026: it loads in this place, and the length and uploader were read from the asset.
**Nobody has listened to these yet** (Claude can't play audio), so they were picked on uploader, library, name and length. Please listen in Studio and mark any you want swapped. Every event also has a backup id (`alt`) that the code switches to automatically if the main id fails to load.

Where the sounds come from:
- **Roblox**: Roblox's own UI sound pack, plus the classic Roblox sword sounds that have been in Roblox since 2008. Free to use anywhere.
- **ProSoundEffects (PSE)** and **APMOfficial (APM)**: the professional libraries that Roblox licensed for every creator to use for free. No copyright risk.
- **BIG Games** (the Pet Simulator 99 studio): their own public upload.
- **Community**: ordinary player uploads. These can be taken down at any time, so the backup id is there for that case.

## Sound effects

| Event | Primary id | Name / uploader | Length | Why | Backup |
|---|---|---|---|---|---|
| ui_click | 15675032796 | Roblox_UI_Small_Click / Roblox | 0.13s | Short, crisp, official Roblox UI click | 15675059323 Roblox_UI_Bright_Click |
| ui_hover | 15675032796 | Same click, pitched up 35% at 12% volume | 0.13s | A barely-there tick, plays only for mouse users on "Button"/"Tab*" | 15675081158 Roblox_UI_Cute_Goodbye |
| tab_open | 15675037413 | Roblox_UI_Paper_Swipe / Roblox | 0.62s | Paper swipe fits the manila-folder/document look | 15675012262 Roblox_UI_Whoosh_04 |
| notify | 15675085146 | Roblox_UI_Indicator / Roblox | 3.4s (cut at 1.6s) | Official notification ping | 15675059323 Bright_Click |
| error | 15675075163 | Roblox_UI_Delete / Roblox | 0.61s | Soft "denied" sound, not harsh | 15675062723 Roblox_UI_Whistle_Low |
| purchase | 127645268874265 | CoinTransfer_01 / Roblox | 1.66s | Official coin-transfer sound for buying | 9113849651 Coin Throws 3 (PSE) |
| coin | 607665037 | coins_get / HeyOverHere (community, 2016) | 0.52s | Short coin pickup, old and widely used | 9121189379 BagOfCoins / DataSigh |
| cash_big | 9113849583 | Coin Throws 2 / PSE (+ plays `purchase`) | 2.2s | A real pile of coins landing, layered with the coin transfer | 9119218944 Slot Machine 2 payout (PSE) |
| claim | 1839997938 | Correct Answer 3 / APM (Game Show Toolkit) | 5s (cut at 2.6s) | "Correct buzzer with rising, sparkling synths": a reward chime | 15675043410 Roblox_UI_Tonal_Stinger |
| level_up | 87681931953984 | Vast Horizon - Sting / APM | 5.4s | Short orchestral sting; music dips while it plays | 1841887348 Things Are Looking Up (sting) / APM |
| law_pass | 9125574158 | Gavel Hit Wood Mallet Single Impact / PSE | 0.71s | A real gavel strike: "law passed" | 9114559389 Gavel Hits Big Impacts Reverberant (PSE) |
| seal | 9125573398 | Gavel Hit Wood Mallet Light Impacts / PSE | 1.0s | Lighter wooden thump, like pressing a wax seal | 9114348725 Envelope Slam Down 14 (PSE) |
| build_start | 9125574353 | Gavel Hit Wood Mallet Triple Impact / PSE | 1.35s | Three mallet hits on wood sound like hammering | 9114755645 Hammering Light Birds 2 (PSE, 10s) |
| build_done | 15675043410 | Roblox_UI_Tonal_Stinger / Roblox | 1.47s | Short tonal success chime | 1839997938 Correct Answer 3 |
| hire | 15675028888 | Roblox_UI_Whoosh_02 / Roblox (+ plays `seal`) | 0.49s | A swoosh followed by a "signed" thump | 12222200 swoosh.wav (classic Roblox) |
| equip | 9116672675 | Metal Impact Dropping Clanky Piece 10 / PSE | 1.26s | Dull metal clank with no ring, like gear being strapped on | 9116542304 Metal Clanks 6 (PSE) |
| convoy_arrive | 134725934515507 | battle bell / CandiedTeas (community) | 5.2s (cut at 2.6s) | A bell announcing an arrival. No official bell was good enough | 107938430449015 Bell / misanthroqe (community) |
| stage_clear | 100735630401429 | Glorious Morning Link / APM | 12s | Big, bright orchestral link for a major achievement; music dips | 1844250707 New World Anthem Link 4 / APM |
| crate_shake | 1846435467 | Timpani Effect G / APM | 4.7s | Timpani roll: classic drum-roll suspense before a reveal | 9120891869 Wood Hits Wood 8 (PSE) |
| crate_open | 15675055424 | Roblox_UI_Cute_Pop / Roblox | 2.7s (cut at 1.2s) | Official pop/burst | 15675024286 Roblox_UI_Whoosh_01 |
| reveal_common | 3199238931 | Pick_up_gem / thienbao2109 (community, uploads mobile-game SFX) | 2.1s (cut at 1.2s) | Modest pickup chime | 15675043410 Tonal_Stinger |
| reveal_rare | 4612374495 | bling_diamond_pickup_3 / thienbao2109 (community) | 1.5s | Sparkly "bling" | 4612374393 bling_diamond_pickup_2 |
| reveal_epic | 1841209502 | Beautiful Shimmer / APM (KPM Sonic Logos) | 6s | Bigger atmospheric shimmer; music dips | 1846631123 Effect Cue 6 / APM |
| reveal_legendary | 134527763388412 | Audio_Unique_Pet_Hatch_End_1 / **BIG Games (Pet Simulator 99)** | 6s | The hatch-reveal sound from one of Roblox's biggest games | 9039690188 Brassy Fat Throb / APM (trailer brass swell) |
| raid_start | 1846284814 | Timpani Signal 1 / APM (+ plays `unsheath`) | 6.4s | War drums with a sword being drawn | 1835324771 Battleforce StingA / APM |
| (unsheath) | 12222225 | unsheath.wav / Roblox (classic sword) | 0.65s | The original Roblox sword-draw sound | none |
| hit_gun | 130729359112925 | Musket Single Shot Close / ruqyv (community) | 2.6s (cut at 1.4s) | A real musket shot fits the historical eras | 129944384098631 Musket Single Shot Distant |
| hit_blade | 12222216 | swordslash.wav / Roblox (classic sword) | 0.56s | The iconic Roblox sword slash | 109675024264804 sword_hit_sword (community) |
| hit_punch | 9113565515 | Boxing Hits 6 / PSE | 0.77s | Real glove-on-bag thud | 9113575293 Boxing Hits 3 (PSE) |
| crit | 9120730097 | Whoosh Impact 3 / PSE | 2.2s | "Thick swish, hard impact, reverberant": a heavy hit | 9114559389 Gavel Big Impacts Reverberant (PSE) |
| takedown_hit | 9120974378 | Wrestling Crowd 3 / PSE (+ plays `crit`) | 4.3s (cut at 2.5s) | A heavy hit plus a crowd surge | 9120975204 Wrestling Crowd 2 (PSE) |
| victory | 1835295052 | Forging The Army StingA / APM | 11s | Martial orchestral victory sting; music dips | 1835324771 Battleforce StingA |
| defeat | 115055593775910 | Downfall StingB / APM | 7s | Grim orchestral defeat sting | 125909120236588 Mounting Consequences StingA / APM |
| boss_defeat | 1835324771 | Battleforce StingA / APM (+ plays `takedown_hit`) | 11s | Bigger than a normal victory: sting, crowd and impact together | 119099828605032 Pride & Ambition StingB / APM |

## Music (shuffled, cross-faded, the same in every era, volume about 0.28 to 0.3)

| Track | Id | Uploader | Length | Notes |
|---|---|---|---|---|
| Royal Retreat | 9040686092 | APM (Bruton, *Regal Strings*) | 2:22 | "Grand and majestic string sections with a noble, royal essence… for history". This was the best match for the theme |
| Summer Dawn (Strings Mix) | 9042589035 | APM (Bruton, *Light Orchestral*) | 2:28 | Gentle strings that won't tire the ear in an idle game |
| Heroes Of Discovery | 1845379555 | APM | 2:05 | Adventurous orchestral |
| History In The Making A | 104175735498486 | APM | 2:46 | The title fits; needs a listen to confirm the mood |
| **Battle (optional)**: Imminent Closure (Underscore A) | 9046505640 | APM (*Heroes & Villains*) | 1:50, looped | Driving strings and brass, stripped-back underscore. `App.music("battle")` |
| Battle backup: Battle Divine Lite Perc | 9043173292 | APM | 1:55 | |

Other tracks checked and kept in reserve: Tales Of Fate C 1847574586, Get Back To The Land 1837401083 (orchestra and choir), Whatever It Takes 9043654041 (heroic, builds), Jubilee Warfare 1841821377, Checkmate 1837202533, Making History 9041814546.

## Swapping a sound
Change the `id` (or the `alt`) in the `SFX` / `MUSIC` table at the top of `client/Sound.lua`. Volume is 0 to 1. `jitter` is the random pitch spread. `stop` cuts a long file short. `duck` lowers the music while the sound plays.
