# Architecture

Full plan: `work/notes/BuyOrFarmForever-plan.md` in the development folder (not part of the repo).

## Layers

| Layer | Files | WoW API calls |
|---|---|---|
| Namespace | `Core/Init.lua` | none |
| Localization | `Locales/Locale.lua`, `Locales/deDE.lua` | none |
| Core helpers | `Core/Util.lua`, `Core/Log.lua`, `Core/DB.lua`, `Core/Settings.lua` (settings schema) | `Log.lua`: `DEFAULT_CHAT_FRAME`, `geterrorhandler` only |
| Core logic | `Core/Money.lua` (parse/format copper), `Core/Prices.lua` (prices per source), `Core/PriceCapture.lua` (merchant/auction capture, scan), `Core/FarmRuns.lua` + `Core/FarmRunsValidation.lua` (run state machine), `Core/FarmCapture.lua` (yield from bag changes), `Core/FarmEstimates.lua`, `Core/Sourcing.lua` (buy/farm plan), `Core/CraftEval.lua` (craft evaluation), `Core/SavingsGoals.lua`, `Core/Income.lua` + `Core/IncomeCapture.lua` (gold buffer), `Core/MoneyContext.lua` (source of a gold change), `Core/Session.lua` (play session), `Core/WeightTemplates.lua` (stat weight templates), `Core/Materials.lua` (goals, requirements, shortfall), `Core/MaterialsValidation.lua` (stored goals), `Core/Recipes.lua` (imported recipes), `Core/Stock.lua` (bag/bank counts via adapter, snapshots) | none |
| Adapter interface | `Adapters/Adapter.lua` | `DEFAULT_CHAT_FRAME` (mismatch message) |
| Client adapter | `Adapters/ClassicEraProfessions.lua` (profession windows), `Adapters/ClassicEraTrade.lua` (merchant, auction house), `Adapters/ClassicEraBags.lua` (bags, map), `Adapters/ClassicEraGear.lua` (item stats, equipment), `Adapters/ClassicEraUI.lua` (cursor item, tooltip and link hooks, merchant frame, minimap), `Adapters/ClassicEraPlayer.lua` (AFK, resting, taxi, class, talent points), `Adapters/ClassicEraQuest.lua` (quest frame rewards), `Adapters/ClassicEra.lua` | all client-specific APIs |
| Events, commands, startup | `Core/Events.lua`, `Core/Slash.lua`, `Core/Main.lua` | `CreateFrame`, `SlashCmdList` |
| Chat commands (fallback for every window action) | `UI/Shared.lua` (helpers), `UI/*Commands.lua` (`/bof goal`, `recipe`, `stock`, `price`, `farm`, `plan`, `craft`, `weights`, `alt`, `gold`, `set`), `UI/FarmReports.lua` (estimate texts) | none (prints via `Log.Print`) |
| Window | `UI/Widgets.lua` (buttons, check boxes, item tables, tab frames, refresh mixin), `UI/Inputs.lua` (edit boxes, item slot, confirmation dialog, `Inputs.Run`), `UI/MainWindow.lua` (frame, title line, eight tabs, `/bof show`), `UI/MaterialTabLayout.lua` + `UI/MaterialTab.lua` + `UI/MaterialTabActions.lua`, `UI/SourcingTabLayout.lua` + `UI/SourcingTab.lua`, `UI/FarmTab.lua`, `UI/CraftAltPanel.lua` + `UI/CraftTab.lua`, `UI/GoldTab.lua`, `UI/SettingsTab.lua`, `UI/HelpTab.lua` | stable frame API only: `CreateFrame`, templates, `GameTooltip`, `UISpecialFrames`, `C_Timer.After` |
| Assistance (no player input) | `UI/FarmAssist.lua` (target reached, auto pause/travel), `UI/FarmSuggest.lua` (start suggestion), `UI/PromptBar.lua` (offer bar), `UI/TooltipLines.lua`, `UI/ShopHints.lua` (merchant/auction hints, reserve warning), `UI/QuestAlternatives.lua`, `UI/MinimapButton.lua` (+ key binding names), `UI/LoginSummary.lua`, `UI/GoldAuto.lua` | through the adapter; frames via the frame API |

Core logic (later: materials, farm runs, prices, sourcing, craft evaluation, gold buffer) never calls
WoW APIs. It uses `ns.Client` (the adapter) and plain Lua data.

## Load order (TOC)

`Core/Init.lua` → `Locales/Locale.lua` → `Locales/deDE.lua` → `Core/Util.lua` → `Core/Money.lua` → `Core/Log.lua` → `Core/DB.lua` → `Core/Settings.lua` → `Core/Materials.lua` → `Core/MaterialsValidation.lua` → `Core/Recipes.lua` → `Core/FarmRuns.lua` → `Core/FarmRunsValidation.lua` → `Adapters/Adapter.lua` → `Adapters/ClassicEraProfessions.lua` → `Adapters/ClassicEraTrade.lua` → `Adapters/ClassicEraBags.lua` → `Adapters/ClassicEraGear.lua` → `Adapters/ClassicEraUI.lua` → `Adapters/ClassicEraPlayer.lua` → `Adapters/ClassicEraQuest.lua` → `Adapters/ClassicEra.lua` → `Core/Events.lua` → `Core/Stock.lua` → `Core/Prices.lua` → `Core/PriceCapture.lua` → `Core/FarmCapture.lua` → `Core/FarmEstimates.lua` → `Core/Sourcing.lua` → `Core/CraftEval.lua` → `Core/WeightTemplates.lua` → `Core/SavingsGoals.lua` → `Core/Income.lua` → `Core/MoneyContext.lua` → `Core/Session.lua` → `Core/IncomeCapture.lua` → `Core/Perf.lua` → `Core/Slash.lua` → `UI/Shared.lua` → `UI/GoalCommands.lua` → `UI/StockCommands.lua` → `UI/PriceCommands.lua` → `UI/FarmReports.lua` → `UI/FarmCommands.lua` → `UI/FarmAssist.lua` → `UI/PlanCommands.lua` → `UI/CraftCommands.lua` → `UI/AltCommands.lua` → `UI/GoldCommands.lua` → `UI/SettingsCommands.lua` → `UI/Widgets.lua` → `UI/Inputs.lua` → `UI/MaterialTabLayout.lua` → `UI/MaterialTab.lua` → `UI/MaterialTabActions.lua` → `UI/SourcingTabLayout.lua` → `UI/SourcingTab.lua` → `UI/FarmTab.lua` → `UI/CraftAltPanel.lua` → `UI/CraftTab.lua` → `UI/GoldTab.lua` → `UI/SettingsTab.lua` → `UI/HelpTab.lua` → `UI/MainWindow.lua` → `UI/PromptBar.lua` → `UI/FarmSuggest.lua` → `UI/TooltipLines.lua` → `UI/ShopHints.lua` → `UI/QuestAlternatives.lua` → `UI/MinimapButton.lua` → `UI/LoginSummary.lua` → `UI/GoldAuto.lua` → `UI/PerfCommand.lua` → `Core/Main.lua`

Modules that listen to signals (`Stock.lua`) load after `Events.lua`; modules that register
subcommands (`UI/*Commands.lua`) load after `Slash.lua`.

## Adapter selection

Each client has its own TOC file that lists only its adapter
(`BuyOrFarmForever_Vanilla.toc` → `Adapters/ClassicEra.lua`). The adapter calls `Adapter.Register`.
`Register` validates the adapter (missing fields raise an error) and calls `IsCurrentClient()`
(`WOW_PROJECT_ID == WOW_PROJECT_CLASSIC`). On a mismatch, `ns.Client` stays nil, a German message is
printed and `Core/Main.lua` registers nothing.

### Adapter interface (stage 3)

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
| `GetMoney()` | copper the character carries, or nil |
| `GetItemStats(itemID)` | `{ STR, AGI, STA, INT, SPI, ARMOR, DPS }` (0 if missing), or nil while loading; DPS from `ITEM_MOD_DAMAGE_PER_SECOND_SHORT` (confirmed in game, Classic Era, 2026-10-19) |
| `GetItemMinLevel(itemID)` | required character level (`itemMinLevel`, 5th return of `C_Item.GetItemInfo`), or nil while loading |
| `GetLevel()` | character level (`UnitLevel("player")`), or nil |
| `GetEquipSlots(itemID)` | slot keys, e.g. `{ "CHEST" }`, `{ "FINGER1", "FINGER2" }`, with `.sum = true` for two-handers; nil if not equippable |
| `GetEquippedItemID(slotKey)` | item id in that slot, or nil (the adapter maps keys to Classic inventory slot numbers) |
| `GetSellPrice(itemID)` | vendor sell price per unit, or nil while loading |
| `QueryAuction(itemName)` | bool; exact-name search, first page, all qualities; only from a click or command |
| `ReadSelectedRecipe()` | `{ key, outputItemID (0 = none), outputMin, outputMax, reagents = { { itemID, count } } }`, or nil + `"no_window"` \| `"no_selection"` \| `"loading"` |
| `GetCursorItem()` / `ClearCursor()` | item id on the cursor or nil / drop it (drag and drop into item slots) |
| `IsAFK()`, `IsResting()`, `IsOnTaxi()` | bool (legacy returns 1/nil are normalized) |
| `GetClass()` | class file name, e.g. `"PRIEST"`, or nil |
| `GetTalentPoints()` | `{ points tree 1, 2, 3 }` from `C_SpecializationInfo.GetSpecializationInfo` (7th return), or nil |
| `HookItemTooltips(callback)` | post-hook `OnTooltipSetItem` of `GameTooltip` and `ItemRefTooltip`; `callback(tooltip, itemID)`; call once |
| `HookLinkInsert(callback)` | post-hook `ChatFrameUtil.InsertLink`; `callback(itemID)` for shift-clicks while no chat input is open; call once |
| `GetMerchantFrame()`, `GetMinimap()` | Blizzard frames to anchor the merchant hint and the minimap button, or nil |
| `GetQuestRewards()` | `{ title, items = { itemID } }` of the open quest frame (choices first), or nil |
| `HasExternalPrices()` | bool: a supported price addon (Auctionator API v1) is loaded |
| `GetExternalPrice(itemID)` | copper, ageDays (nil if unknown) of the price addon; nil if none; nil, nil, error if the price addon raised an error (caught with `pcall`) |
| `events` (table) | WoW event name → client-neutral signal |

Parts without adapter state (`ClassicEraUI`, `ClassicEraPlayer`, `ClassicEraQuest`, `ClassicEraExternal`) are exposed as
methods by a loop in `Adapters/ClassicEra.lua`.

Signals so far: `BANK_OPENED`, `BANK_CLOSED`, `BAGS_CHANGED`, `ITEM_LOADED`, `MERCHANT_OPENED`,
`MERCHANT_CHANGED`, `MERCHANT_CLOSED`, `AUCTION_OPENED`, `AUCTION_CLOSED`, `AUCTION_RESULTS`, `LOOT_OPENED`,
`LOOT_CLOSED`, `LOGOUT` (only the time of a running farm run is noted), `MONEY_CHANGED`,
`EQUIPMENT_CHANGED`, `MAIL_OPENED`, `MAIL_CLOSED`, `TRADE_OPENED`, `TRADE_CLOSED`, `COMBAT_STARTED`,
`PLAYER_FLAGS_CHANGED`, `RESTING_CHANGED`, `CONTROL_LOST`, `CONTROL_GAINED`, `QUEST_OFFERED`, `QUEST_REWARDS`,
`QUEST_CLOSED`, `TRAINER_OPENED`, `TRAINER_CLOSED`. Internal
signals: `DATA_CHANGED` (raised by `Slash.Handle` after every registered command), `PRICES_CHANGED`
(raised by `PriceCapture` after storing prices and when the auction house opens or closes),
`CHARACTER_READY` (raised by `Main` after `EnsureCharacter` at login), `FARM_CHANGED` (after a bag
update was counted for a running run), `SETTINGS_CHANGED` (after `/bof set` or a reset). Core code subscribes with
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

## Gold buffer (stage 4)

- Savings goals: `characters[k].savingsGoals = { { label, copper, reserved, done, createdAt } }`,
  list order = priority, max. 30. `Distribute(money)` assigns the current gold once in order;
  reserves stay until the next distribution. `Overview(money)`: reserved (capped at the current
  gold), free = gold − reserved, uncovered = open targets − reserved. `ReserveUse(cost)` =
  max(0, cost − free).
- Income: `characters[k].income[day] = { gained, spent, seconds }` (day = server time / 86400, max.
  60 days). Every `PLAYER_MONEY` delta counts (no source distinction). Online time is added between
  checkpoints (login, gold change, bag change, logout), each gap capped at 30 min. Net per hour over
  14 days, shown from 1 h online. Assumption to confirm in game: `GetMoney()` is valid at
  `PLAYER_LOGIN`; guard: a gain within 30 s after a login that read 0 gold is not counted.
- Sourcing: `settings.useReservesInSourcing = false` limits the budget to the free gold. The plan
  shows the reserve use of its cost and the time value (cost / net per hour).

## Farm tab

The buttons call `Slash.Handle("farm …")`, so the window and the chat share one code path (and the
chat confirms every action). Status, item and estimate lines come from `FarmCommands.StatusLine`,
`ItemLines`, `EstimateLines`. The status line is rewritten by the 1 s ticker (see Events and timers).

## Craft evaluation (stage 3)

0.5.0: rated stats include `ARMOR` (per point) and `DPS` (weapon damage per second); their default
weights are 0 so older evaluations do not change; templates set them. A planned alternative gets a
verdict (`CraftCommands.VerdictLine`): the craft stays better, or it bridges the time until the
alternative (with its time effort if known). `CraftEval.LevelLock` marks items above the character
level.

- Stats: `GetItemStats(link)` (global function, confirmed in game in Classic Era 70003; no
  `C_Item.GetItemStats`). The adapter maps Blizzard keys (`ITEM_MOD_STRENGTH_SHORT`, …,
  `RESISTANCE0_NAME`) to `STR, AGI, STA, INT, SPI, ARMOR`; the core never sees Blizzard keys.
- Score = Σ stat × weight over STR, AGI, STA, INT, SPI (`characters[k].craftEval.weights`, 0–10,
  default 1). Armor is read but not rated (feature description: not evaluated yet).
- Slots (adapter, from `C_Item.GetItemInfoInstant` equip location): rings and trinkets replace the
  weaker equipped one, two-handed weapons replace main and off hand together (`.sum`), one-handed
  weapons are compared with the main hand only, empty slots count 0.
- Evaluation of a goal (`CraftCommands.EvaluationLines`, used by `/bof craft` and the Craft tab):
  craft item = output of the goal's recipe; comparison; sourcing plan of this goal (current
  strategy and budget) and cost/farm time per score point; value of owned materials (bags + bank
  of the character, capped at the need) at vendor price (`GetSellPrice`) and planning price;
  alternatives (`craftEval.alternatives = { { itemID, kind = PLANNED|POSSIBLE, note, at, copper?,
  seconds?, requires? } }`, max. 20, note and requires = cleaned user text; the optional cost,
  time effort and requirements are user input, absent = unknown) compared with the craft; the
  details are shown next to the craft's sourcing cost and farm time. Optional fields need no schema
  change (old data has none).
- `CraftEval.Sanitize` (in `DB.VALIDATORS`) resets invalid weights to 1, drops invalid alternatives and
  invalid optional details (negative or too large cost/time, wrong types).

## Sourcing plan (stage 2g)

- `Sourcing.Inputs(charData, goals)`: per missing material `{ itemID, missing, unitPrice (Prices.Best),
  priceOutdated, secondsPerUnit (farm seconds / yield of the estimate basis), travelSeconds }`.
- `Sourcing.Plan(inputs, strategy, budget)` (pure): per line `buy, farm, cost, farmSeconds, open`, plus
  totals and `budgetLeft`. Buying order: unfarmable items first, then highest farm seconds saved
  per copper (fractional-knapsack greedy; the last item may be bought partly). Farming a part adds
  the average travel once per item. `SAVE_TIME` may buy everything, `SAVE_GOLD` only items without
  an estimate, `FARM_SELF` nothing. What is neither bought nor farmable is `open`.
- Budget (`Sourcing.Budget`): `settings.budgetCopper` if > 0, else `GetMoney()`; with
  `settings.useReservesInSourcing = false` limited to the gold not reserved for savings goals.
- Time value of purchases: from the net income per hour (`Income`, gold buffer) once there is at
  least an hour of data (`PlanCommands.CostNotes`).
- Window tabs: `UI/MainWindow.lua` keeps one object per tab (`frame.material`, `frame.sourcing`,
  `frame.farm`, `frame.craft`) with
  `frame`, `Activate`, `Deactivate`, `Refresh`. Only the shown tab is activated; the selection is
  stored in `settings.window.tab` (`SOURCING` added to the enum; no migration needed).

### Build-out 0.5.0 (Core/SourcingPlan.lua, Core/GoldRoutes.lua)

- `Sourcing.Inputs` adds `byproducts = { [itemID] = units per farm second }` per farmable input:
  the other missing materials yielded by the same runs that `FarmEstimates.ForItem` counts
  (`FarmEstimates.Byproducts`). `Sourcing.Plan` settles lines from the longest farm time down; each
  farmed line credits its by-products to lines not settled yet (no cycles). A credited part is
  `line.byproduct` and costs no farm time.
- Time limit: `settings.farmTimeLimitMinutes` (0 = none, max 1440; not in the settings schema, set
  with `/bof timelimit` or the Sourcing tab box, like `budgetCopper`). After the strategy's
  purchases, `enforceLimit` buys farmed units in order of time saved per copper until the farm time
  fits or the budget is used; greedy, re-settles after each purchase. `plan.overLimitSeconds` > 0
  when the budget was not enough.
- Gold routes: runs grouped by `targetItemID` (runs without a target and targets that are missing
  materials skipped), value = sum of items x `GoldRoutes.SaleValue` (lowest current AUCTION /
  MANUAL / AUCTIONATOR price minus `AUCTION_CUT` 5 %, or the vendor sell price if higher), time =
  farm + travel. Routes need `MIN_SECONDS` (600). The best route's time to earn the cost of all
  priced missing materials is shown under the plan (`PlanCommands.RouteText`).

### Gold planner (0.6.0)

- Routes (`Core/GoldRoutes.lua`): a route is zone (`uiMapID` at the start) + activity + target
  (`GoldRoutes.Key`); runs without a target form their own route. Value = loot at
  `GoldRoutes.SaleParts` (vendor price = sure; auction after the 5 % cut on top = auction part) +
  looted coins (`run.lootCopper`, recorded since 0.6.0; older runs have `nil` and are counted in
  `runsWithoutCoins`). Rates per hour of farm time; travel = average per run, paid once per trip.
  At least `MIN_SECONDS` (600) of farm time per route. Rating = sure + auction x (1 -
  `settings.ahDiscountPercent` / 100), default 25 %.
- Tasks: `Core/BagTasks.lua` (per stack the best of vendor / auction / disenchant; goal materials,
  items without value and `characters[key].goldKeep` skipped; bound items not on the auction house),
  `Core/CraftTasks.lua` (learned recipes = recipe book: product value (vendor sure, auction surplus
  after the cut) minus the reagents; reagents in the bags at their raw value (`GoldRoutes.SaleParts`,
  buy price if they have no sale value), the rest at `PriceCapture.Best`, or farmed (no gold, farm
  time from `FarmEstimates` plus one run's travel added to the task time; 0.7.0-alpha.6) when there is
  no buy price but measured runs; as many crafts as the bags
  allow, else 5; cooldown recipes 1 craft when ready, waiting ones listed by `CraftTasks.Waiting`;
  best 5 tasks). Since 0.7.0-alpha.5; before, all reagents counted at the buy price.
- Plan (`Core/GoldPlan.lua`, pure): tasks by rating per second, each taken if it beats the best
  method in the same time; the rest goes to the method with the highest rating x (rest - travel).
- Recipe book (`Core/RecipeBook.lua`): `characters[key].recipeBook[recipeKey] = { cooldown?,
  readyAt? }`, recipe data in `db.recipes`; at most 500 recipes per character; enchantments without
  an item are skipped. A cooldown is known once the window showed a remaining cooldown.
- Time constants (design assumptions): vendor 2 s per stack, auction 20 s per stack, disenchant
  10 s per item, craft 5 s + post 20 s per craft, buying 20 s per reagent.
- UI: `UI/GoldPlanCommands.lua` (`/bof goldplan`, `/bof goldsources`, `/bof goldkeep`),
  `UI/GoldPlanPanel.lua` (planner view of the Gold buffer tab).

### Advisor (0.7.0)

- `Core/AdvisorSources.lua`: sources per context return suggestions `{ kind, priority, itemID?,
  count?, sure, auction, cost?, action?, ... }`. Context "ANY" (always): bag tasks, full bags
  (<= 3 free slots), craftable recipe goals, ready cooldowns, materials other characters hold
  (`MAIL_ASK`), best hour (`GoldPlan`), next savings goal. "MERCHANT": missing goal materials the
  merchant sells. "BANK": goal materials in the bank. "AUCTION": sourcing plan purchases, missing or
  outdated prices. "MAIL": materials other characters (same realm and faction) miss for their goals.
  A kind gets +40 priority in the window where it can be done.
- `Core/Advisor.lua`: `Advisor.Context()` from window signals (last opened window wins),
  `ADVISOR_CONTEXT` signal on change, `Advisor.Collect` sorts by priority, then rating.
- `Core/AdvisorSummary.lua` (0.7.0-alpha.4, user decision 2026-10-19): the window's fixed rows in
  this order: `SUM_SELL` (vendor and auction tasks, full bags), `DISENCHANT` (only if the character
  knows Disenchant; per item `gains` = rated copper more than the second best way, from
  `BagTasks`), `SUM_CRAFT` (ready goals and cooldowns, then profitable recipe-book crafts with the
  reagents in the bags (`CraftTasks` `fromBags`), then those to buy), `SAVINGS`, `PLAN_HOUR`. A row
  with nothing to do carries `empty` (reason key) and is drawn grey.
- UI: `AdvisorText` (texts per kind), `AdvisorCard` (card widget, `BACKDROP_TOAST_12_12`),
  `AdvisorWindow` (movable window 300 px, one clickable card per summary row without buttons,
  height follows the rows, scale 0.85, its two settings at the bottom; opens 7 s after login
  if a suggestion has priority >= 80 and `advisorAtLogin`), `AdvisorSide` (cards next to
  `MerchantFrame`, `AuctionFrame`, `BankFrame`, `MailFrame`; one retry a frame later because the
  auction UI loads on demand), `AdvisorActions` (click actions).
- Actions (user decision 2026-10-19: buy and sell on click; this changes the original description
  "you do purchases and sales yourself" for the merchant only): sell the vendor task's stacks
  (`C_Container.UseContainerItem`, batches of 6 every 0.3 s, stops when the merchant closes; each
  slot is re-checked for the expected item) and buy missing materials (`BuyMerchantItem` in whole
  merchant stacks, at most `GetMerchantItemMaxStack` per call). Both ask first
  (`Inputs.Confirm`). Auction house and mail stay manual.

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
- External prices (0.5.0): Auctionator through its public API v1 (`GetAuctionPriceByItemID`,
  `GetAuctionAgeByItemID`, callerID `"BuyOrFarmForever"`), optional (`## OptionalDeps`), switch
  `settings.useAuctionator` (default on). `PriceCapture.External(itemID, now)` turns it into a live
  record `{ AUCTIONATOR = { copper, at = now - ageDays } }`; without an age (Auctionator: older than
  21 days) it counts as 22 days old, so it is outdated with the default limit. `Prices.Best` takes the
  record as an extra source. External prices are read on demand and never stored in SavedVariables.
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
| `PLAYER_EQUIPMENT_CHANGED` → `EQUIPMENT_CHANGED` | Craft tab | only while the Craft tab is shown | per equipment change | requests one refresh |
| `PLAYER_MONEY` → `MONEY_CHANGED` | `IncomeCapture` (always), Sourcing and Gold tab (while shown) | always | per gold change | one income record update (no allocation once the day exists); tabs request a refresh |
| `BAGS_CHANGED`, `LOGOUT` (signals) | `IncomeCapture` | always | per bag-change burst / logout | online-time checkpoint (two number updates) |
| `AUCTION_ITEM_LIST_UPDATE` → `AUCTION_RESULTS` | `PriceCapture` | only while the auction house is open | per result page and when row data arrives | reads one page (max. 50 rows), stores the lowest unit buyout of tracked items |
| `BAGS_CHANGED`, `BANK_OPENED`, `BANK_CLOSED`, `DATA_CHANGED` (signals) | Material tab | handler added on show, removed on hide (the WoW events stay registered for `Stock`) | see above | requests one refresh |
| `MERCHANT_*`, `BANK_*`, `AUCTION_*`, `MAIL_*`, `TRADE_*`, `COMBAT_STARTED` (signals) | `FarmCapture` | only while a farm run is running | per window / combat start | flag updates; combat start notes activity (idle time) |
| `PLAYER_FLAGS_CHANGED`, `PLAYER_UPDATE_RESTING`, `PLAYER_CONTROL_LOST/GAINED` | `FarmAssist` | only while a farm run exists (not in review); synced on `DATA_CHANGED` | per AFK/resting/flight change | at most one `/bof farm` command; control loss starts one `C_Timer.After(1)` taxi check |
| `FARM_CHANGED` (internal) | `FarmAssist` | always (raised only during runs) | per counted bag update | target check (`Stock.Rows` over all goals) only until the target was reported |
| `LOOT_OPENED`, `LOOT_CLOSED`, `BAGS_CHANGED` (signals) | `FarmSuggest` | only while `farmSuggestStart` is on | per loot window / bag burst | counts of the selected goal's missing items at loot open, compared after the loot |
| `LOOT_*`, `QUEST_REWARDS/CLOSED`, `MERCHANT_*`, `TRAINER_*`, `MAIL_*`, `AUCTION_*`, `TRADE_*` (signals) | `MoneyContext` | always | per window | one flag each (source of the next gold change) |
| `DATA_CHANGED`, `BAGS_CHANGED`, `BANK_CLOSED`, `EQUIPMENT_CHANGED`, `SETTINGS_CHANGED` (signals) | `TooltipLines` | always | per change | sets a dirty flag; the tooltip cache is rebuilt on the next item tooltip |
| `PLAYER_MONEY` → `MONEY_CHANGED` | `ShopHints` (while a merchant is open), `GoldAuto` (always; acts only with `goldAutoDistribute`) | see column | per gold change | hint text and reserve check; `GoldAuto` distributes only after a gain |
| `QUEST_DETAIL`, `QUEST_COMPLETE` | `QuestAlternatives` | always | per quest frame | reads the rewards, one slot check per reward item |
| `TRADE_SKILL_SHOW`, `CRAFT_SHOW` → `PROFESSION_OPENED`; `TRADE_SKILL_UPDATE`, `CRAFT_UPDATE` → `PROFESSION_CHANGED` | `RecipeBook` | always | per window open; updates in bursts (casts, filters) | one `C_Timer.After(1)` per burst, then one read of all visible recipes (`ReadAllRecipes`) |
| `MERCHANT_*`, `AUCTION_*`, `BANK*`, `MAIL_*`, `PROFESSION_OPENED/CLOSED` (signals) | `Advisor` | always | per window | updates the open-window list; raises `ADVISOR_CONTEXT` on change |
| `ADVISOR_CONTEXT`, `SETTINGS_CHANGED` (signals) | `AdvisorSide` | always | per window | shows/hides the side cards; refresh signals only while shown |
| `BAGS_CHANGED`, `DATA_CHANGED`, `PRICES_CHANGED`, `MONEY_CHANGED`, `ITEM_LOADED`, `ADVISOR_CONTEXT`, `SETTINGS_CHANGED`, `MERCHANT_CHANGED` | `AdvisorWindow` | only while shown | see above | one coalesced refresh (`Advisor.Collect`) |
| `PLAYER_MONEY` → `MONEY_CHANGED` with source `LOOT` | `IncomeCapture` → `FarmRuns.AddLootCopper` | always | per looted coin | one number added to the running run |
| `BAGS_CHANGED`, `PRICES_CHANGED`, `ITEM_LOADED` (signals) | Gold buffer tab | handler added on show, removed on hide | see above | requests one refresh; the planner view recomputes bag tasks, craft tasks and routes |

Window refreshes are coalesced: any number of refresh requests in one frame lead to one
`C_Timer.After(0, ...)` callback, which redraws only if the window is still visible. The window is
created on first open and hidden, never destroyed; rows are a fixed pool of 10 frames.

No `OnUpdate` scripts. One-shot `C_Timer.After` callbacks: `0` for coalescing window refreshes; `1` s
taxi check after control loss (`FarmAssist`); `5` s login summary; `10` s price cleanup after login;
`1` s recipe book capture after profession window events; `7` s advisor check after login; `0.3` s
between sell batches (only after a confirmed click, stops when the merchant closes); `0` s retry of
the advisor side cards for the load-on-demand auction window; `30` s auto-hide of the prompt bars (each callback checks a sequence number, so an older timer does
not hide a newer offer). One ticker:

| Ticker | File | Why no event | Interval | Runs while | Cost |
|---|---|---|---|---|---|
| Farm time display | `UI/FarmTab.lua` | passing time has no event | 1 s | the Farm tab is visible **and** a run is running; cancelled on stop, pause, hide | rewrites one font string (status line) |

Hooks added in 0.4.0, post-hooks installed once at `CHARACTER_READY` through the adapter:
`GameTooltip:HookScript("OnTooltipSetItem")` and the same for `ItemRefTooltip` (tooltip lines, cache
lookup only) and `hooksecurefunc(ChatFrameUtil, "InsertLink")` (shift-click into the visible item slot;
skipped while a chat input is open). Taint of these hooks: unverified in game.

Hooks: `hooksecurefunc("SelectTradeSkill")` and `hooksecurefunc("SelectCraft")` in
`Adapters/ClassicEraProfessions.lua`, installed once at load. Secure post-hooks (no taint, Blizzard
code unchanged); they run only when a recipe is selected and set one variable. The adapter's window frame is not routed through
`Core/Events.lua` because the core does not need to know which kind of window is open; its handler
only sets flags.

## Main window (stage 2d)

- `UI/MainWindow.lua` creates the frame on the first `/bof show` (`BackdropTemplate` with
  `BACKDROP_DIALOG_32_32`, `UIPanelCloseButton`; both defined in Blizzard_SharedXML for Vanilla 70003).
- Global frame name `BuyOrFarmForeverMainFrame`: required because `UISpecialFrames` (Escape closes
  the window) holds frame names. Other globals: the namespace, SavedVariables, slash globals and the
  key binding names `BINDING_HEADER_BUYORFARMFOREVER`, `BINDING_NAME_BUYORFARMFOREVER_TOGGLE`,
  `BINDING_NAME_BUYORFARMFOREVER_FARM` (the client reads them for `Bindings.xml`).
- Position: `settings.window.point/x/y`, saved on drag stop, restored on creation (unknown points
  fall back to `CENTER`). `settings.window.allGoals` (default false) stores the "all goals" view.
- The Material tab reads `Stock.Rows` (shared with `/bof stock`) and uses `UIShared.ItemText` /
  `UIShared.GoalName` for names. Buttons: previous/next goal (wraps), "all goals", recipe import
  (`Recipes.ImportSelected`, 1 craft). Mouse wheel scrolls 1 row. Tooltip: item hyperlink plus one
  line per other character.
- Not protected, no secure templates; changing it in combat is allowed.

## Player relief (0.4.0)

Plan: `work/notes/player-automation-plan.md` (development folder). Every chat action has a window
path; chat commands stay as fallback.

- **One code path:** window inputs build the chat command line and run it through `Inputs.Run`
  (`Slash.Handle`), so validation, messages and the `DATA_CHANGED` refresh are shared. New commands for
  this: `/bof goal name`, `/bof gold name|undo`, `/bof alt kind`, `/bof weights template|suggest`,
  `/bof recipe new`, `/bof set`.
- **Input widgets** (`UI/Inputs.lua`): edit boxes commit on Enter and restore on Escape or focus loss;
  `Inputs.SetValue` does not overwrite a box with focus. Item slots take a dragged item
  (`OnReceiveDrag`/`OnClick` + `Client:GetCursorItem`) or a shift-click (link hook; the visible slot
  wins). One confirmation dialog for deletions and the reset.
- **Settings** (`Core/Settings.lua`): one schema (type, default, range, group, label) feeds
  `DB.DEFAULTS.settings`, `DB.MIN`/`DB.MAX`, the settings tab and `/bof set`. One account-wide profile.
- **Farm automation:** idle time is cut at the next activity (`FarmRuns.NoteActivity`, no timer;
  `run.idleSeconds` from `farmIdleMinutes` at start). With `farmAutoReview`, an open loot window decides
  first, then open merchant/bank/AH/mail/trade windows (the gain is left out), then the 2 s loot grace;
  a stopped run without unclear gains is saved. `FarmAssist` pauses on AFK/resting and switches to
  travel on flight paths, and only undoes what it did itself (`run.autoPaused`, `run.autoTravel`).
- **Optional fields, no schema change:** `currentRun.idleSeconds/lastActivityAt/targetNotified/
  autoPaused/autoTravel`, `alternative.copper/seconds/requires`, `income[day].bySource`,
  `characters[key].lastSession`. Each is validated on load and dropped when invalid. The plan proposed
  schema 2 for `bySource`; it was not needed because the field is optional (old days have none).
- **Recipe import** increases an existing goal of the same recipe (`Recipes.ImportOrIncrease`);
  `/bof recipe new` forces a new goal.
- **Weight templates** (`Core/WeightTemplates.lua`) are design choices of the addon (see
  `docs/DATA_SOURCES.md`); the suggestion uses the class and the talent tree with the most points.

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
