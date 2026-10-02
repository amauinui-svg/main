# Client brief (for building new screens)

Game: "Idle Country" (Roblox idle strategy, Idle-Mafia-like). Read `game/FEEDBACK.md` (owner Kash's decisions) first.
Reference screenshots of the competitor (Idle Mafia) are PNGs in `/root/.claude/uploads/62ee7c29-3555-51be-b0ac-e51c354a3caf/`
(view them with the Read tool). Copy their LAYOUTS (rows, cards, header stat boxes, popups), but use OUR kit and theme.

## Code conventions
- Client modules live in `game/client/*.lua`, are ModuleScripts in ReplicatedStorage.Client, and return a table of
  screen definitions: `return { keyname = { build = function(host, App) ... return obj end } }` where obj may have
  `obj:Refresh(state)` (called on every full sync while visible and when opened), `obj:Tick(state)` (every 0.25 s while
  visible) and `obj:Opened()`. ClientMain merges every module's defs; nav keys open them with `App.open(key)`.
- Read `client/UI.lua` (the kit: UI.img/text/icon/button/bar/panel/card/chip/badge/list/tabs/flag, UI.C colors,
  UI.Font) and `client/ClientMain.client.lua` (App API: App.req(action,args,btn) -> result table {ok,msg,...};
  App.toast(title, body, tone); App.float(gui, text, color); App.confirm(title, body, okLabel, kind, fn);
  App.modalHost (a full-screen TextButton for popups: UI.clear it, set Visible=true, build a panel inside);
  App.state (the full snapshot), App.now(), App.on("tick"/"full"/"world", fn), App.W()/App.H(), App.content).
  Also look at `client/Economy.lua` and `client/Social.lua` for how existing screens are written; match that style.
- Design size: the content area is (App.W() - 176) x (App.H() - 64) design pixels, about 1104 x 656 on a 1280x720
  screen, and down to ~820 x 496 on phones. Layout must not overflow at those sizes: use scrolling lists.
- Image keys: `game/Assets.lua` (UI.img(parent, key, {...}) / UI.asset(key)). Useful keys: country_era1..8 (wide
  scenes), prop_e{era}_t{1..3} (isometric buildings), tile_owned/tile_forsale/tile_locked, construct, smoke_puff,
  gear_sword/spear/musket/saber/rifle/halberd/helm/cuirass/coat/shield/plate, officer_1..8 (WHITE silhouettes:
  tint with ImageColor3 = rarity color), crate_basic, crate_limited, icon_seal, icon_ticket, medal_bronze/silver/gold,
  takedown_bg, enemy_guard/soldier/general, loading_bg, aura glow etc., and the Lucide-style white icons icon_*
  (tint them). Images are wide/square PNGs: use ScaleType Fit or Crop as needed (UI.img(..., {fit=true}) or set
  ScaleType yourself; pass slice=false for non-plates).
- Shared data modules (require from ReplicatedStorage.Shared): Rules (R.Money, R.Short, R.Commas, R.Clock,
  R.Duration, R.EraOf(lv), R.MinuteValue...), GameData (D.Eras names), Officers (O.Rarities with color hex, traits,
  O.HireOdds, O.TraitByKey...), Tasks (TK.Daily, TK.Diff, TK.Shop, TK.Login...), Config (prices, passes, products).
- Every action the server supports is a `function act.<name>(plr, p, a)` in `server/Actions.lua`; read the ones you
  call so you pass the right args and read the right result fields. State fields come from `PS.Snapshot` in
  `server/PlayerService.lua`.
- Do NOT edit ClientMain, UI.lua, server files, or other people's modules. Only create the module file(s) you were
  given. If you need a kit helper that does not exist, write it locally inside your module.
- Polish matters (Kash: "make it feel published"): hover lift/scale tweens on cards and buttons, rarity glow
  (UIStroke in rarity color, a soft aura image behind rare items), numbers that count up, smooth popups
  (scale-in with TweenService), no text overflowing, consistent padding (12-16 px), UIListLayout SortOrder =
  LayoutOrder always. Keep descriptions short; add small "i" info buttons where a system needs explaining.
- Verify syntax with: `/tmp/claude-0/-home-claude/62ee7c29-3555-51be-b0ac-e51c354a3caf/scratchpad/tools/luau-compile --null <file>`.
  You cannot run the game; be careful with nil checks (state fields may be missing on old saves).
- Don't commit or push; just leave the file(s) in place and report what you built, the action names you used and
  anything the server is missing.
