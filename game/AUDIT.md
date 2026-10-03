# Idle Country Game: pre-launch bug and exploit audit (2 Oct 2026)

Scope: server/*.lua (every act.<name>, PlayerService, WorldService, Market, Raids, Takedown, GameServer, Store),
the shared formulas (Rules, Trade, Military, Officers, Tasks, Config) and the client modules (only for things that
break the game). No game files were edited. Every finding below was checked against the code; line numbers are for
the files as of commit 7753e22.

Severity: CRITICAL = prints money / loses paid items at scale; HIGH = paid feature or core loop broken, or economy
exploit; MEDIUM = exploitable or fails under load, needs a fix before launch; LOW = edge case or hygiene.

---

## Part 1: what games like this usually ship with (research)

| # | Common bug / exploit | What goes wrong | Source |
|---|---|---|---|
| 1 | Remote spam, no rate limit | Clients fire remotes hundreds of times a second; servers lag, budgets (DataStore, MessagingService) drain. Roblox: "always consider the maximum rate" for client-triggered logic, use a token bucket. | [Roblox docs: Securing the client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary) |
| 2 | Client-trusted values | Price, damage, reward or target sent by the client and used as-is. "Every piece of data sent from a client must be validated by the server." | same |
| 3 | NaN / inf / negative / huge numbers | "NaN is uniquely dangerous because it is of type number but fails all standard comparisons"; use math.isfinite. Negative amounts turn a withdraw into a deposit, etc. | same |
| 4 | Type confusion | Tables where numbers or strings are expected, fake "instances" as tables, strings used as string patterns. | same |
| 5 | Session locking missing or wrong | Rejoining fast loads the old save in a new server; two servers write the same key; dead locks after crashes. | [DevForum: Datastore Session Locking](https://devforum.roblox.com/t/datastore-session-locking/740302), [ProfileStore](https://devforum.roblox.com/t/profilestore/3190543) |
| 6 | Dupes by leaving mid-transaction | Two-sided transfers saved one side at a time; "if a player leaves while the trade is processing" items exist twice. Move value last, after all checks, and make it atomic. | [DevForum: Uniquely identifying objects and mitigating duplication](https://devforum.roblox.com/t/uniquely-identifying-objects-mitigating-duplication-glitches/1337329), [Trading dupe glitch](https://devforum.roblox.com/t/trading-dupe-glitch/1026853) |
| 7 | ProcessReceipt mistakes | Granting twice (no receipt id check), not granting (error path swallowed), returning PurchaseGranted before the save. Even the official sample once "robbed players of money". | [DevForum: ProcessReceipt sample robs players](https://devforum.roblox.com/t/marketplaceservice-processreceipt-code-sample-robs-players-of-money/2021619), [Player keeps getting dev product on rejoin](https://devforum.roblox.com/t/player-keeps-getting-developer-product-reward-when-rejoining/1700799), [ProcessReceipt fires multiple times](https://devforum.roblox.com/t/processreceipt-fires-multiple-times-with-each-product-purchase/2853262) |
| 8 | Gamepass checks failing | UserOwnsGamePassAsync throws (web outage) at join and the pass is treated as not owned; or it returns a stale false right after an in-game purchase ("the ownership API only periodically updates"). Docs: the server-side PromptGamePassPurchaseFinished values are reliable and update the cache. | [DevForum: gamepass prompt still firing after purchase](https://devforum.roblox.com/t/gamepass-prompt-still-firing-after-player-has-purchased-it/1890909), [MarketplaceService API](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService) |
| 9 | MessagingService assumed reliable | Docs: "Delivery is best effort and not guaranteed." Limits: 1 KB per message, 600 + 240 x players sent per server per minute, (40 + 80 x servers) received per topic per minute. Systems must survive dropped messages. | [MessagingService API](https://create.roblox.com/docs/reference/engine/classes/MessagingService) |
| 10 | MemoryStore treated as durable | Ephemeral, 1000 + 120 x CCU request units per minute, 32 KB per item, max 45 days TTL; "for data that needs to persist across sessions, use data stores". | [Memory stores docs](https://create.roblox.com/docs/cloud-services/memory-stores) |
| 11 | DataStore budget exhaustion | Per server: reads and writes 60 + 40 x players per minute, ordered writes 30 + 5 x players; per key 4 MB/min writes. Leaderboards and "lookup a name per row" patterns eat the read budget that player loads need. | [Data store limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits) |
| 12 | Tables with holes saved | JSONEncode uses the length operator: {[1]=1,[2]=2,[5]=5} saves as [1,2]; data after a gap is silently dropped. | [DevForum: tables with gaps in JSONEncode](https://devforum.roblox.com/t/tables-with-gaps-cause-strange-behaviour-in-httpservicejsonencode/4088719) |
| 13 | Clan / alliance races | Double join, leader leaves (no successor), disband while members act, treasury double spend from two servers, stale membership on other servers. Fix: every check inside the atomic UpdateAsync, periodic re-validation. | general DevForum consensus (items 5, 6) |
| 14 | Offline catch-up | Client clock trusted, no cap on offline time, compounding rewards offline, catch-up run twice on fast rejoin. | general (owner's previous-game notes) |
| 15 | Leaderboard abuse | Alt farming into the board, writing out-of-range values to OrderedDataStores, per-row GetAsync lookups. | items 11 and 6 |
| 16 | Server-hop / teleport raids | Per-server cooldowns reset by hopping, attacking offline players without a durable ledger, applying stale snapshots. | items 6 and 9 |
| 17 | Chat tag spoofing | Tags read from client-writable values or rich text injected via names. | general |
| 18 | Studio-only debug left live | Debug remotes or admin commands gated by name/userId instead of RunService:IsStudio, or reading workspace values a client can create. | item 1 |

Owner's lessons from his previous game (applied as audit criteria below): passes must always grant with a fallback if
UserOwnsGamePassAsync fails at join; watch save races; quest progress must credit live; every pcall must branch or
warn; per-hit caps are useless, budgets must be per second; one function per currency change; the display and the
payout must be the same expression.

---

## Part 2: findings, most severe first

### CRITICAL

**C1. Cross-server raids print money: an offline (or alt) target can be robbed forever while losing almost nothing.**
Raids.lua:291, 297, 305-309, 357, 380, 413.
- `queueHit` drops `rec.recent` entries older than 900 s (line 291). `cashOnHand` (305-309) subtracts only those
  recent steals from the stale war card. An offline defender's card is never republished, so 15 minutes after a
  raid the full card cash is "on hand" again.
- The attacker is paid immediately (`PS.Earn(p, steal)`, line 380) but the defender only pays when the queue is
  applied, and the queue keeps only the newest 30 entries (line 297); everything older is deleted unpaid. At login
  `ApplyHits` also clamps each steal to current cash (line 413).
- Spy entries share the same 30-slot queue (`remoteSpy`, 319-321), so an attacker can spy 30 times to push his own
  paid raids out of the queue.
- Exploit: main + alt. Alt reaches a high level, holds cash, logs off. Main attacks the alt from RANKINGS once a
  minute (per-target cooldown 60 s, 2 Supply). Each win pays up to 60 minutes of the alt's law income
  (stealCap). Over a 12 hour session that is up to 720 hits; the alt loses at most 30 entries' worth, clamped to its
  cash. Net: unlimited cash and Wealth ranking. Any real offline player is also farmable this way.
- Fix (escrow ledger, not a log):
  1. Never prune `recent` by time. Prune only entries with `t <= rec.applied`, a watermark the defender's server writes
     in the same UpdateAsync that drains the queue.
  2. Never evict raid entries. Keep spies in a separate list (or drop spies first), and veto new raids when the
     unapplied raids already total more than X% of `card.cash` (for example 30%, or 3 raids while offline).
  3. Give every entry an id (HttpService:GenerateGUID). In `ApplyHits`, apply only ids not in `d.appliedHits`
     (keep the last 100 in the profile), save the profile, then remove those ids from the queue in a second
     UpdateAsync. This also fixes H4 below.
  4. Optionally pay the attacker the clamped amount: queue a "loot" entry to the attacker with what the defender
     actually lost, instead of paying up front.

### HIGH

**H1. A failed gamepass check at join silently removes paid passes for the whole session (owner lesson #1).**
Market.lua:19-22, 198-201; PlayerService.lua:216-218.
- `CheckPasses`: if `UserOwnsGamePassAsync` errors, `owned = ok and r or false`, no retry, no fallback. The player
  loses VIP/Mega VIP cash, Auto Dispatch, Express, +2 Convoys, +3 Lots and the Bonus Officer slot until rejoin.
  `EnsureConvoys` then deletes the parked extra convoys (216-218) and `act.seat` clears officers seated above the
  slot count (Actions.lua:618).
- `PromptGamePassPurchaseFinished` re-asks `UserOwnsGamePassAsync`; if that errors or returns a stale false, the
  buyer gets nothing until rejoin. Roblox documents the server-side `wasPurchased` as reliable.
- Fix: retry 3 times with backoff; persist ownership in the profile (`d.ownedPasses[key] = true` whenever it is
  confirmed) and use it as the fallback when the call fails; re-check failed keys every 60 s; on the server
  purchase event trust `bought == true` (optionally verify in the background, never revoke on error).

**H2. Bank interest compounds every second with no cap, and the interest trait is uncapped.**
PlayerService.lua:641 (online), 618-621 (offline); Officers.lua:217, 377; Config.lua:81.
- Online: `d.bank += d.bank * 0.015 * (1 + interest) / 3600` every second, so 1.5 %/h compounds to about +43 % per
  day; the 10 % deposit fee is earned back in about 7 hours of AFK. `O.Caps` caps only `losses` and `regen`, so
  Central Banker officers (up to 40 % each, one per slot, 8 slots) plus Legendary+ gear perks can push the rate to
  10 %/h or more (about 11x per day AFK). Roblox's idle kick is trivially bypassed.
- Fix: keep Kash's 1.5 %/h but pay simple interest on a capped base, for example interest only on the first
  `MinuteValue(lv) * 600` of the balance, or cap interest per hour at a fraction of the player's own hourly income.
  Add `interest = 100` (or lower) to `O.Caps`.

**H3. Cross-server SPY always errors (the RANKINGS spy button is broken).**
Raids.lua:137 (call) vs 272 (definition).
- `RA.Spy` calls `remoteUid(id)` but `local function remoteUid` is declared 135 lines later, so inside `RA.Spy`
  the name resolves to a nil global. Every spy on a player who is not in this server throws "attempt to call a nil
  value"; GameServer turns it into "Something went wrong". Kash's rule is that stats are hidden until you spy,
  so cross-server targets can only be attacked blind.
- Fix: forward-declare `local remoteUid` next to `findTargetPublic` (line 20) and assign it at line 272
  (`remoteUid = function(id) ... end`), or move the function above `RA.Spy`.

**H4. A Raid Shield (39 Robux) does not stop cross-server hits for up to 2 minutes, and queued hits are not
idempotent.** Raids.lua:336, 398-406, 409-423.
- `remoteAttack` checks `card.sh`, the shield on a war card published up to 2 minutes ago; `ApplyHits` never checks
  the shield, so a player who just bought a shield still loses cash and soldiers.
- `ApplyHits` empties the queue in the DataStore first, then applies in memory. If the server crashes before the
  next autosave (up to 60 s), or the player leaves while the UpdateAsync yields (line 406 returns after the queue was
  already emptied), those hits are gone: the attacker kept the cash, the defender never paid.
- Fix: write `rec.sh = d.shield` into the hits record when a shield is granted (Market grant.RaidShield,
  Actions.sealBuy) and veto in `queueHit`; in `ApplyHits` refund (do not apply) raids whose `t` is inside the
  shield. Use the id/watermark scheme from C1 so applying is idempotent.

### MEDIUM

**M1. Finish Convoy can be bought at the 9 Robux price for a long trip.** Market.lua:48, 55-65; Actions.lua:318-326.
- The intent stored is only the convoy index. Open the FinishConvoy1 prompt (9 Robux, at most 10 minutes left),
  leave it open, let the convoy arrive and re-send it on a 10 hour trip, then confirm: `finishConvoy` finishes
  whatever that slot is doing now. FinishConvoy4 costs 49.
- Fix: store `{ i = i, t1 = c.t1, key = key }` as the intent and, at grant time, only finish if the slot still has
  that `t1`; otherwise refund as gold (already done for "arrived").

**M2. ProcessReceipt records the receipt only after a grant that can yield, and races the leave save.**
Market.lua:164-184, 128-137.
- `grant.RevengeStrike` runs `RA.Attack`, which can yield on DataStore calls. The receipt id is inserted after the
  grant (line 180), so a second invocation for the same PurchaseId during the yield (Roblox re-sends unprocessed
  receipts, see research item 7) grants a second guaranteed raid.
- No `p.leaving` check: a receipt processed while `PlayerRemoving` is saving calls `PS.Save(plr)` (non-release) in
  parallel with the release save. Saves are not serialized per player, so the lock can be re-taken for 90 s
  (next server waits about 12 s) or, if the release write lands last, the grant is lost after PurchaseGranted.
- Fix: keep an in-flight set `inFlight[PurchaseId]` (return NotProcessedYet if present); return NotProcessedYet
  when `p.leaving`; serialize saves per player (a `p.saving` flag plus "save again when done" bit).

**M3. Actions keep running after the player has left, and some charge after the yield.**
GameServer.server.lua:43-48; Actions.lua:725-735 (allyCreate), 736-748 (allyJoin).
- The busy-wait (up to 8 s) never re-checks `p.leaving`, and yielding actions never re-check after the yield.
  `allyCreate` checks cash, yields on two DataStore writes, then deducts. If the player leaves during the yield,
  the release save already ran: the alliance exists with them as leader, the 50,000 founding cost was never
  saved, and `d.alliance` was never saved (orphan leader; they can found or join another, so one user can lead
  several alliances). `allyJoin` likewise leaves an orphan membership plus a free treasury credit of the fee.
- A raid (local or AI) during the yield can also push cash negative because the deduction happens after.
- Fix: deduct before the remote write and refund on failure (as `allyDonate` already does at line 766); after
  every yield, `if PS.Profiles[plr] ~= p or p.leaving then` undo the remote change or return. In GameServer, re-check
  `p.leaving` after the busy-wait.

**M4. Alliance records go stale on other servers; kicked members keep stipend, perks and rent/tax exemptions.**
WorldService.lua:154-157, 481-488; GameServer.server.lua:60-74; PlayerService.lua:627-633, 81-83.
- A server only refreshes an alliance record when a MessagingService message arrives (best effort). Nothing
  re-validates membership or settings periodically (`RefreshIndex` every 120 s fires "all", which the GameServer
  handler ignores). A dropped message means a kicked player keeps `d.alliance` for the session: STATE STIPEND
  income (`StipendRate` never checks membership), city perks, no rent in that alliance's capitals and no convoy tax.
  Dues settings, upgrades and roles also stay stale.
- Fix: every 60 to 120 s, `LoadAlliance` each alliance that has members in this server and fire "a" for it; make
  `StipendRate`/`RentFor`/`TaxFor` require `a.members[uid]`.

**M5. Message fan-out burns every server's DataStore read budget.** WorldService.lua:154-157, 296-303, 481-487;
Takedown.lua:241-242.
- Every `MutateAlliance` publishes "a", including the treasury flush every 30 s per alliance per server (dues and
  rent make this constant) and the Takedown flush every 20 s. Every server, even one with no members of that
  alliance, answers each message with a `GetAsync`. With 30 servers and 5 active alliances per server that is
  hundreds of reads per minute per server against a budget of 60 + 40 x players; a 1 to 2 player server is
  throttled, which delays player loads and saves. Past 40 + 80 x servers messages per minute the topic drops
  messages, feeding M4.
- Fix: include `rev` in the message and skip `LoadAlliance` when the alliance is not cached here or the cached rev is
  newer; do not publish for treasury-only changes (send treasury in the periodic refresh); flush the treasury every
  2 to 5 minutes instead of 30 s.

**M6. No cooldown on alliance actions: join/leave/donate/open spam.** Actions.lua:736-757, 758-777, 842-852.
- Only the global 25/s limit applies. Join+leave in a loop writes the alliance key, the shared "index" key (member
  count changes the summary) and publishes to every server each time; `allyDonate` of $1 does the same and floods
  the 40-line log (pushes out real history). One player can drive M5 on purpose.
- Fix: per-player cooldowns (join/leave 30 s, donate/open/settings 2 s), minimum donation (for example 1 minute of
  law income), and do not write the index for count-only changes more than once a minute.

**M7. The request budget is per-hit sized, and every request pushes a full snapshot (owner lesson: budgets per
second).** GameServer.server.lua:29-36, 53; PlayerService.lua:453-480.
- 25 requests/s per player, and each one (even a failed one) calls `PS.Sync`, which rebuilds `Snapshot`: Mods for
  the player, `RA.Targets` (Power and Mods for every player in the server), the full inventory (up to 200 gear and
  every officer) and the alliance record. A modified client spamming `saveSettings` costs 25 full snapshots per
  second of bandwidth and CPU.
- Fix: token bucket of about 8/s with burst 15; mark `p.dirty` instead of syncing inline and let the 1 s heartbeat
  (or a 0.25 s debounce) send at most one full sync; skip the sync when the action returned `ok = false`.

**M8. `PS.Load` is not protected: any error leaves the player stuck on "Still loading" forever.**
PlayerService.lua:531-585, 62-75.
- An unexpected save shape (for example a v1 property index that no longer exists: `D.Props[p].cost` in `migrate`)
  throws inside the PlayerAdded handler. The DataStore lock is held, `PS.Profiles[plr]` is unset or stuck with
  `loading = true`, and every request returns "Still loading" (a soft lock).
- Fix: wrap the body in pcall; on failure release the lock and `plr:Kick("Your save could not load, please rejoin")`
  or continue with `canSave = false` and a toast. Validate migrated indices (`D.Props[p]` exists).

**M9. One failed MemoryStore probe at startup forks the world for that server's lifetime and can overwrite the
city backup.** Store.lua:212-214, 225-239; WorldService.lua:118-122, 498.
- `S.MemOnline` is decided once. If the probe fails transiently, this server keeps cities in a local table: its
  players capture cities nobody else sees, and every 10 minutes `backupCities` writes this forked view over the
  shared DataStore backup ("cities"), which `restoreCities` later trusts.
- Fix: retry the probe in the background and switch back on; never run `backupCities` while `MemOnline` is false;
  in `backupCities` merge per city by a version field instead of replacing the whole snapshot.

### LOW

**L1. `act.seat` can create a hole in `cab.slots`.** Actions.lua:607-620; Officers.lua:370.
Seating a benched officer straight into slot 3 while slot 2 is nil gives `{a, nil, b}`. `O.Bonuses` iterates with
`ipairs`, so officer b gives no bonus, and JSON saves drop data after a gap (research item 12), so b is unseated
after rejoin. Fix: when seating into slot k, fill `slots[1..k-1]` nil entries with `false`.

**L2. `WS.Join` charges the fee the client saw, does not check existing membership, and double-credits on retry.**
WorldService.lua:248-260; Actions.lua:741-745. If the leader lowered the fee, the joiner still pays the old higher
fee. If UpdateAsync commits but the call errors and retries, `a.treasury += fee` runs twice. Fix: return
`a.joinFee` as the result and charge that; `if a.members[uid] then return a, true end` before adding the fee.

**L3. Alliance tags are not unique; names are only checked against this server's cached index.**
WorldService.lua:212-223. Anyone can found "[TOP]" next to the real top alliance, and two servers can create the
same name at once. Fix: reserve name and tag in their own DataStore keys (`UpdateAsync` that fails if taken).

**L4. Tiny deposits skip the bank fee; the deposit and donate dailies cost $1.** Actions.lua:455-464, 758-777;
Tasks.lua:244-245. `fee = floor(amt * 0.10)` is 0 for amounts under 10, and the "Deposit cash" / "Donate" orders
complete with a 1 cash action. Fix: `fee = math.ceil(...)` and a minimum deposit/donation for task credit (for
example 1 minute of law income).

**L5. Takedown and tickets are still live although Kash removed them (21:15).** Actions.lua:186-195, 423;
Tasks.lua:286-287; Takedown.lua:220-236. The endpoints, the 20 s flush and the ticket items in the Merits shop still
run, and `TD.Claim` pays from a view that includes this server's unflushed hits (rewards for a stage that may never
be written). Fix: remove the actions from `A.list`, stop `TD.Start`, remove ticket shop items.

**L6. Several pcalls swallow errors silently (owner lesson).** WorldService.lua:155, 481; Raids.lua:261, 281, 549,
578; PlayerService.lua:716. Failed card publishes, subscriptions, rankings writes and AI raids leave
no trace. Fix: `local ok, err = pcall(...) if not ok then warn(...) end` on each.

**L7. Currency changes bypass `PS.Earn`, and the law card shows a different number from the payout (owner lessons).**
Market.lua:90 (`TreasuryGrant` adds cash directly), Actions.lua:128, 470, 479 (refunds, withdraw, loan), Raids.lua:414,
491, 536 (raid losses edit `cash` directly). Economy.lua:145 shows `R.LawCash(...)` while the server pays
`LawCash * (0.9 to 1.1)` minus dues and loan repayment (Actions.lua:82, PlayerService.lua:141-153). Fix: route every
change through `PS.AddCash(p, delta, src, opts)` (opts: skip dues/loan); show "~$X" or the exact net range on the card.

**L8. Rankings do one `GetAsync` per row.** PlayerService.lua:736-743. 50 name lookups per board per minute per
server; in a 1 player server (100 reads/min) that competes with the player's own load and save. Fix: store name,
flag and tag inside the war card or one cached `IC_Names` batch, and cache names for 10 minutes.

**L9. `RA.Attack` spends your per-target cooldown before the shield check.** Raids.lua:446-447. Attacking a
shielded player puts a 60 s timer on that target's button. Fix: set `p.raidCd[id]` after the shield and Supply checks.

**L10. A removed trait key would brick every profile holding it.** Officers.lua:365, 373. `b[t.k] += t.v` errors when
`t.k` is not in `O.Traits`, so `PS.Mods` throws in `Step` and `Snapshot` (no syncs, soft lock). Fix:
`b[t.k] = (b[t.k] or 0) + t.v` and ignore unknown keys.

**L11. Studio sessions on the live store get Studio-granted passes.** Market.lua:17; PlayerService.lua:502-505.
Without `IC_TestProfile`, a Studio playtest writes the LIVE save with every pass granted (Mega VIP officer
`d.vipOfficer`, extra convoys and lots used). Fix: only apply `StudioGrantsPasses` when `IC_TestProfile` is set.

**L12. Hard-coded city count.** Market.lua:71 checks `city > 41`; use `#World.Cities`.

**L13. Client: one bad note stops the rest, and an uncached alliance shows the join screen.**
ClientMain.client.lua:430, 499 (`handleNotes` not wrapped in pcall per note); Social.lua:208 (when `st.alliance` is
set but `alliance_rec` is nil, e.g. the record read failed at load, the screen offers JOIN, which then fails with
"Leave your alliance first"). Fix: pcall each note; show "Alliance loading... / LEAVE" when the id is set but the
record is missing.

---

## Checked and OK (no action needed)

- Studio debug bridge (GameServer.server.lua:97-159) and the client IC_Cmd hook (ClientMain.client.lua:528) are
  inside `RunService:IsStudio()`; nothing is reachable in live servers. Only two remotes exist (Request, Sync) and
  the server only listens on Request.
- Session lock: load takes the lock in UpdateAsync, saves refuse to overwrite another server's fresh lock, leave
  releases it, stale locks expire after 90 s.
- ProcessReceipt checks the receipt id, returns NotProcessedYet when the profile cannot save, and returns
  PurchaseGranted only after a successful save that includes the receipt id.
- Number validation: `int()`, `amountArg`, `PS.Earn`, `WS.Credit`, tax/rent/fee/dues clamps all reject NaN and inf;
  no client string is ever used as a pattern; tables in args are type-checked.
- Alliance treasury: every spend and role check happens inside the UpdateAsync callback (no double spend across
  servers); member cap is atomic; leader leaving hands over to the senior officer/member; last member out disbands
  and frees the cities. There is no treasury withdrawal, so treasury bugs cannot mint player cash.
- Offline catch-up uses server `os.time`, is capped at 12 h, convoys are clipped to the window, and `lastSeen` is
  captured before any yield.
- VIP chat tags come from a server-set player attribute; clients cannot spoof them for others. Names are filtered
  with TextService before they are shown to anyone.
- Shared formulas (Rules, Trade, Military, Tasks): no divide by zero (all divisors use math.max(1, ...)), XpReq is
  always at least 15 so level loops terminate, costs and payouts stay positive. The only runaway value is the bank
  (H2).
