# Architecture

Full plan: `work/notes/BuyOrFarmForever-plan.md` in the development folder (not part of the repo).

## Layers

| Layer | Files | WoW API calls |
|---|---|---|
| Namespace | `Core/Init.lua` | none |
| Localization | `Locales/Locale.lua`, `Locales/deDE.lua` | none |
| Core helpers | `Core/Util.lua`, `Core/Log.lua`, `Core/DB.lua` | `Log.lua`: `DEFAULT_CHAT_FRAME`, `geterrorhandler` only |
| Core logic | `Core/Money.lua` (parse/format copper), `Core/Prices.lua` (prices per source), `Core/PriceCapture.lua` (merchant/auction capture, scan), `Core/FarmRuns.lua` + `Core/FarmRunsValidation.lua` (run state machine), `Core/FarmCapture.lua` (yield from bag changes), `Core/FarmEstimates.lua`, `Core/Materials.lua` (goals, requirements, shortfall), `Core/MaterialsValidation.lua` (stored goals), `Core/Recipes.lua` (imported recipes), `Core/Stock.lua` (bag/bank counts via adapter, snapshots) | none |
| Adapter interface | `Adapters/Adapter.lua` | `DEFAULT_CHAT_FRAME` (mismatch message) |
| Client adapter | `Adapters/ClassicEraProfessions.lua` (profession windows), `Adapters/ClassicEraTrade.lua` (merchant, auction house), `Adapters/ClassicEraBags.lua` (bags, map), `Adapters/ClassicEra.lua` | all client-specific APIs |
| Events, commands, startup | `Core/Events.lua`, `Core/Slash.lua`, `Core/Main.lua` | `CreateFrame`, `SlashCmdList` |
| Chat UI (provisional) | `UI/Shared.lua` (helpers), `UI/GoalCommands.lua` (`/bof goal`, `/bof recipe`), `UI/StockCommands.lua` (`/bof stock`) | none (prints via `Log.Print`) |
| Window | `UI/Widgets.lua` (shared buttons and item tables), `UI/MainWindow.lua` (frame, `/bof show`), `UI/MaterialTabLayout.lua` (widgets), `UI/MaterialTab.lua` (logic) | stable frame API only: `CreateFrame`, templates, `GameTooltip`, `UISpecialFrames`, `C_Timer.After` |

Core logic (later: materials, farm runs, prices, sourcing, craft evaluation, gold buffer) never calls
WoW APIs. It uses `ns.Client` (the adapter) and plain Lua data.

## Load order (TOC)

`Core/Init.lua` → `Locales/Locale.lua` → `Locales/deDE.lua` → `Core/Util.lua` → `Core/Money.lua` → `Core/Log.lua` →
`Core/DB.lua` → `Core/Materials.lua` → `Core/MaterialsValidation.lua` → `Core/Recipes.lua` → `Core/FarmRuns.lua` → `Core/FarmRunsValidation.lua` → `Adapters/Adapter.lua` → `Adapters/ClassicEraProfessions.lua` → `Adapters/ClassicEraTrade.lua` → `Adapters/ClassicEraBags.lua` → `Adapters/ClassicEra.lua` →
`Core/Events.lua` → `Core/Stock.lua` → `Core/Prices.lua` → `Core/PriceCapture.lua` → `Core/FarmCapture.lua` → `Core/FarmEstimates.lua` → `Core/Perf.lua` → `Core/Slash.lua` → `UI/Shared.lua` → `UI/GoalCommands.lua` → `UI/StockCommands.lua` → `UI/PriceCommands.lua` → `UI/FarmCommands.lua` → `UI/Widgets.lua` → `UI/MaterialTabLayout.lua` → `UI/MaterialTab.lua` → `UI/MainWindow.lua` → `UI/PerfCommand.lua` → `Core/Main.lua`

Modules that listen to signals (`Stock.lua`) load after `Events.lua`; modules that register
subcommands (`UI/*Commands.lua`) load after `Slash.lua`.

## Adapter selection

Each client has its own TOC file that lists only its adapter
(`BuyOrFarmForever_Vanilla.toc` → `Adapters/ClassicEra.lua`). The adapter calls `Adapter.Register`.
`Register` validates the adapter (missing fields raise an error) and calls `IsCurrentClient()`
(`WOW_PROJECT_ID == WOW_PROJECT_CLASSIC`). On a mismatch, `ns.Client` stays nil, a German message is
printed and `Core/Main.lua` registers nothing.

### Adapter interface (stage 2f)

| Function | Returns |
|---|---|
| `IsCurrentClient()` | bool |
| `GetBuildInfo()` | `{ version, build, date, interface }` |
| `GetLocale()` | locale code |
| `GetAddOnVersion(addonName)` | version string from the TOC, or nil |
| `GetCharacterKey()` | `{ key = "Name-NormalizedRealm", name, realm, normalizedRealm, faction }` or nil before login / for secret values |
| `GetServerTime()` | seconds since the epoch |
| `GetUptime()` | client uptime in seconds |
| `GetBagCount(itemID)` | count in the bags |
| `GetBagAndBankCount(itemID)` | count in bags + bank, or nil |
| `GetItemLink(itemID)` | item link, or nil while the item data loads (the load is requested) |
| `GetItemIcon(itemID)` | icon file id, or nil |
| `GetSpellName(spellID)` | localized spell name, or nil |
| `GetMemoryKB(addonName, refresh)` | memory in KB (`refresh` first calls `UpdateAddOnMemoryUsage`), or nil |
| `GetCPUMetrics(addonName)` | `{ recent, average, peak }`, each `{ addon, app, overall }`, or nil while the addon profiler is off |
| `GetTimeMs()` | high-resolution time in ms (`debugprofilestop`), or nil |
| `GetItemName(itemID)` | localized name, or nil while loading (load requested) |
| `ReadMerchantPrices()` | `{ { itemID, copper per unit } }` of the open merchant; items with token costs skipped |
| `ReadAuctionResults()` | `{ { itemID, count, buyout } }` of the current auction search page (rows without data skipped) |
| `CanQueryAuction()` | bool |
| `ScanBags(counts)` | fills and returns `{ [itemID] = count }` for backpack + equipped bags (table cleared first) |
| `GetCurrentMapID()` | uiMapID of the player's map, or 0 |
| `GetMapName(uiMapID)` | localized map name, or nil |
| `QueryAuction(itemName)` | bool; exact-name search, first page, all qualities; only from a click or command |
| `ReadSelectedRecipe()` | `{ key, outputItemID (0 = none), outputMin, outputMax, reagents = { { itemID, count } } }`, or nil + `"no_window"` \| `"no_selection"` \| `"loading"` |
| `events` (table) | WoW event name → client-neutral signal |

Signals so far: `BANK_OPENED`, `BANK_CLOSED`, `BAGS_CHANGED`, `ITEM_LOADED`, `MERCHANT_OPENED`,
`MERCHANT_CHANGED`, `MERCHANT_CLOSED`, `AUCTION_OPENED`, `AUCTION_CLOSED`, `AUCTION_RESULTS`, `LOOT_OPENED`,
`LOOT_CLOSED`, `LOGOUT` (only the time of a running farm run is noted). Internal
signals: `DATA_CHANGED` (raised by `Slash.Handle` after every registered command), `PRICES_CHANGED`
(raised by `PriceCapture` after storing prices and when the auction house opens or closes),
`CHARACTER_READY` (raised by `Main` after `EnsureCharacter` at login), `FARM_CHANGED` (after a bag
update was counted for a running run). Core code subscribes with
`Events.OnSignal(signal, fn)` and never names WoW events. `Events.Emit(signal, ...)` raises a signal.
`Events.OffSignal(signal, fn)` removes a handler; when a signal has no handlers left, its WoW events
are unregistered.

The interface grows with each stage (plan section 6).

## Material goals and stock (stages 2a, 2b)

Per character (`characters[charKey]`): `materialGoals[id] = { label, crafts, items = { { itemID, count } }, createdAt }`,
`activeGoalID` (0 = none), `nextGoalID` (ids are never reused).

- `Materials.Requirements(goals)` → `{ { itemID, need } }`, need = count × crafts, merged over goals in
  order of first appearance.
- `Materials.Shortfall(requirements, haveFn)` → adds `have` and `missing` (never below 0).
- Have = bags + bank of the current character + snapshots of other characters on the same realm and
  faction (`settings.countOtherCharacters`, default on). Other-faction characters are shown, not counted.
- Bank: live value = `GetBagAndBankCount - GetBagCount`. Confirmed in game (Classic Era 70003) to be
  correct with a closed bank, also after `/reload` and relog.
- Snapshots (stage 2b): `stock.bags[itemID]`, `stock.bank[itemID]`, `bagsAt`, `bankAt` of every
  character, for all items in the goals of *any* character (`Materials.CollectTrackedItems`, filled into a reused table; the snapshot
  tables are updated in place), zeros
  included so "0" and "unknown" differ. Taken on `BAGS_CHANGED`, `BANK_OPENED`, `BANK_CLOSED` and on
  `/bof stock`. Deliberately not on login (bag data may not be loaded yet) and not on `PLAYER_LOGOUT`:
  in game (Classic Era 70003) both characters stored 0 hearthstones at logout although each had one,
  so counts at logout are treated as unreliable.
  Items no longer tracked are dropped. Realm and name come from the character key
  (`Name-NormalizedRealm`; normalized realm names have no hyphens).
- `Stock.Sanitize` (in `DB.VALIDATORS`) removes invalid snapshot entries on load.
- Labels are user text: control characters and `|` removed, max. 50 characters.
- `Materials.Sanitize` (`Core/MaterialsValidation.lua`) is registered in `DB.VALIDATORS` and repairs stored goals on load.

## Farm runs (stage 2f)

- States: `FARM`, `TRAVEL`, `PAUSED`, `REVIEW`. Current run: `characters[charKey].currentRun`
  (`state, activity, targetItemID, uiMapID, items = { [itemID] = { confirmed, unclear } },
  activeSeconds, travelSeconds, startedAt, segmentStart, lastSeenAt, endedAt, resumeState`).
  Saved runs: `db.farmRuns` (list, newest last, max. `FarmRuns.MAX_RUNS` = 500, oldest dropped):
  `{ charKey, activity, targetItemID, uiMapID, items = { [itemID] = confirmed }, activeSeconds,
  travelSeconds, startedAt, endedAt }`. Unclear amounts not kept in the review are dropped.
- Times are server time. Login (`CHARACTER_READY`): a running run continues if its last sign of life
  (`lastSeenAt`: start, bag updates, commands, logout) is at most 60 s old (a `/reload`); otherwise it
  is paused at `lastSeenAt`, so offline time and crashes do not count.
- Yield (`FarmCapture`): after every bag update the carried bags are compared with the previous
  scan. Gains while a loot window is open or within 2 s after it closed (autoloot, gathering) are
  confirmed, other gains unclear, decreases ignored. The first scan after a login only sets the
  baseline. No chat messages are parsed (language-independent); the loot slot API was not used
  because the Classic UI source contradicts itself on `GetLootSlotInfo`'s 4th return and does not use
  `GetLootSlotLink`. The bank is not part of the comparison.
- Location: uiMapID at the start, replaced by the map when arriving (travel → farm). Names come
  from `C_Map.GetMapInfo` at display time.
- Estimates (`FarmEstimates`): runs of the character (`settings.farmEstimateScope = "CHARACTER"`)
  or of all characters (`"ACCOUNT"`) count for an item if it was the target or yielded it. Point
  estimate = amount × total farm time / total yield; range = slowest and fastest run with yield
  (at least two); travel = average per run. Target runs without yield lower the rate.

## Prices (stage 2e)

- `db.prices["<NormalizedRealm>-<Alliance|Horde>"][itemID] = { MANUAL = { copper, at }, MERCHANT = ..., AUCTION = ... }`,
  unit prices in copper (auction and merchant prices can be fractional), `at` = server time.
  `Prices.Sanitize` (in `DB.ROOT_VALIDATORS`) removes invalid entries on load.
- Planning price (`Prices.Best`): the cheapest price that is not outdated; if all are outdated, the
  newest one, flagged. Outdated = older than `settings.priceMaxAgeDays` (default 7). Merchant prices
  never become outdated (fixed prices).
- Automatic capture only for tracked items (goals of any character). Merchant: unit price =
  price / stack size, items with `extendedCost` (tokens) skipped. Auction: lowest buyout per unit of
  one result page; pages within `Prices.AUCTION_MERGE_SECONDS` (600 s) are merged by minimum, a
  later search replaces the price. Auctions without buyout are ignored.
- Auction scan (`PriceCapture.ScanNext`, button and `/bof price scan`): one exact-name search per
  click for the next missing material not yet searched during this auction house visit. One search
  per click avoids automated query loops; whether `QueryAuctionItems` needs a hardware event in
  Classic Era is not documented, so it is only called from a click or command. Only the first page
  is read; the scan does not page through results.
- Money input (`Money.Parse`): units required (`g`, `s`, `k`/`c`, from the locale); a plain number
  is rejected because it is ambiguous.

## Recipes (stage 2c)

`/bof recipe [crafts]` reads the recipe selected in the open profession window through
`Client:ReadSelectedRecipe()`, validates it (`Recipes.Normalize`: key, ids, counts, at most
`Recipes.MAX_REAGENTS`, duplicates merged), stores it in `db.recipes[key]` (account-wide; an import
replaces an older one) and creates a goal with `Materials.CreateRecipeGoal`.

- Key: `spell:<id>` when the client gives a spell/enchant link, else `item:<outputItemID>`.
- `db.recipes[key] = { outputItemID, outputMin, outputMax, reagents, origin = "IMPORT", at }`. No names
  (localized). `Recipes.Sanitize` is registered in `DB.ROOT_VALIDATORS` (account-wide checks).
- A recipe goal has `label = ""` and `recipeKey`; its display name is the output item link, else the
  spell name (`GetSpellName`), else a placeholder. The goal copies the reagents, so later edits of the
  goal do not change the stored recipe.
- Classic Era adapter: two windows, trade skill (`GetTradeSkill*`) and craft (`GetCraft*`,
  Enchanting and Beast Training). Both can be open; the window in which a recipe was selected last is
  used (user request, 0.2.0-alpha.7), otherwise the one opened last. Headers
  and recipes without reagents are refused; missing reagent links mean "loading" (item data not
  cached yet). `GetCraftItemLink` is expected to return an item link for crafts that create items
  and an enchant link otherwise (plan Q-T4, to be confirmed in game).
- Only fixed reagents exist in Classic Era. Optional/quality reagents are a Forever topic.

## Events and timers

| Event | Handler | Registered | Frequency | Cost / effect |
|---|---|---|---|---|
| `ADDON_LOADED` | `Main.onAddonLoaded` | file load, unregistered after the own addon loaded | once per load | loads the database |
| `PLAYER_LOGIN` | `Main.onPlayerLogin` | file load, unregistered after the first call | once | character key, `EnsureCharacter` |
| `BAG_UPDATE_DELAYED` → `BAGS_CHANGED` | `Stock` | always | once per bag-change burst (the client coalesces `BAG_UPDATE`) | snapshot of the tracked items only (`GetItemCount` per item) |
| `BANKFRAME_OPENED` / `_CLOSED` → `BANK_OPENED` / `BANK_CLOSED` | `Stock` | always | per bank visit | snapshot of the tracked items |
| `TRADE_SKILL_SHOW` / `_CLOSE`, `CRAFT_SHOW` / `_CLOSE` | Classic Era adapter (own frame) | always | per profession window open/close | sets two flags, no API calls |
| `ITEM_DATA_LOAD_RESULT` → `ITEM_LOADED` | Material tab | only while the window is shown | per item whose data arrives | requests one refresh |
| `MERCHANT_SHOW` / `MERCHANT_CLOSED` | `PriceCapture` | always | per merchant visit | reads the merchant list once, stores tracked items |
| `MERCHANT_UPDATE` → `MERCHANT_CHANGED` | `PriceCapture` | only while a merchant is open | when merchant data changes | same as above |
| `AUCTION_HOUSE_SHOW` / `AUCTION_HOUSE_CLOSED` | `PriceCapture` | always | per auction house visit | flags, scan list reset |
| `BAGS_CHANGED`, `LOOT_OPENED`, `LOOT_CLOSED`, `LOGOUT` (signals) | `FarmCapture` | only while a farm run is running (start/resume/login-continue on; pause/stop/discard off) | per bag update / loot window | bag scan of the carried bags (about 100 slots), diff with reused count tables |
| `AUCTION_ITEM_LIST_UPDATE` → `AUCTION_RESULTS` | `PriceCapture` | only while the auction house is open | per result page and when row data arrives | reads one page (max. 50 rows), stores the lowest unit buyout of tracked items |
| `BAGS_CHANGED`, `BANK_OPENED`, `BANK_CLOSED`, `DATA_CHANGED` (signals) | Material tab | handler added on show, removed on hide (the WoW events stay registered for `Stock`) | see above | requests one refresh |

Window refreshes are coalesced: any number of refresh requests in one frame lead to one
`C_Timer.After(0, ...)` callback, which redraws only if the window is still visible. The window is
created on first open and hidden, never destroyed; rows are a fixed pool of 10 frames.

No `OnUpdate` scripts and no tickers; one-shot `C_Timer.After(0)` only for coalescing.

Hooks: `hooksecurefunc("SelectTradeSkill")` and `hooksecurefunc("SelectCraft")` in
`Adapters/ClassicEraProfessions.lua`, installed once at load. Secure post-hooks (no taint, Blizzard
code unchanged); they run only when a recipe is selected and set one variable. The adapter's window frame is not routed through
`Core/Events.lua` because the core does not need to know which kind of window is open; its handler
only sets flags.

## Main window (stage 2d)

- `UI/MainWindow.lua` creates the frame on the first `/bof show` (`BackdropTemplate` with
  `BACKDROP_DIALOG_32_32`, `UIPanelCloseButton`; both defined in Blizzard_SharedXML for Vanilla 70003).
- Global frame name `BuyOrFarmForeverMainFrame`: required because `UISpecialFrames` (Escape closes
  the window) holds frame names. It is the only global besides the namespace, SavedVariables and
  slash globals, and it exists only after the window was opened once.
- Position: `settings.window.point/x/y`, saved on drag stop, restored on creation (unknown points
  fall back to `CENTER`). `settings.window.allGoals` (default false) stores the "all goals" view.
- The Material tab reads `Stock.Rows` (shared with `/bof stock`) and uses `UIShared.ItemText` /
  `UIShared.GoalName` for names. Buttons: previous/next goal (wraps), "all goals", recipe import
  (`Recipes.ImportSelected`, 1 craft). Mouse wheel scrolls 1 row. Tooltip: item hyperlink plus one
  line per other character.
- Not protected, no secure templates; changing it in combat is allowed.

## Startup

1. File load: modules created, adapter registered, slash commands registered, events registered.
2. `ADDON_LOADED` (own name): `DB.Load` → `BuyOrFarmForeverDB`, `ns.db`, `ns.readOnly`. Pending log
   entries are flushed into the database.
3. `PLAYER_LOGIN`: character key, `DB.EnsureCharacter`, build info logged (debug mode).

## SavedVariables (schema 1)

One account-wide variable `BuyOrFarmForeverDB`. Defaults: `Core/DB.lua` (`DB.DEFAULTS`,
`DB.CHARACTER_DEFAULTS`). Fields not used yet (savings goals, income) already exist with
empty defaults so later stages need no migration.

`DB.Load` statuses:

| Status | Meaning | Effect |
|---|---|---|
| `new` | nothing stored | defaults created |
| `ok` | current schema | defaults merged, invalid values replaced |
| `migrated` | older schema | migrations run on a copy, then merged |
| `newer` | newer schema than this version knows | stored data returned untouched, `ns.readOnly = true` |
| `migration_failed` | a migration step failed | stored data untouched, `ns.readOnly = true`, error reported |

Validation: missing fields get defaults; values of the wrong type, enum fields with unknown values
(`DB.ENUMS`) and numbers below `DB.MIN` are replaced and their paths reported. Unknown fields are kept.
Character entries that are not tables are removed. Debug log entries without a string `msg` are removed.

Migrations: `DB.MIGRATIONS[n](db)` upgrades schema n to n + 1. They run on a deep copy; the stored
table is only replaced when all steps succeed.

## Performance measurement (`/bof perf`)

- Memory: `GetAddOnMemoryUsage` after `UpdateAddOnMemoryUsage`, which walks all addons; refreshed
  at most every 15 s (`Perf.MEMORY_UPDATE_SECONDS`, same as Blizzard's addon list).
- CPU: `C_AddOnProfiler` (documented in Classic Era 70003). Share of frame time =
  `addon / (app - overall + addon)`, the formula of Blizzard_AddOnList, for the recent average,
  the session average and the peak. Without the profiler the command says so.
- Timing: one `Stock.Rows` run over all goals, measured with `debugprofilestop`.

## Efficiency notes

- Event dispatch (`Core/Events.lua`) creates no tables or closures per event: handler arguments go
  into a reused context per nesting depth, and `xpcall` gets a static function and error handler.
- Debug-only strings (trace messages) are built only when debug mode is on.
- Stock snapshots on `BAG_UPDATE_DELAYED` reuse one scratch set for the tracked items and update
  the stored snapshot tables in place, so a bag change allocates nothing in steady state.
- Window refreshes allocate row data, but only while the window is visible and at most once per
  frame (coalesced).

## Errors

`Core/Events.lua` calls each handler in `xpcall`. Errors go to `Log.ReportError`: stored in the debug
log and passed to `geterrorhandler()` (BugGrabber/BugSack or the default error frame). Other handlers
for the same event still run. No error is swallowed.

## Debug log

Ring buffer `db.debugLog`, max 200 entries `{ at, level, msg }`. `ERROR`/`WARN` always,
`INFO`/`TRACE`/`DEBUG` only in debug mode. `DEBUG` is also printed. Every dispatched event is traced
(`TRACE`) in debug mode. In read-only mode nothing is written into the stored data.
