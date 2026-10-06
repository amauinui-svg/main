# Roblox Official Advertising Products for Game Developers (state as of Oct 2026)

Research date: 2026-10-06. Primary sources: Creator Hub docs (create.roblox.com) and official DevForum Announcements. Note on dates: DevForum tag listings show "latest activity" dates; the original post dates below come from the posts themselves. Fetched page content was summarized by a tool, so quote-level details should be spot-checked in the live UI before spending.

## 1. What ad formats exist, and which can a small developer buy?

### Takeaway
A developer promoting their own game can self-serve exactly one product family: **Sponsored ads in Ads Manager**, which show as sponsored 16:9 tiles on Home and in Search results (video tiles rolling out from Oct 2026). A larger "Featured Tile" on Home is a managed beta with a $5,000 minimum. Rewarded Video, billboards, portals and the Homepage Feature are brand/programmatic products, or ways for a developer to *earn* from ads in their own game. They are not tools for promoting a game.

### Cited Findings
- Ads Manager offers one format: sponsored thumbnail tiles on the Home page and in search results, at 16:9, with up to 10 thumbnails per campaign "distributed evenly across players" — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- "Your ad campaign is automatically shown in both the Home page and search results." Placement cannot be chosen separately, so there is no standalone Search-ads product — [Ads Manager (sponsoring-experiences URL)](https://create.roblox.com/docs/production/promotion/sponsoring-experiences)
- History: in May 2025, Search was listed as upcoming ("looking to bring our Sponsored format to more placements and surfaces, including Search") — [More Ads Manager Upgrades, May 21, 2025](https://devforum.roblox.com/t/more-ads-manager-upgrades/3659656). It has since shipped (see the docs above).
- **Featured Tile (managed beta):** a "larger tile on Home" with prominent placement. Minimum investment is **$5,000 USD**, signup is by registration form, and it is described as "particularly impactful for well-known games" — [Ads Manager Updates: Maximize Earnings, Attribution, New Tile in Beta (May 7, 2026)](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762)
- **Video in Sponsored Tiles** is "rolling out over coming weeks," using gameplay videos in the same format as Home — [Ads Manager RDC Recap (Oct 2, 2026)](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- The creator advertising overview lists in-game formats: Rewarded Videos ("offer in-game rewards to incentivize players to watch click-to-play video ads"), Billboards (image/video) and Portals ("an image and an interactive door that teleports players to an advertised game"). Sponsored ads on Home/Search are the Ads Manager product — [Advertising for creators](https://create.roblox.com/docs/production/promotion/advertising-on-roblox)
- The Immersive Ads docs cover only the **publisher** side, meaning earning from ads in your game. Requirements: age 13+, ID-verified with 2FA, 2,000 unique visitors per month, and an approved Maturity & Compliance Questionnaire. Ineligible users see a fallback image or the Roblox logo — [Immersive ads docs](https://create.roblox.com/docs/en-us/production/monetization/immersive-ads)
- **Homepage Feature** (Jan 2026): a premium CPM-bought brand unit on the homepage, tested with e.l.f., Sam's Club and Universal's FNAF2. Rewarded Video has expanded to 400+ experiences and 1,000+ brands. Programmatic access goes through Amazon DSP and Liftoff (demand side) and Index Exchange, Magnite and PubMatic (supply side). These are brand-advertiser channels — [Roblox newsroom, Jan 2026](https://about.roblox.com/vi/newsroom/2026/01/roblox-expands-advertising-platform)
- Google is a partner on immersive ads and sells the inventory to brands — [Google blog](https://blog.google/products/ads-commerce/immersive-ads-roblox/); [MediaPost](https://www.mediapost.com/publications/article/404657/google-roblox-expand-immersive-ads-partnership-a.html)
- **Ads Manager API on Open Cloud** (test/beta announced Aug 2026) allows programmatic campaign management — [DevForum tag listing](https://devforum.roblox.com/tag/ads); [Open Cloud advertising guide](https://create.roblox.com/docs/cloud/guides/advertising)

### Inferences
- For a small developer the realistic menu is: Sponsored tile campaigns (Plays, Earnings if eligible, or Engagement), optionally with video tiles once rolled out. Featured Tile ($5k+) and brand formats are out of reach or don't apply.
- Portal ads that send players to an advertised game exist as an in-game format, but I found no current self-serve way for a developer to buy them through Ads Manager. Treat them as unavailable to self-serve buyers.

### Gaps
- I found no official notice in this research confirming the legacy Robux-bid "Sponsored Experiences" system (pre-2024, bid in Robux per day) is gone. Ads Manager docs now occupy the old `sponsoring-experiences` URL, which suggests it was replaced, but no deprecation date was found.
- No pixel dimensions or file-size spec for tiles was found. Only 16:9 is documented.

## 2. Pricing, bidding, budgets, Ad Credits and payment

### Takeaway
Pricing is **automated cost-per-play (CPP) bidding** only. You set a daily or lifetime budget and Roblox auto-bids, with no manual CPC/CPM option. You pay by card in USD (18+ only) or with Ad Credits converted from Robux (13+; permanent). The historical minimum spend was 10 ad credits (5/day for 2 days). Current docs state only a 1-credit minimum purchase.

### Cited Findings
- "With auto-bidding, you set an ad budget and duration and Roblox automatically calculates the bid that will get you the best performance at the lowest cost." The model is cost-per-play based — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md)
- Budget types are a daily budget ("maximum amount you pay for your ads per day") and a lifetime budget ("maximum amount you pay ... for the entire duration"). Budget type cannot be changed after publishing. Start date, start time and duration are customizable — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Minimum spend (May 2025): "10 ad credits (5 ad credits per day, with a 2 day minimum)" — [More Ads Manager Upgrades, May 21, 2025](https://devforum.roblox.com/t/more-ads-manager-upgrades/3659656). The current docs only say "1 ad credit is the minimum conversion requirement" and specify no campaign minimum — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md)
- If the audience is too small, ads "won't be shown and you won't be charged" (staff, Kayakrivers) — [More Ads Manager Upgrades](https://devforum.roblox.com/t/more-ads-manager-upgrades/3659656)
- **Card payment:** available to 18+ only. First-time users are charged $5 USD on submission, plus a temporary $1.00 verification hold refunded within 7 business days. After that you are charged when the payment threshold is reached or monthly, whichever comes first. The threshold "increases as you spend more on ads" — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- **Robux to Ad Credits:** available to 13+, minimum 1 ad credit, and a "permanent and irreversible action." Robux earned at the U.S. 18+ exchange rate are converted first. Group-earned Robux can become group ad credits if you have the "Configure and spend group revenue" permission — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager); [sponsoring-experiences doc](https://create.roblox.com/docs/production/promotion/sponsoring-experiences)
- Oct 2026: "US 18+ Robux conversion to ad credits with enhanced valuation" — [RDC Recap, Oct 2, 2026](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- **Auto-reload** buys ad credits automatically when the balance runs out, one day's worth at a time. Group campaigns need the group revenue permission — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- **Discounts:** "ads system discounts designed for games that make Roblox overall healthier." No amounts or criteria are published — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md)
- Oct 2026: "Highly retentive games now get better ad distribution" — [RDC Recap](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- Credit lifecycle: unused credits return when a campaign ends. Invalid (bot) traffic is refunded as an "Ad Fraud Refund" 16 days after the campaign ends, following a 14-day analysis. You can cancel up to 6 hours before the scheduled start, which refunds credits and avoids card charges — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- The Earnings and Engagement objectives cost more per play than Plays: Earnings has a "higher cost-per-play ... highly valuable, smaller subset" — [May 7, 2026 post](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762). For Engagement, "Expect a higher cost per play (CPP)" — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md)
- Benchmark from the Earnings beta: among 1,200+ beta games, two-thirds reached ROAS above 100% when reinvesting up to 4% of earnings — [RDC Recap](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)

### Inferences
- Since Kash's games earn Robux, converting Robux to credits is the default way to fund ads (Robux earned at the U.S. 18+ rate are used first). A card works only if the account holder is 18+.
- With no published CPP benchmark, a small test (around the old 10-credit / 2-day floor, or a few days at a modest daily budget) is the only way to learn the actual CPP for a genre.

### Gaps
- No official Robux-to-ad-credit exchange rate was found, and no official USD value per ad credit. Docs and announcements do not state it, so check the conversion screen in Ads Manager.
- No official typical CPP ranges were published.
- I could not confirm whether the 10-credit minimum campaign spend still applies in 2026.

## 3. Targeting, and the effect of the "Ages 16+ and trusted friends" restriction

### Takeaway
You pick an Audience (All, New, Recent, or Lapsed Players). Advanced targeting covers location, age, gender, genre and device type, but exact age bands aren't published. Roblox staff have said games that are ineligible for under-16 users automatically won't show ads to that group. A game limited to "Ages 16+ and trusted friends" will therefore only receive ad delivery to the 16+ audience, a much smaller and costlier pool, until it passes the Kids/Select eligibility gates.

### Cited Findings
- Audiences: All Players; New Players (never played, or inactive 180+ days); Recent Players (played within 30 days, requires 10,000+ recent players); Lapsed Players (inactive 30–180 days, requires 20,000+ lapsed players) — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Advanced targeting: "narrow down your audience by customizing settings like location, age, gender, genre, and device type." No band values are listed — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md)
- History: in May 2025 targeting was only geo and platform, with no age or gender targeting at that time — [More Ads Manager Upgrades, May 21, 2025](https://devforum.roblox.com/t/more-ads-manager-upgrades/3659656). A later "Ads Manager UI & Targeting Enhancements" announcement exists (latest activity Sept 2026), but I could not fetch it — [DevForum ads tag](https://devforum.roblox.com/tag/ads)
- Staff clarification: "Games ineligible for under-16 users won't show ads to that demographic automatically" — [May 7, 2026 post](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762)
- RDC 2026 recap mentions "age-appropriate guardrails for Tiles (users 13+)" and "Sponsored Tiles available to users 13 and under." The wording is ambiguous as summarized — [RDC Recap, Oct 2, 2026](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- **Why games show "Ages 16+ and trusted friends":** staff called it "intended behavior" (July 2026). Games stay restricted until they meet both sets of requirements. Account: ID verification, 2FA, good standing. Experience: a refundable 1,000 Robux submission fee and 500 highly engaged players over the past 60 days. Alternatively, a 100,000 Robux fee bypasses the engagement threshold — [DevForum thread, July 26, 2026](https://devforum.roblox.com/t/experience-limited-to-ages-16-and-trusted-friends-despite-having-minimal-content-rating/4758340)
- The official version (Roblox Kids and Select global launch, June 16, 2026) has the same requirements: an age-checked account with ID and 2SV, plus either a refundable 1,000 Robux publishing fee per game or two consecutive months of Plus/Premium. Games need **500 Highly Engaged Players** to enter, and maintenance was lowered to 25 HEPs over 60 days (updated July 16). **Expedited Review** costs a refundable 100,000 Robux, takes up to 48h and bypasses the HEP threshold; it is refundable after 90 days in good standing. Roblox said it would relax the HEP definition, estimating about 33% more daily entries — [Roblox Kids and Select Global Launch](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717)
- **Engagement objective (beta)** exists for games not yet eligible for Kids/Select. It targets "players whose sessions count toward your Highly Engaged Player threshold" (age-checked players). It costs more than Plays. It is meant for progressing toward eligibility, not discovery, and campaigns don't stop automatically once you hit the threshold, so pause them yourself — [Kids and Select launch post](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717); [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- One forum reply defines a "highly engaged player" as someone with minimum purchases anywhere on Roblox in the 60-day window. **This is unverified** (it came from the thread, not official docs) — [DevForum thread](https://devforum.roblox.com/t/experience-limited-to-ages-16-and-trusted-friends-despite-having-minimal-content-rating/4758340)
- Content maturity: Restricted (18+) experiences are accessible only to age-verified 18+ users. Free-form creation and social hangouts without private spaces are limited to 16+ — [Content maturity docs](https://create.roblox.com/docs/en-us/production/promotion/content-maturity)
- "Trusted Friends" (renamed from Trusted Connections, April 2026) is an age-checked inner circle. Cross-age friends can be added with parental consent — [Roblox newsroom, Apr 2, 2026](https://about.roblox.com/newsroom/2026/04/expanding-trusted-friends)

### Inferences
- For a game stuck at "16+ and trusted friends": a Plays campaign can only reach age-checked 16+ players (plus Trusted Friends of current players, organically). That pool is smaller, so expect higher CPP and fewer plays per dollar. Age-targeting choices below 16 do nothing.
- The **Engagement objective** is the official ad path designed to fix this. It buys the age-checked, high-value sessions that count toward the 500-HEP gate, after which the game unlocks under-16 audiences (Kids/Select) and normal Plays campaigns become much more efficient. The other route is the 100,000 Robux Expedited Review.
- For 13+/16+ planning, the targeting settings that matter most are age (set to match eligibility), country (cost differs by region), and device (mobile dominates the Roblox audience).

### Gaps
- Exact age-band values, gender options and genre list in the current Ads Manager UI were not retrievable. Check the UI.
- No official statement quantifies how much the 16+ restriction reduces reach or raises CPP.
- The current official definition of "Highly Engaged Player" after the relaxation was not found.

## 4. Campaign structure, optimization, learning period and metrics

### Takeaway
Ads Manager is flat: each campaign has a goal (Plays, Earnings, or Engagement), an audience, a budget and schedule, and up to 10 creatives per the docs (25 per the May 2026 announcement). There are no separate ad sets. Roblox auto-optimizes, campaigns sit in "Learning" for their first 24 hours, and reporting covers impressions, clicks, plays, CPP, playtime, earnings and ROAS, broken down by new, returning and resurrected users.

### Cited Findings
- Goals: **Plays** (broad, players most likely to start sessions); **Earnings** (Limited; high-value spenders; needs a developed economy); **Engagement** (age-checked highly engaged players, for Kids/Select progress) — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Earnings went to full release in Oct 2026 for "nearly 30,000 games." Eligibility uses monetization thresholds (games with **ARPU of 6 Robux or higher in H1 2026**). Estimated ROAS is shown weeks before final accrual, and earnings now display in USD alongside Robux — [RDC Recap, Oct 2, 2026](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- Earnings reporting includes Robux and a USD equivalent. It excludes subscriptions but includes ad revenue and Creator Rewards — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager); RDC recap adds Immersive Ads and Rewarded Video earnings — [RDC Recap](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- Editable after publishing: name, budget amount, schedule and creatives. Fixed: goal, audience and budget type — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager). Live budget adjustments were enabled May 2026 — [May 7, 2026 post](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762)
- **Creative count conflict:** the docs say "up to 10 thumbnails in a campaign" — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md). The May 2026 announcement says "Thumbnail capacity increased from 10 to 25 per campaign" — [May 7, 2026 post](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762). The docs may lag.
- Statuses: In Review, Moderated, Active, **Learning (first 24 hours)**, Scheduled, Inactive, Completed, Auto-Completed, Canceled, Error, Rejected — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- The pacing algorithm (May 2025) reduced traffic spikes by 80% — [More Ads Manager Upgrades](https://devforum.roblox.com/t/more-ads-manager-upgrades/3659656)
- Metrics: Spent (USD or credits), Impressions, Clicks, Plays, CPP, Playtime, Earnings, ROAS. Impressions and clicks are real-time. Plays and earnings arrive with delay (up to 30-day attribution), and full data takes up to 48h. Attribution windows: New Users 30 days post-join; Recent Users session-only; Resurrected 7D/30D — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Reporting filters for New, Returning and Resurrected users. Attribution changed in May 2026 to give less credit when ads only assisted and more when they led, so metrics may shift — [May 7, 2026 post](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762)
- Day-by-day campaign-level plays reporting (July 2026) — [Leveling Up Ads Manager, July 24, 2026](https://devforum.roblox.com/t/leveling-up-ads-manager-with-new-features/4755120). Custom date ranges and group ad accounts with a workspace selector came Oct 2026 — [RDC Recap](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- Incrementality: across 21 studied campaigns, median lifts were 14% in incremental play sessions and 10% in D7 retained users. Incrementality studies are available for Plays campaigns only — [RDC Recap](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- Advanced Join Options let you set a destination place and launch data, read via `GetJoinData()`. Launch data is visible in the URL — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Roblox marketing claims: 150% lift in impressions for games running ads, 24% more plays, 16% more playtime, and Hypershot getting up to 10% of plays from sponsored ads — [Advertising for creators](https://create.roblox.com/docs/production/promotion/advertising-on-roblox)

### Inferences
- There is no explicit retention or payer-conversion metric beyond Earnings/ROAS and D7 in incrementality studies. Track ad cohorts in-game yourself using launch data from Advanced Join Options.
- Avoid judging a campaign on day 1 (Learning period), and wait up to 48h, or the 30-day attribution window for earnings, before deciding.

### Gaps
- No published guidance on how long learning lasts beyond "first 24 hours," or on how many creatives is optimal.

## 5. Creative rules, specs and moderation

### Takeaway
Creatives are 16:9 thumbnails. You can upload them, reuse existing game thumbnails, or generate them with AI (3 variants per prompt, 100 prompts a day free). Since Oct 2026, gameplay video works in Sponsored Tiles. Moderation went from hours to minutes in Oct 2026, though the docs still say 24–48h. Non-unique metadata or assets reduce effectiveness.

### Cited Findings
- 16:9; from existing uploaded images, new uploads, or AI-generated (3 variations from a text description). Asset Library: upload up to 10 files at once, archive keeps performance history, and assets tied to live campaigns can't be archived — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Generative AI creatives: "100 prompts per day at no cost," up to 3 options per prompt. You can upload pre-moderated game assets as visual references to keep the output on-brand. Developers in the thread were skeptical of the quality — [Leveling Up Ads Manager, July 24, 2026](https://devforum.roblox.com/t/leveling-up-ads-manager-with-new-features/4755120)
- Moderation timing: docs say "Within 24 hours for each ad submitted" and also "typically 48 hours" for assets — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager). Oct 2026: "Campaign moderation reduced from hours to minutes" — [RDC Recap](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- "Games with non-unique metadata/assets may rank lower and see reduced effectiveness." Ad fraud leads to account suspension, non-payment leads to campaign suspension, and campaigns must follow the advertising standards — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- An official "New Advertising Policies & Standards" announcement exists (activity July 2026), but I could not fetch it — [DevForum ads tag](https://devforum.roblox.com/tag/ads). A third-party summary (creation.dev; **low-reliability aggregator**) says the changes roll out over 12 months from March 2026. Per that summary, unskippable ads can't block progression, immersive ads can't misrepresent gameplay, and "Sponsored" disclosure is required — [creation.dev](https://www.creation.dev/learn/roblox-advertising-policy-changes-2026)
- The official standards page is [Comply with advertising standards](https://create.roblox.com/docs/production/promotion/comply-with-advertising-standards). The fetched content did not include the specific prohibited-content rules.
- Background: Roblox's 2023 Advertising Standards (legal commentary) cover disclosure and child-directed advertising rules — [Davis+Gilbert](https://dglaw.com/faced-with-increasing-pressure-roblox-adopts-new-advertising-standards) (dated Apr 2023)

### Inferences
- Sponsored tiles use the campaign's own 16:9 creatives, not automatically the game's icon. Kash can test up to 10–25 thumbnails per campaign, and Roblox spreads impressions evenly across them, so a campaign works as a built-in thumbnail A/B test.
- Creatives should still follow general Roblox asset moderation and the advertising standards: no misleading claims, no off-platform links, nothing age-inappropriate.

### Gaps
- No pixel resolution, file size, text-overlay limits or explicit rejection reasons were found in retrievable official docs.
- I could not confirm which image the Sponsored tile shows when no custom creative is uploaded (likely the game's existing thumbnails).

## 6. Official guidance: best practices, thumbnail testing, ads vs organic

### Takeaway
Roblox says ad engagement does **not** count toward "Recommended for You" ranking. Its stated levers are retention (highly retentive games get better ad distribution), unique assets and metadata, and choosing the right objective. Separately from ads, Creator Hub offers thumbnail personalization/experimentation for organic thumbnails.

### Cited Findings
- Staff: ad engagement does not count toward Recommended for You algorithm rankings — [May 7, 2026 post](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762)
- "Highly retentive games now get better ad distribution" — [RDC Recap, Oct 2, 2026](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)
- Earnings objective is advised only for "well-monetized games (high average revenue per user)." Plays is for broad discovery. Engagement is for HEP threshold progress — [May 7, 2026 post](https://devforum.roblox.com/t/ads-manager-updates-maximize-earnings-attribution-updates-new-tile-in-beta-other-updates/4623762); [Kids and Select launch](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717)
- In May 2025, "2 in 5 campaigns already using 2 or more creatives," which encourages multiple creatives — [More Ads Manager Upgrades](https://devforum.roblox.com/t/more-ads-manager-upgrades/3659656)
- Earnings beta benchmark: two-thirds of games were ROAS-positive when reinvesting up to 4% of earnings — [RDC Recap](https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790)

### Inferences
- Ads can buy initial plays, but organic recommendation depends on how those players behave (retention, playtime, spend) once they're in. Fix D1/D7 retention before scaling spend. Better retention also improves ad delivery.
- Sequence for a 16+-restricted new game: (1) meet the account requirements (ID + 2FA) and pay the 1,000 R$ fee, or hold Premium for 2 months; (2) run a small Engagement campaign until 500 HEPs, pausing it manually; (3) once Kids/Select eligible, switch to Plays campaigns with 5–10+ thumbnails; (4) move to Earnings once ARPU passes about 6 R$.

### Gaps
- I did not retrieve the official thumbnail personalization/experimentation docs this session, so their specs and how they interact with Sponsored creatives are unverified.
- I found no RDC 2026 talk video transcripts. Only the DevForum recap was used.
