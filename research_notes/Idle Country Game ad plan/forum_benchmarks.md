# Roblox Ads: Forum-Reported Benchmarks and Community Playbooks (2024-2026)

Context on units used below: Ads Manager bills in **ad credits**. Forum posts in 2024-2025 consistently quote the 10-credit minimum as **2,850 R$** (285 R$ per credit) and one user compares it to "$28.50", i.e. 1 ad credit ~ $1 USD when bought with Robux at the DevEx-style rate. Roblox's own benchmarks are quoted in USD per play. Sources: [Using Ads Manager For The First Time, Jan 2025](https://devforum.roblox.com/t/using-ads-manager-for-the-first-time/3342871); [Ads Manager Updates, Aug 5 2025](https://devforum.roblox.com/t/ads-manager-updates-acquire-new-users-continuous-campaigns-and-more/3862159).

## 1. Reported CTR, CPC, CPM, cost-per-play (CPP) ranges, by genre/audience

### Takeaway
The only trustworthy numbers are Roblox's own published cost-per-play benchmarks (roughly $0.007-$0.019 per play depending on objective, late 2025) plus scattered dev reports of $0.01-$0.024 per play; Roblox optimizes toward CPP, so CTR/CPC/CPM are barely reported and no genre breakdown exists publicly. Costs have risen sharply since mid-2025 and the Jan 2026 migration to the new Ads Manager.

### Cited Findings
**Official Roblox benchmarks (CPP, USD)**
- Aug 5, 2025: Maximize Plays $0.008; Drive Retention $0.007; Reactivate Users $0.011. Also: 91% of ad spend already on new Ads Manager; 16:9 format drove an estimated +57% play-through rate; Sponsored Sort repositioning +13.4% "quality plays" — [Ads Manager Updates: Acquire New Users, Continuous Campaigns (Aug 2025)](https://devforum.roblox.com/t/ads-manager-updates-acquire-new-users-continuous-campaigns-and-more/3862159)
- Nov 11, 2025: Maximize Plays $0.0073; Drive Retention $0.0113; Reactivate Users $0.011; **Acquire New Users $0.0187**. Roblox: "you can still drive plays for under $0.01 for maximize plays" — [Ads Manager Updates: Home + Search Combined, New Benchmarks (Nov 2025)](https://devforum.roblox.com/t/ads-manager-updates-home-search-combined-new-benchmarks-and-sunsetting-the-classic-flow/4084863)
- Mar 31, 2025: Ads Manager optimizes toward lowest CPP (not CPM/CPC); 16:9 sponsored units gave "40% improvement in play through rate" — [Leveling Up Ads Manager (Mar 2025)](https://devforum.roblox.com/t/leveling-up-ads-manager-with-new-features/3587640)

**Developer-reported numbers**
- Jul 1, 2024 (Seal's Kingdom): CPP $0.02 (~5.7 R$/player) on "a few thousand" Robux; audience 57% US, 12.5% UK; ages 38% 18+, 18.6% 13-17, 23.9% 9-12, 20.6% under 9; devices tablet > PC > iPhone. Replies: bid $0.01 on less competitive platforms; desktop is more competitive (low bids may not spend) — [Optimizing my game's Cost Per Play (Jul 2024)](https://devforum.roblox.com/t/optimizing-my-games-cost-per-play-from-ads/3047197)
- Aug 2024: 3,000 R$ budget / 11 credits; ~2,000 clicks from 90,000+ impressions (~2.2% CTR); OP called it "widely unsuccessful" — [It is worth it to advertise (Aug 2024)](https://devforum.roblox.com/t/it-is-worth-it-to-advertise-sponsor-an-experience/3113357)
- Mar-Apr 2025 replies: 20 credits -> 640.2k impressions & 4k plays (~0.6% impression-to-play, ~$0.005/play); 2 credits -> 265k impressions & 1.5k plays (~$0.0013/play) — [Leveling Up Ads Manager (Mar 2025)](https://devforum.roblox.com/t/leveling-up-ads-manager-with-new-features/3587640)
- Jan-Mar 2025: 5.14 credits -> 1,626 visits (~$0.003/visit) — [Using Ads Manager For The First Time](https://devforum.roblox.com/t/using-ads-manager-for-the-first-time/3342871)
- Oct 8-13, 2025: impressions per ad credit fell from ~20k to 7.5k (later ~10k), i.e. ~2-3x more expensive; play rate (play/impression) 4.2% vs 3.6% previously. Reply blames more advertisers in the auction — [Why are sponsored ads suddenly x3 more expensive? (Oct 2025)](https://devforum.roblox.com/t/why-are-sponsored-ads-suddenly-x3-more-expensive/3983531)
- Nov 2025 reply: classic flow 17.22 credits -> 5,832 R$ revenue (1,395 plays, ~$0.012/play); new flow 95.77 credits -> 1,011 R$ revenue (12,370 plays, ~$0.0077/play). Multiple devs report more plays but much less revenue on new flow — [Ads Manager Updates Nov 2025](https://devforum.roblox.com/t/ads-manager-updates-home-search-combined-new-benchmarks-and-sunsetting-the-classic-flow/4084863)
- Jan 18, 2026: dev with $2,500+ spent in 2026 reports CPP ~$0.01 (classic) -> ~$0.024 (new Ads Manager), +140%; staff "assigned for review", no fix as of Mar 21, 2026 — [The new Ad Manager is underperforming (Jan 2026)](https://devforum.roblox.com/t/the-new-ad-manager-is-underperforming-and-i-am-considering-a-permanent-suspension-of-all-ad-spend/4269150)
- Early 2024: 5,700 R$ -> ~15,000 impressions vs earlier 500 R$ -> 61,000 impressions (new Ads Manager launch); 10,000 R$ under old sponsor system -> 130-180 peak CCU, 30-50 next day — [Sponsored Experiences moving to Ads Manager p.13 (Jan-Mar 2024)](https://devforum.roblox.com/t/sponsored-experiences-moving-to-ads-manager/2661756?page=13)

**Audience/device notes**
- 2023 (older, pre-new-Ads Manager): best icon got 3.5% CTR among older mobile males; gameplay-trailer thumbnail <1%, 500 R$ wasted; console had much lower CPP than mobile; removal of under-13 targeting doubled cost-per-click; PC users played ~50% longer than mobile — [My Experiments with Sponsored and User Ads (2023)](https://devforum.roblox.com/t/my-experiments-with-sponsored-and-user-ads/2420807)
- Aug 2024 reply: target mobile rather than PC — [It is worth it to advertise](https://devforum.roblox.com/t/it-is-worth-it-to-advertise-sponsor-an-experience/3113357)
- Current docs (2026): targeting by location, age, gender, genre, device; audience segments New / Recent / Lapsed / All players; objectives now Plays, Earnings (limited), Engagement — [Roblox Docs: Ads Manager](https://create.roblox.com/docs/production/promotion/ads-manager)

**Third-party aggregator (treat with caution)**
- BLOXG (Mar 2026, claims 850+ promoted games): Sponsored Experiences CTR 1.2%, CPC $0.25, CPP $0.45; top-10% icon CTR 5%+ — [BLOXG Advertising Benchmarks 2026](https://bloxg.com/statistics/roblox-advertising-benchmarks). **Contradicted** by Roblox's official CPP benchmarks ($0.007-$0.019) and every dev report above ($0.003-$0.024), which are 20-60x lower. Not credible for CPP.

### Inferences
- Realistic CPP for a small dev in 2026: ~$0.01-$0.025 per play (Maximize Plays), ~$0.02+ per genuinely new user. At 285 R$/credit, $0.01/play ~ 2.85 R$ per play; $0.02 ~ 5.7 R$ per play.
- "Impressions per credit" (~7.5k-20k in late 2025) and play rate (~3.5-4.5% play/impression) are the two ratios devs track; a ~2% CTR was considered a failure in 2024, 3.5%+ considered good.
- New flow yields cheaper but lower-quality plays (less revenue per play); judge on revenue/retention of ad cohort, not CPP.

### Gaps
- No public genre breakdown (simulator vs tycoon vs idle vs strategy) of CPP/CTR found from any credible source.
- No CPM or CPC published by Roblox; no region-level CPP.
- No 2026 data on the newest Plays/Earnings/Engagement objectives' CPP.

## 2. Metrics to hit before spending; ads on low-retention games

### Takeaway
Community consensus: ads don't fix a game — get retention, session length and monetization right first, then use ads to feed a game that already converts. No credible published numeric threshold (e.g. "D1 >= X%") was found in forum sources.

### Cited Findings
- "ads WILL NOT carry your game"; ads complement quality; 2-month-old low-CCU games are read by the algorithm as low quality — [It is worth it to advertise (Aug 2024)](https://devforum.roblox.com/t/it-is-worth-it-to-advertise-sponsor-an-experience/3113357)
- "Before throwing serious Robux on ads, ensure the game is as good as it can be"; cheap acquisition means nothing without retention — [My Experiments (2023)](https://devforum.roblox.com/t/my-experiments-with-sponsored-and-user-ads/2420807)
- Focus first on what the algorithm rewards: in-game spending, session length, returning player rate, server/client performance; "no guarantee of ROI immediately or ever" — [Game launch advertising cost (2025)](https://devforum.roblox.com/t/game-launch-advertising-cost/3667546)
- Nov 2025: ads reach broad audiences so ad-cohort analytics look bad; use ads mainly at launch or when not getting Home recommendations; unclear whether sponsored plays count in D1/D7/D30 — [Does sponsoring improve retention? (Nov 2025)](https://devforum.roblox.com/t/does-sponsoring-improve-retention/4073864)
- 200 CCU from 22,000 R$ on a new game dropped to 0-4 CCU within 8 hours — [Ads Manager p.13 (2024)](https://devforum.roblox.com/t/sponsored-experiences-moving-to-ads-manager/2661756?page=13)
- Example of a weak-retention game asking for help: D1 2.83%, 9.9-min sessions (Aug 2026) — [Improving D1 Retention (Aug 2026)](https://devforum.roblox.com/t/improving-d1-retention-for-game/4818622)
- Roblox analytics offers "similar experience benchmarks" (percentile vs comparable games) for retention/engagement — [Analytics: Similar Experience Benchmarks](https://devforum.roblox.com/t/analytics-similar-experience-benchmarks-broader-access/2210285)

### Inferences
- Practical gate: use Roblox's built-in similar-experience benchmark percentiles; if D1/D7 and session length are below median for the genre, ad money mostly buys players who leave.
- A D1 around 3% (example above) is clearly in "fix first" territory.

### Gaps
- No forum-verified numeric targets for D1/D7, payer conversion or ARPDAU before advertising; ROLearn (Feb 2026) claims genre-specific D1/D7 targets but content was gated — [ROLearn](https://rolearn.dev/guidance/first-week-retention-optimization/).

## 3. A/B testing icons and thumbnails

### Takeaway
Roblox's Thumbnail Personalization (Nov 2024) auto-tests up to 5 thumbnails on qPTR, reallocating hourly with results in hours; Ads Manager takes up to 10 16:9 creatives per campaign with per-creative tracking. Low-traffic games (<1k DAU) may not get meaningful thumbnail results. Icons cannot be natively A/B tested.

### Cited Findings
- Nov 13, 2024: up to 5 active thumbnails, impressions split evenly at first, every hour higher-qPTR thumbnails get more impressions per user group; stats after "a few hours"; average +8.5% qPTR, some +50%; testers: cut a "multi-day endeavor" to hours; games under ~1,000 DAU may not see meaningful results; keep multiple active — [Personalize your thumbnails (Nov 2024)](https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233)
- Personalization later "remembers your existing winning thumbnails" — [Thumbnail personalization remembers winners](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665)
- Thumbnail personalization and experiments now exposed via Open Cloud APIs — [New OpenCloud APIs (2026)](https://devforum.roblox.com/t/new-opencloud-apis-for-analytics-events-experiments-and-thumbnail-personalization/4828676)
- Devs still requesting native A/B testing for titles & icons (feature request) — [Add A/B Testing for Titles & Icons](https://devforum.roblox.com/t/add-ab-testing-and-stats-for-titles-icons/4778726); [Are you able to A/B test game icons](https://devforum.roblox.com/t/are-you-able-to-ab-test-game-icons/3339468)
- Ads Manager: up to 10 16:9 thumbnails per campaign (docs, 2026); up to 5 with performance tracking (Mar 2025) — [Docs](https://create.roblox.com/docs/production/promotion/ads-manager); [Leveling Up Ads Manager](https://devforum.roblox.com/t/leveling-up-ads-manager-with-new-features/3587640)
- Community tactic: split budget into small test ads (e.g. four 250 R$ ads) then put remainder (2,000 R$) on the winner (2023) — [My Experiments](https://devforum.roblox.com/t/my-experiments-with-sponsored-and-user-ads/2420807); 100 R$ test groups (2020) — [Best time to sponsor](https://devforum.roblox.com/t/whats-the-best-time-to-sponsor/752171)
- Static icons beat gameplay-video thumbnails in 2023 test — [My Experiments](https://devforum.roblox.com/t/my-experiments-with-sponsored-and-user-ads/2420807)
- Roblox docs: Engagement campaigns "require several days to produce meaningful results" — [Docs](https://create.roblox.com/docs/production/promotion/ads-manager)

### Inferences
- A cheap way to test creatives on a small game: run a Maximize Plays campaign with several 16:9 creatives; the ad impressions supply the traffic thumbnail personalization lacks at low DAU.

### Gaps
- No forum consensus on sample sizes (impressions per variant) or statistical significance.

## 4. Budget pacing and timing

### Takeaway
Minimums dropped over time (campaign min 10 credits, buy min 1 credit as of Nov 2025; continuous campaigns since Aug 2025). Older forum advice favors weekends (Fri evening-Sat) and holidays and spreading spend over several days; modern data on time-of-day is thin.

### Cited Findings
- Mar 2025: daily min 50 credits, lifetime min 100 credits (criticized) — [Leveling Up Ads Manager](https://devforum.roblox.com/t/leveling-up-ads-manager-with-new-features/3587640)
- Aug 2025: continuous (no end date) campaigns; devs complained 2,850 R$ minimum is prohibitive — [Aug 2025 update](https://devforum.roblox.com/t/ads-manager-updates-acquire-new-users-continuous-campaigns-and-more/3862159)
- Nov 2025: min Ad Credit purchase 10 -> 1; campaign min 10 credits; classic flow sunset Jan 2026 — [Nov 2025 update](https://devforum.roblox.com/t/ads-manager-updates-home-search-combined-new-benchmarks-and-sunsetting-the-classic-flow/4084863)
- 2025 advice: spend "probably no less than $100" per campaign; example $100/day for a week; test staggered vs concentrated spend with the same budget — [Game launch advertising cost](https://devforum.roblox.com/t/game-launch-advertising-cost/3667546)
- 2020 (old): "ALWAYS sponsor on the weekend"; Fri 4-5 PM to catch Saturday; holidays like Christmas; split 20k into 4 days x 5k — [Best time to sponsor (2020)](https://devforum.roblox.com/t/whats-the-best-time-to-sponsor/752171)
- Weekend/peak competition: more advertisers -> higher bids (Oct 2025 reply) — [x3 more expensive](https://devforum.roblox.com/t/why-are-sponsored-ads-suddenly-x3-more-expensive/3983531)
- High CCU spikes = fast credit burn, not sustainable growth (2025) — [Using Ads Manager First Time](https://devforum.roblox.com/t/using-ads-manager-for-the-first-time/3342871)

### Inferences
- Weekends bring more impressions but also more bidders; with Roblox auto-bidding, a steady continuous campaign probably smooths cost. Pair spend with an update so ad traffic lands on fresh content.

### Gaps
- No 2024-2026 data comparing weekday vs weekend CPP, time zones, or update-day spikes.

## 5. Does ad traffic kick-start organic recommendations?

### Takeaway
Roblox says ad performance does not affect organic "Recommended for You" rank; most devs since 2024 report traffic drops to near zero when campaigns end. Indirect effect is plausible only if ad-acquired players retain and pay well, feeding the engagement metrics the algorithm uses.

### Cited Findings
- Roblox (Sep 2025 / Mar 2026): "ad performance should not impact your organic rank in Recommend for You"; sponsored tiles now blended into Recommended for You — [Sponsored in Recommended for You](https://devforum.roblox.com/t/upcoming-tests-sponsored-experiences-to-appear-within-recommended-for-you-on-home/3938575)
- Jan-Mar 2024: consensus that new Ads Manager gives no residual algorithmic boost (old sponsors did: 30-50 CCU next day) — [Ads Manager p.13](https://devforum.roblox.com/t/sponsored-experiences-moving-to-ads-manager/2661756?page=13)
- Nov 2025: some believe ads can hurt by dragging analytics down with low-intent players — [Does sponsoring improve retention?](https://devforum.roblox.com/t/does-sponsoring-improve-retention/4073864)
- Aug 2025: some devs praised "algorithm integration success" (anecdotal, no numbers) — [Aug 2025 update](https://devforum.roblox.com/t/ads-manager-updates-acquire-new-users-continuous-campaigns-and-more/3862159)
- One established game: ~90% players from algorithm, ~10% off-platform — [Game launch advertising cost](https://devforum.roblox.com/t/game-launch-advertising-cost/3667546)

### Inferences
- Plan ads as paid acquisition that must pay back on its own; any organic lift is a bonus.

### Gaps
- No controlled evidence either way.

## 6. Failure stories and lessons

### Cited Findings
- 22,000 R$ (80 credits) -> 200 CCU -> 0-4 CCU within 8 hours (2024) — [Ads Manager p.13](https://devforum.roblox.com/t/sponsored-experiences-moving-to-ads-manager/2661756?page=13)
- 3,000 R$ / 11 credits, 2.2% CTR, "widely unsuccessful", blamed icon (Aug 2024) — [It is worth it to advertise](https://devforum.roblox.com/t/it-is-worth-it-to-advertise-sponsor-an-experience/3113357)
- 500 R$ wasted on gameplay-trailer thumbnail (<1% CTR) (2023) — [My Experiments](https://devforum.roblox.com/t/my-experiments-with-sponsored-and-user-ads/2420807)
- New flow: 95.77 credits -> only 1,011 R$ revenue vs classic 17.22 credits -> 5,832 R$ (Nov 2025) — [Nov 2025 update](https://devforum.roblox.com/t/ads-manager-updates-home-search-combined-new-benchmarks-and-sunsetting-the-classic-flow/4084863)
- $2,500+ spent, CPP 2.4x higher, considering stopping all ads (Jan 2026) — [Underperforming thread](https://devforum.roblox.com/t/the-new-ad-manager-is-underperforming-and-i-am-considering-a-permanent-suspension-of-all-ad-spend/4269150)

### Lessons (community)
- Fix icon/thumbnail first; test small; target less competitive devices; measure revenue per ad cohort; ads don't carry a weak game.

## 7. Payback math examples

### Takeaway
Only one forum example gives spend-vs-revenue: classic flow returned ~1.2x in gross Robux, new flow ~0.04x. Using official CPP, a game needs roughly 3-7 R$ gross per new ad player just to break even (before Roblox's cut on earnings).

### Cited Findings
- 17.22 credits (~4,900 R$ at 285 R$/credit) -> 5,832 R$ earned; 95.77 credits (~27,300 R$) -> 1,011 R$ (Nov 2025) — [Nov 2025 update](https://devforum.roblox.com/t/ads-manager-updates-home-search-combined-new-benchmarks-and-sunsetting-the-classic-flow/4084863)
- 285 R$ per credit / 2,850 R$ for 10 credits — [Using Ads Manager First Time](https://devforum.roblox.com/t/using-ads-manager-for-the-first-time/3342871)
- $0.02/play = ~5.7 R$/player — [Optimizing CPP (Jul 2024)](https://devforum.roblox.com/t/optimizing-my-games-cost-per-play-from-ads/3047197)
- Ads Manager "Earnings" metric includes ad revenue and in-game purchases from ad players — [Docs](https://create.roblox.com/docs/production/promotion/ads-manager)

### Inferences
- Break-even per ad play = CPP x 285 R$: $0.0073 -> ~2.1 R$; $0.0187 (new users) -> ~5.3 R$; $0.024 -> ~6.8 R$. Whether the "Earnings" figure is gross or after the 30% marketplace fee wasn't confirmed; if it's gross, a developer keeps ~70%, so they actually need ~3-10 R$ gross per ad player.
- Rule of thumb: run a small test (10-20 credits), divide the ad cohort's Earnings by credits x 285; scale if >=1.0 (or meaningfully improving after icon tweaks), stop if <0.3.

### Gaps
- No forum data on ad-cohort D7/D30 revenue or full LTV payback curves.
