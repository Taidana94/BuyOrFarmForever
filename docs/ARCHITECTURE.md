# Architecture

Full plan: `work/notes/BuyOrFarmForever-plan.md` in the development folder (not part of the repo).

## Layers

| Layer | Files | WoW API calls |
|---|---|---|
| Namespace | `Core/Init.lua` | none |
| Localization | `Locales/Locale.lua`, `Locales/deDE.lua` | none |
| Core helpers | `Core/Util.lua`, `Core/Log.lua`, `Core/DB.lua`, `Core/Settings.lua` (settings schema) | `Log.lua`: `DEFAULT_CHAT_FRAME`, `geterrorhandler` only |
| Core logic | `Core/Money.lua` (parse/format copper), `Core/Prices.lua` (prices per source), `Core/PriceCapture.lua` (merchant/auction capture, scan), `Core/FarmRuns.lua` + `Core/FarmRunsValidation.lua` (run state machine), `Core/FarmCapture.lua` (yield from bag changes), `Core/FarmEstimates.lua`, `Core/Acquire.lua` (cheapest way per wanted item, pure), `Core/WantPlan.lua` (the plan with the addon's data, cached), `Core/CraftEval.lua` (gear rating), `Core/SavingsGoals.lua`, `Core/Income.lua` + `Core/IncomeCapture.lua` (gold buffer), `Core/MoneyContext.lua` (source of a gold change), `Core/Session.lua` (play session), `Core/WeightTemplates.lua` (stat weight templates), `Core/Materials.lua` (shared checks of ids, counts, labels), `Core/Wants.lua` (wanted items, migration from goals), `Core/Recipes.lua` (imported recipes), `Core/Stock.lua` (bag/bank counts via adapter, snapshots) | none |
| Adapter interface | `Adapters/Adapter.lua` | `DEFAULT_CHAT_FRAME` (mismatch message) |
| Client adapter | `Adapters/ClassicEraProfessions.lua` (profession windows), `Adapters/ClassicEraTrade.lua` (merchant, auction house), `Adapters/ClassicEraBags.lua` (bags, map), `Adapters/ClassicEraGear.lua` (item stats, equipment), `Adapters/ClassicEraUI.lua` (cursor item, tooltip and link hooks, merchant frame, minimap), `Adapters/ClassicEraPlayer.lua` (AFK, resting, taxi, class, talent points), `Adapters/ClassicEraCrafting.lua`, `Adapters/ClassicEraProfessionInfo.lua`, `Adapters/ClassicEra.lua` | all client-specific APIs |
| Events, commands, startup | `Core/Events.lua`, `Core/Slash.lua`, `Core/Main.lua` | `CreateFrame`, `SlashCmdList` |
| Chat commands (fallback for every window action) | `UI/Shared.lua` (helpers), `UI/*Commands.lua` (`/bof want`, `recipe`, `price`, `farm`, `craft`, `weights`, `gold`, `goldplan`, `make`, `set`), `UI/FarmReports.lua` (estimate text) | none (prints via `Log.Print`) |
| Window | `UI/Widgets.lua` (buttons, check boxes, item tables, tab frames, refresh mixin), `UI/Inputs.lua` (edit boxes, item slot, confirmation dialog, `Inputs.Run`), `UI/MainWindow.lua` (frame, title line, six tabs, `/bof show`), `UI/WantsTabLayout.lua` + `UI/WantsTab.lua`, `UI/FarmTab.lua` (routes) + `UI/FarmWindow.lua` (run control), `UI/Profession*.lua`, `UI/GoldTab.lua` + `UI/GoldPlanPanel.lua`, `UI/SettingsTab.lua`, `UI/HelpTab.lua` | stable frame API only: `CreateFrame`, templates, `GameTooltip`, `UISpecialFrames`, `C_Timer.After` |
| Assistance (no player input) | `UI/FarmAssist.lua` (target reached, auto pause/travel), `UI/FarmSuggest.lua` (start suggestion), `UI/PromptBar.lua` (offer bar), `UI/TooltipLines.lua`, `UI/ShopHints.lua` (merchant/auction hints, reserve warning), `UI/MinimapButton.lua` (+ key binding names), `UI/LoginSummary.lua`, `UI/GoldAuto.lua` | through the adapter; frames via the frame API |

Core logic (wants, the plan, farm runs, prices, gear rating, gold buffer) never calls
WoW APIs. It uses `ns.Client` (the adapter) and plain Lua data.

## Load order (TOC)

`Core/Init.lua` → `Locales/Locale.lua` → `Locales/deDE.lua` → `Core/Util.lua` → `Core/Money.lua` → `Core/Log.lua` → `Core/DB.lua` → `Core/Settings.lua` → `Core/Materials.lua` → `Core/Wants.lua` → `Core/Recipes.lua` → `Core/FarmRuns.lua` → `Core/FarmRunsValidation.lua` → `Data/ClassicEra/Professions.lua` → `Data/ClassicEra/EffectData.lua` → `Adapters/Adapter.lua` → `Adapters/ClassicEraProfessionInfo.lua` → `Adapters/ClassicEraProfessions.lua` → `Adapters/ClassicEraCrafting.lua` → `Adapters/ClassicEraTrade.lua` → `Adapters/ClassicEraBags.lua` → `Adapters/ClassicEraGear.lua` → `Adapters/ClassicEraUI.lua` → `Adapters/ClassicEraPlayer.lua` → `Adapters/ClassicEraExternal.lua` → `Adapters/ClassicEra.lua` → `Core/Events.lua` → `Core/Stock.lua` → `Core/Prices.lua` → `Core/PriceCapture.lua` → `Core/FarmCapture.lua` → `Core/FarmEstimates.lua` → `Core/GoldRoutes.lua` → `Core/Acquire.lua` → `Core/WantPlan.lua` → `Core/GoldPlan.lua` → `Core/BagTasks.lua` → `Core/RecipeBook.lua` → `Core/RecipeCategories.lua` → `Core/ProfessionView.lua` → `Core/CraftTasks.lua` → `Core/AdvisorSources.lua` → `Core/Advisor.lua` → `Core/AdvisorSummary.lua` → `Core/CraftEval.lua` → `Core/WeightTemplates.lua` → `Core/SavingsGoals.lua` → `Core/Income.lua` → `Core/MoneyContext.lua` → `Core/Session.lua` → `Core/IncomeCapture.lua` → `Core/Perf.lua` → `Core/Slash.lua` → `UI/Shared.lua` → `UI/WantCommands.lua` → `UI/PriceCommands.lua` → `UI/FarmCommands.lua` → `UI/FarmAssist.lua` → `UI/CraftCommands.lua` → `UI/GoldCommands.lua` → `UI/GoldPlanCommands.lua` → `UI/SettingsCommands.lua` → `UI/Widgets.lua` → `UI/Inputs.lua` → `UI/WantsTabLayout.lua` → `UI/WantsTab.lua` → `UI/FarmTab.lua` → `UI/FarmWindow.lua` → `UI/ProfessionTabLayout.lua` → `UI/ProfessionDetail.lua` → `UI/ProfessionMakeRow.lua` → `UI/ProfessionTab.lua` → `UI/MakeCommand.lua` → `UI/GoldPlanPanel.lua` → `UI/GoldTab.lua` → `UI/SettingsTab.lua` → `UI/HelpTab.lua` → `UI/MainWindow.lua` → `UI/PromptBar.lua` → `UI/FarmSuggest.lua` → `UI/TooltipLines.lua` → `UI/ShopHints.lua` → `UI/AdvisorText.lua` → `UI/AdvisorCard.lua` → `UI/AdvisorActions.lua` → `UI/AdvisorWindow.lua` → `UI/AdvisorSide.lua` → `UI/MinimapButton.lua` → `UI/LoginSummary.lua` → `UI/GoldAuto.lua` → `UI/PerfCommand.lua` → `Core/Main.lua`

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
| `ScanBags(counts)` | fills and returns `{ [itemID] = count }` for backpack + equipped bags (table cleared first; `GetContainerItemID` + `GetItemCount`, no table per slot) |
| `ScanBank(counts)` | same for the bank and the bank bags (`Enum.BagIndex.Bank`, `NUM_BAG_SLOTS + 1 .. + NUM_BANKBAGSLOTS`); only meaningful while the bank is open |
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
| `ReadAllRecipes()` | every recipe of the open profession windows like `ReadSelectedRecipe` plus `cooldownSeconds`, `profession` (key, `"OTHER"` if unknown) and `difficulty` (raw skill type); second return true if entries were still loading |
| `ReadProfessionSkills()` | `{ { profession, rank, maxRank } }` of the open profession windows (raw numbers) |
| `GetProfessionInfo(key)` | localized profession name, icon file id; nil, nil for `OTHER` |
| `GetEffectCategory(kind, id)` | category key of the client's effect data for `"item"` (item id) or `"spell"` (enchantment), or nil |
| `IsInCombat()` | bool (`InCombatLockdown`) |
| `OpenProfession(professionKey)` | bool: `CastSpellByName(<client spell name>)` was sent (Mining: Smelting 2656); false for Enchanting and unknown keys. Only from a click or command |
| `GetOpenTradeProfession()` | profession key of the open trade skill window (not the craft window), or nil |
| `CraftRecipe(recipeKey, count)` | true after `SelectTradeSkill` + `DoTradeSkill(index, count)`; false + `"combat"` \| `"no_window"` \| `"not_listed"`. Collapsed categories are expanded once (`ExpandTradeSkillSubClass(0)`), the window's filters are left alone. Only from a click or command |
| `GetItemStackSize(itemID)` | units per stack (8th return of `C_Item.GetItemInfo`), or nil while loading |
| `GetItemClassID(itemID)` / `GetItemClassName(classID)` | item class id (`C_Item.GetItemInfoInstant`, no cache needed) / its localized name, or nil |
| `GetCursorItem()` / `ClearCursor()` | item id on the cursor or nil / drop it (drag and drop into item slots) |
| `IsAFK()`, `IsResting()`, `IsOnTaxi()` | bool (legacy returns 1/nil are normalized) |
| `GetClass()` | class file name, e.g. `"PRIEST"`, or nil |
| `GetTalentPoints()` | `{ points tree 1, 2, 3 }` from `C_SpecializationInfo.GetSpecializationInfo` (7th return), or nil |
| `HookItemTooltips(callback)` | post-hook `OnTooltipSetItem` of `GameTooltip` and `ItemRefTooltip`; `callback(tooltip, itemID)`; call once |
| `HookLinkInsert(callback)` | post-hook `ChatFrameUtil.InsertLink`; `callback(itemID)` for shift-clicks while no chat input is open; call once |
| `GetMerchantFrame()`, `GetMinimap()` | Blizzard frames to anchor the merchant hint and the minimap button, or nil |
| `HasExternalPrices()` | bool: a supported price addon (Auctionator API v1) is loaded |
| `GetExternalPrice(itemID)` | copper, ageDays (nil if unknown) of the price addon; nil if none; nil, nil, error if the price addon raised an error (caught with `pcall`) |
| `events` (table) | WoW event name → client-neutral signal |

Parts without adapter state (`ClassicEraUI`, `ClassicEraPlayer`, `ClassicEraExternal`,
`ClassicEraBags`, `ClassicEraProfessionInfo`, `ClassicEraCrafting`) are exposed as methods by a loop in `Adapters/ClassicEra.lua`.

Signals so far: `BANK_OPENED`, `BANK_CLOSED`, `BAGS_CHANGED`, `ITEM_LOADED`, `MERCHANT_OPENED`,
`MERCHANT_CHANGED`, `MERCHANT_CLOSED`, `AUCTION_OPENED`, `AUCTION_CLOSED`, `AUCTION_RESULTS`, `LOOT_OPENED`,
`LOOT_CLOSED`, `LOGOUT` (only the time of a running farm run is noted), `MONEY_CHANGED`,
`EQUIPMENT_CHANGED`, `MAIL_OPENED`, `MAIL_CLOSED`, `TRADE_OPENED`, `TRADE_CLOSED`, `COMBAT_STARTED`,
`PLAYER_FLAGS_CHANGED`, `RESTING_CHANGED`, `CONTROL_LOST`, `CONTROL_GAINED`, `QUEST_REWARDS`,
`QUEST_CLOSED`, `TRAINER_OPENED`, `TRAINER_CLOSED`. Internal
signals: `DATA_CHANGED` (raised by `Slash.Handle` after every registered command), `PRICES_CHANGED`
(raised by `PriceCapture` after storing prices and when the auction house opens or closes),
`CHARACTER_READY` (raised by `Main` after `EnsureCharacter` at login), `FARM_CHANGED` (after a bag
update was counted for a running run), `SETTINGS_CHANGED` (after `/bof set` or a reset), `RECIPES_CHANGED`
(after the recipe book read the profession windows). Core code subscribes with
`Events.OnSignal(signal, fn)` and never names WoW events. `Events.Emit(signal, ...)` raises a signal.
`Events.OffSignal(signal, fn)` removes a handler; when a signal has no handlers left, its WoW events
are unregistered.

The interface grows with each stage (plan section 6).

## Wants and the acquisition plan (0.10.0)

User request 2026-10-23 (`work/notes/wants-plan.md`): "I want this item" and the addon says how to get it
cheapest. Replaces material goals, the sourcing plan and the craft tab of 0.2.0 to 0.9.0.

- `characters[k].wants = { { itemID, count, createdAt } }` (`Core/Wants.lua`, max. 50, merged by item).
  `Wants.OfRecipe(recipe, crafts)`: a recipe stands for its product (enchantments for their reagents),
  used by `/bof recipe` and the professions tab's button. `Wants.TrackedItems(db, set, charKeys?)`:
  wants plus the reagents of stored recipes that make them, as deep as the planner looks; this set
  drives price capture, the AH scan list and the sell exclusions of the advisor.
- `Core/Acquire.lua` (pure, tested with a fake context): `Acquire.Plan(wants, ctx)`. Per item the stock
  pool comes first (one pool for all wants, so two wants never use the same stack); for the rest the
  options BUY (price x rest), FARM ((seconds per unit x rest + travel) x hourValue / 3600) and CRAFT (per
  learned recipe: crafts = rest / average output rounded up, each reagent planned recursively on a copy
  of the pool, max. `MAX_DEPTH` 3, cycle guard; stock a reagent takes counts at its sale value). Lowest
  value wins, ties BUY > CRAFT > FARM. Without an option: OPEN (value infinite, so a craft with an open
  reagent still beats OPEN but loses to any priced option). Totals: copper, farm seconds, travel once per
  zone, craft nodes (reagents first), open nodes.
- `Core/WantPlan.lua` builds the context from the addon's data: `available` = bags + bank (live) +
  snapshots of same-realm, same-faction characters (`settings.countOtherCharacters`), `buyPrice` =
  `PriceCapture.Best`, `saleValue` = `GoldRoutes.SaleValue`, `farm` from `FarmEstimates.ForItem` +
  `MainZone`, `recipesFor` from the recipe books of the characters on the realm and faction (own first).
  `hourValue`: setting `hourValueGold` if > 0, else the rating per hour of the best route
  (`GoldRoutes.Current()[1]`), else 0. The plan is cached and invalidated on `BAGS_CHANGED`,
  `BANK_CLOSED`, `PRICES_CHANGED`, `DATA_CHANGED`, `RECIPES_CHANGED`, `SETTINGS_CHANGED`.
  `Requirements(plan)` (everything the plan needs in the bags, i.e. all nodes but crafts) feeds
  `Stock.Rows` for tooltips, advisor and farm assist; `ToGet(plan)` (buy/farm/open per item) feeds the
  auction suggestions, the AH hint and the farm start suggestion.
- UI: `UI/WantsTab.lua` + `UI/WantsTabLayout.lua` (wants list with count boxes, plan tree with indent,
  "Herstellen" runs `MakeCommand.Run`, "Farmen" runs `farm start <item>`, summary lines incl. the free
  gold check and the hour value); `UI/WantCommands.lua` (`/bof want`, `/bof recipe`, shared texts).

## Stock (stages 2a, 2b; full snapshots since 0.10.0)

- Live counts: bags via `GetBagCount`; bank = `GetBagAndBankCount - GetBagCount`, correct with a closed
  bank (confirmed in game, Classic Era 70003).
- Snapshots per character: `stock.bags` = every item in the bags (`Client:ScanBags`, in place) on
  `BAGS_CHANGED`, while the bank is open also `stock.bank` (`Client:ScanBank`); on `BANK_CLOSED` the
  bank snapshot's items and everything seen in the bags meanwhile are recounted from the live counts.
  Once after login (`Stock.LOGIN_DELAY_SECONDS` 10) the bags are captured too, unless the scan is empty
  while a snapshot with items exists (bag data not loaded). Not on `PLAYER_LOGOUT`: in game the counts
  were already 0 there. User decision 2026-10-23: no manual bookkeeping, everything the account owns is
  known. A character's bank is known after its first bank visit with 0.10.0.
- `Stock.OthersFor` lists other characters of the realm with the item (same faction counted).
  `Stock.Sanitize` (in `DB.VALIDATORS`) removes invalid snapshot entries on load.
- Labels (savings goals) are user text: control characters and `|` removed, max. 50 characters
  (`Materials.CleanLabel`).

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
- The wants plan compares its purchases with the free gold (gold minus reserves) and warns when it is
  short; the setting `useReservesInSourcing` of 0.3.0 to 0.9.0 is gone (migration 1 -> 2).

## Farm window and farm tab (0.10.0)

User decision 2026-10-23: runs are controlled in a small window (`UI/FarmWindow.lua`: Start, Pause /
Fortsetzen, Anreise / Angekommen, Beenden; `/bof farm`, right click on the minimap button, opened by
`farm start`), the Farm tab lists the recorded routes per zone (`GoldRoutes.Current({ minSeconds = 0,
minCopper = 0 })`, loot per hour in the tooltip). Runs have no activity type any more (`activity` is
stored as `OTHER`, old values validate), "Beenden" saves at once and drops unclear gains
(`FarmRuns.Finish`), the review state is gone. The buttons call `Inputs.Run("farm …")`, one code path
with the chat. The status line is rewritten by the 1 s ticker (see Events and timers).

## Gear rating (stage 3, reduced in 0.10.0)

`Core/CraftEval.lua` compares an item with the equipped gear using the character's weights
(`craftEval.weights`, 0–10, STR, AGI, STA, INT, SPI, ARMOR, DPS; defaults 1/1/1/1/1/0/0, templates in
`Core/WeightTemplates.lua`). Shown as one line in the professions detail for gear recipes
(`CraftCommands.GearLine`), in the tooltip of wanted gear (`TooltipLines`) and by `/bof craft <item>`.
The weights are edited in the settings tab (boxes plus "Vorschlag"). The alternatives editor, the
quest reward offers and the sourcing cost per score point of 0.3.0 to 0.9.0 are gone (user decision
2026-10-23).

- Stats: `GetItemStats(link)` (global function, confirmed in game in Classic Era 70003); the adapter
  maps Blizzard keys to `STR, AGI, STA, INT, SPI, ARMOR, DPS`; the core never sees Blizzard keys.
- Slots (adapter, from `C_Item.GetItemInfoInstant` equip location): rings and trinkets replace the
  weaker equipped one, two-handed weapons replace main and off hand together (`.sum`), one-handed
  weapons are compared with the main hand only, empty slots count 0.
- `CraftEval.LevelLock` marks items above the character level. `CraftEval.Sanitize` resets invalid
  weights.

### Gold routes (0.5.0, zone-based since 0.10.0)

`Core/GoldRoutes.lua`: saved runs grouped by `uiMapID` (`GoldRoutes.Key`), value = loot x
`GoldRoutes.SaleValue` (lowest current AUCTION / MANUAL / AUCTIONATOR price minus `AUCTION_CUT` 5 %, or
the vendor sell price if higher) plus looted coins, split into sure and auction gold; rating = sure +
auction x (1 - `ahDiscountPercent`); travel = average per run. `List` filters by `minSeconds` (default
`MIN_SECONDS` 600) and `minCopper` (default 1). The best route's rating per hour is the time value of
farming in the wants plan.

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

### Strategy comparison (0.11.0)

- Gold per character: `characters[key].money` / `moneyAt`, written by `Core/IncomeCapture.lua` at
  login and on every gold change. `Core/Account.lua` (pure): rows per character of a realm (gold,
  professions with skill and recipe count, distinct items and units in the bag and bank snapshots).
- Fishing: `FarmCapture` counts loot windows of a running run (`run.loots`, `run.fishingLoots`
  via `Client:IsFishingLoot()` on LOOT_OPENED); `FarmRuns.Save` stores `activity = "FISHING"` when
  more than `FISHING_SHARE` (50 %) were fishing loot. `GoldRoutes.Key` = `"<uiMapID>"` or
  `"<uiMapID>:FISHING"` (strings since 0.11.0); routes carry `fishing`.
- Crafted routes: `Core/Conversion.lua` values one unit of loot through the best learned recipe
  (no cooldown) using it: (products' sale value - other reagents at `PriceCapture.Best`) / units
  needed, kept only when it beats selling the loot raw; craft + post seconds per unit
  (`CraftTasks.SECONDS_PER_CRAFT` / units). `Strategies.CraftedRoutes` (pure) adds the gain per hour
  and scales the route by 3600 / (3600 + craft seconds per farmed hour). `Conversion.Methods` =
  routes + crafted routes; used by the gold plan and the advisor's best hour.
- `Strategies.Compare` (pure): one `GoldPlan.Plan` per family (BEST, BAGS, CRAFT, FARM, FISHING,
  FARM_CRAFT), ranked by rating; families without a step are returned separately.
- UI: `/bof compare [duration]`, `/bof account` (`UI/AccountCommands.lua`); planner view buttons
  Plan / Vergleich / Konto (view not stored).

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

### Professions tab (0.8.0)

User request 2026-10-23 (plan: `work/notes/professions-view-plan.md` in the development folder): one view per
profession with the character's learned recipes, grouped by what the product is good for, a reagent filter
and a nicer look (inspired by a screenshot of another addon, not copied).

- **Recipe book** (`Core/RecipeBook.lua`): entries get `profession` (key) and `difficulty` (`optimal` |
  `medium` | `easy` | `trivial`) from the window; `characters[key].professions[key] = { rank, maxRank, at }`
  holds the skill bars. Enchantments (no output item) are kept now; every user that needs an item skips
  `outputItemID == 0` (`CraftTasks`, `AdvisorSources`, `LoginSummary`). Cap `MAX_RECIPES` 1000. After a
  capture the internal signal `RECIPES_CHANGED` is raised.
- **Profession keys** (`RecipeBook.PROFESSIONS`, display order): `ALCHEMY`, `BLACKSMITHING`, `ENCHANTING`,
  `ENGINEERING`, `LEATHERWORKING`, `TAILORING`, `MINING`, `COOKING`, `FIRST_AID`, `POISONS`, `OTHER`.
  The Classic Era adapter recognizes a window by comparing `GetTradeSkillLine()` / `GetCraftDisplaySkillLine()`
  with `C_TradeSkillUI.GetTradeSkillDisplayName(skillLine)` and the profession spell names
  (`Data/ClassicEra/Professions.lua`); nothing localized is stored. Smelting (2656) counts as Mining.
  No match → `OTHER`. Fishing has no recipes in Classic Era.
- **Categories** (`Core/RecipeCategories.lua`, `FromFacts` pure): effect data of the client
  (`Data/ClassicEra/EffectData.lua`: consumables and enchantments) → gear by its largest primary stat
  (STR, AGI, STA, INT, SPI; ties in that order; none → `WEAPON` with DPS, else `ARMOR`) → item class
  (`CLASS_<classID>`, label from `C_Item.GetItemClassInfo`) → `UTILITY` for enchantments without data.
  Results are cached per recipe key for the session; nil (gear stats still loading) is not cached and shows
  as `LOADING`. Classic Era consumables have no reliable sub-classes (the Classic auction UI only uses them
  from TBC on), hence the data table.
- **View model** (`Core/ProfessionView.lua`): `Professions(charData)`, `Build(charData, profession,
  { search, mats })` (groups in category order, rows by client name; `mats` = `ALL` | `SOME` (at least one
  reagent with enough units in the bags) | `COMPLETE` (all of them)), `Economics(recipe, now)` (reagent cost
  at buy prices, vendor and auction value after the cut, profit = best sale − cost; nil when a price is
  missing). Search is a plain substring of the lower-cased name (`string.lower` folds ASCII only).
- **UI**: `UI/ProfessionTabLayout.lua` (profession icons, skill bar, search box, three filter buttons, pool
  of 15 rows for headers and recipes, mouse wheel), `UI/ProfessionDetail.lua` (product, category, skill-up
  chance, up to 8 reagents with bags/need and bank, crafts possible, cost/value/profit, button "Als Ziel
  anlegen" → `/bof recipe key <key>` → `Recipes.GoalFromStored`), `UI/ProfessionTab.lua` (state and
  refresh). Settings: `settings.window.profession` (key, "" = first), `settings.window.professionMats`.
  Search, scroll, collapsed categories and the selected recipe last for the session.

### Crafting from the professions tab (0.9.0)

User request 2026-10-23: craft directly from the tab (count, all, one stack) without opening the profession
window by hand.

- `/bof make <recipeKey> [count|all]` (`UI/MakeCommand.lua`); the tab's buttons run it through `Inputs.Run`,
  so chat and window share messages and checks. Learned recipes only; enchantments are refused (they need a
  target item, `DoCraft`); the count is capped at what the bags allow (`ProfessionView.ReagentState`).
- Window closed or showing another profession: the command only opens the right window
  (`Client:OpenProfession`) and asks for a second click. Crafting right after `TRADE_SKILL_SHOW` would run
  outside the hardware event of the click; whether the client allows `DoTradeSkill` there is not verified, and
  a blocked call would show the client's "action blocked" message. Open question for a later single-click flow
  (in-game check in `docs/TESTING.md`).
- In combat nothing is opened or crafted (`IsInCombat`).
- Sources: warcraft.wiki.gg `API_DoTradeSkill` (no restriction tag) and `API_CastSpellByName` (protected, "can
  still open trade skill windows ... from a tainted execution path"), 2026-10-23, community; the Vanilla
  TradeSkillUI calls `DoTradeSkill` and `ExpandTradeSkillSubClass(0)` itself.
- UI: `UI/ProfessionMakeRow.lua` (box, "Herstellen", "Alle: n", "Stapel: n" = `ProfessionView.CraftCounts`:
  crafts for one stack of the product, rounded up, at most what the bags allow). The goal button moved to the
  right of the reagent label.

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
replaces an older one) and adds the wants of `Wants.OfRecipe` (product x crafts, or the reagents of an
enchantment). `/bof recipe key <key> [crafts]` does the same for a stored recipe (`Recipes.Stored`).

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
| `BAG_UPDATE_DELAYED` → `BAGS_CHANGED` | `Stock`, `WantPlan` (invalidate) | always | once per bag-change burst (the client coalesces `BAG_UPDATE`) | one bag scan into the reused snapshot table (about 100 slots, `GetContainerItemID` + `GetItemCount`, no garbage); the bank too while it is open |
| `BANKFRAME_OPENED` / `_CLOSED` → `BANK_OPENED` / `BANK_CLOSED` | `Stock`, `WantPlan` (invalidate on close) | always | per bank visit | bank scan on open; recount of the bank snapshot from live counts on close |
| `TRADE_SKILL_SHOW` / `_CLOSE`, `CRAFT_SHOW` / `_CLOSE` | Classic Era adapter (own frame) | always | per profession window open/close | sets two flags, no API calls |
| `ITEM_DATA_LOAD_RESULT` → `ITEM_LOADED` | window tabs, farm window | only while shown | per item whose data arrives | requests one refresh |
| `MERCHANT_SHOW` / `MERCHANT_CLOSED` | `PriceCapture` | always | per merchant visit | reads the merchant list once, stores tracked items |
| `MERCHANT_UPDATE` → `MERCHANT_CHANGED` | `PriceCapture` | only while a merchant is open | when merchant data changes | same as above |
| `AUCTION_HOUSE_SHOW` / `AUCTION_HOUSE_CLOSED` | `PriceCapture` | always | per auction house visit | flags, scan list reset |
| `BAGS_CHANGED`, `LOOT_OPENED`, `LOOT_CLOSED`, `LOGOUT` (signals) | `FarmCapture` | only while a farm run is running (start/resume/login-continue on; pause/stop/discard off) | per bag update / loot window | bag scan of the carried bags (about 100 slots), diff with reused count tables |
| `PLAYER_EQUIPMENT_CHANGED` → `EQUIPMENT_CHANGED` | `TooltipLines` | always | per equipment change | dirty flag |
| `PLAYER_MONEY` → `MONEY_CHANGED` | `IncomeCapture` (always), Wants and Gold tab (while shown) | always | per gold change | one income record update (no allocation once the day exists); tabs request a refresh |
| `BAGS_CHANGED`, `LOGOUT` (signals) | `IncomeCapture` | always | per bag-change burst / logout | online-time checkpoint (two number updates) |
| `AUCTION_ITEM_LIST_UPDATE` → `AUCTION_RESULTS` | `PriceCapture` | only while the auction house is open | per result page and when row data arrives | reads one page (max. 50 rows), stores the lowest unit buyout of tracked items |
| `BAGS_CHANGED`, `BANK_CLOSED`, `ITEM_LOADED`, `DATA_CHANGED`, `PRICES_CHANGED`, `MONEY_CHANGED`, `RECIPES_CHANGED`, `AUCTION_*`, `SETTINGS_CHANGED` (signals) | Wants tab | handler added on show, removed on hide (the WoW events stay registered for `Stock` etc.) | see above | one coalesced refresh: reads the cached plan (rebuilt at most once per invalidating signal), fills 10 want rows and 11 tree rows |
| `BAGS_CHANGED`, `BANK_CLOSED`, `PRICES_CHANGED`, `DATA_CHANGED`, `RECIPES_CHANGED`, `SETTINGS_CHANGED` (signals) | `WantPlan` | always | per change | clears the cached plan (one assignment); the plan is rebuilt lazily by the next reader |
| `MERCHANT_*`, `BANK_*`, `AUCTION_*`, `MAIL_*`, `TRADE_*`, `COMBAT_STARTED` (signals) | `FarmCapture` | only while a farm run is running | per window / combat start | flag updates; combat start notes activity (idle time) |
| `PLAYER_FLAGS_CHANGED`, `PLAYER_UPDATE_RESTING`, `PLAYER_CONTROL_LOST/GAINED` | `FarmAssist` | only while a farm run exists; synced on `DATA_CHANGED` | per AFK/resting/flight change | at most one `/bof farm` command; control loss starts one `C_Timer.After(1)` taxi check |
| `FARM_CHANGED` (internal) | `FarmAssist`, farm window and tab (while shown) | always (raised only during runs) | per counted bag update | target check (`Stock.Rows` over the plan's requirements) only until the target was reported |
| `LOOT_OPENED`, `LOOT_CLOSED`, `BAGS_CHANGED` (signals) | `FarmSuggest` | only while `farmSuggestStart` is on | per loot window / bag burst | counts of the plan's items still to get at loot open, compared after the loot |
| `LOOT_*`, `QUEST_REWARDS/CLOSED`, `MERCHANT_*`, `TRAINER_*`, `MAIL_*`, `AUCTION_*`, `TRADE_*` (signals) | `MoneyContext` | always | per window | one flag each (source of the next gold change) |
| `DATA_CHANGED`, `BAGS_CHANGED`, `BANK_CLOSED`, `EQUIPMENT_CHANGED`, `SETTINGS_CHANGED`, `PRICES_CHANGED`, `RECIPES_CHANGED` (signals) | `TooltipLines` | always | per change | sets a dirty flag; the tooltip cache is rebuilt on the next item tooltip |
| `PLAYER_MONEY` → `MONEY_CHANGED` | `ShopHints` (while a merchant is open), `GoldAuto` (always; acts only with `goldAutoDistribute`) | see column | per gold change | hint text and reserve check; `GoldAuto` distributes only after a gain |
| `TRADE_SKILL_SHOW`, `CRAFT_SHOW` → `PROFESSION_OPENED`; `TRADE_SKILL_UPDATE`, `CRAFT_UPDATE` → `PROFESSION_CHANGED` | `RecipeBook` | always | per window open; updates in bursts (casts, filters) | one `C_Timer.After(1)` per burst, then one read of all visible recipes (`ReadAllRecipes`) |
| `MERCHANT_*`, `AUCTION_*`, `BANK*`, `MAIL_*`, `PROFESSION_OPENED/CLOSED` (signals) | `Advisor` | always | per window | updates the open-window list; raises `ADVISOR_CONTEXT` on change |
| `ADVISOR_CONTEXT`, `SETTINGS_CHANGED` (signals) | `AdvisorSide` | always | per window | shows/hides the side cards; refresh signals only while shown |
| `BAGS_CHANGED`, `DATA_CHANGED`, `PRICES_CHANGED`, `MONEY_CHANGED`, `ITEM_LOADED`, `ADVISOR_CONTEXT`, `SETTINGS_CHANGED`, `MERCHANT_CHANGED` | `AdvisorWindow` | only while shown | see above | one coalesced refresh (`Advisor.Collect`) |
| `PLAYER_MONEY` → `MONEY_CHANGED` with source `LOOT` | `IncomeCapture` → `FarmRuns.AddLootCopper` | always | per looted coin | one number added to the running run |
| `BAGS_CHANGED`, `PRICES_CHANGED`, `ITEM_LOADED`, `MONEY_CHANGED` (signals) | Gold buffer tab | handler added on show, removed on hide | see above | requests one refresh; the planner view recomputes bag tasks, craft tasks and routes |
| `FARM_CHANGED`, `DATA_CHANGED`, `ITEM_LOADED`, `PRICES_CHANGED` (signals) | Farm tab (routes) | handler added on show, removed on hide | see above | one coalesced refresh: routes from the saved runs (at most 500) |
| `FARM_CHANGED`, `DATA_CHANGED`, `ITEM_LOADED` (signals) | Farm window | only while shown | see above | button states and one status line |
| `BAGS_CHANGED`, `ITEM_LOADED`, `PRICES_CHANGED`, `DATA_CHANGED`, `RECIPES_CHANGED` (signals) | Professions tab | handler added on show, removed on hide | see above; `RECIPES_CHANGED` once per profession window burst | one coalesced refresh: groups the recipes of one profession (at most a few hundred rows, categories cached per recipe), fills 15 rows and the detail panel |

Window refreshes are coalesced: any number of refresh requests in one frame lead to one
`C_Timer.After(0, ...)` callback, which redraws only if the window is still visible. The window is
created on first open and hidden, never destroyed; rows are a fixed pool of 10 frames.

No `OnUpdate` scripts. One-shot `C_Timer.After` callbacks: `0` for coalescing window refreshes; `1` s
taxi check after control loss (`FarmAssist`); `5` s login summary; `10` s price cleanup and bag snapshot after login;
`1` s recipe book capture after profession window events; `7` s advisor check after login; `0.3` s
between sell batches (only after a confirmed click, stops when the merchant closes); `0` s retry of
the advisor side cards for the load-on-demand auction window; `30` s auto-hide of the prompt bars (each callback checks a sequence number, so an older timer does
not hide a newer offer). One ticker:

| Ticker | File | Why no event | Interval | Runs while | Cost |
|---|---|---|---|---|---|
| Farm time display | `UI/FarmWindow.lua` | passing time has no event | 1 s | the farm window is shown **and** a run is running; cancelled on stop, pause, hide | rewrites one font string (status line) |

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
  fall back to `CENTER`). `settings.window.tab` stores the shown tab (default `WANTS`).
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
  `run.idleSeconds` from `farmIdleMinutes` at start). An open loot window decides first, then open
  merchant/bank/AH/mail/trade windows (the gain is left out), then the 2 s loot grace. Since 0.10.0
  "Beenden" saves the run at once and drops unclear gains (`FarmRuns.Finish`); the `farmAutoReview`
  setting and the review step are gone. `FarmAssist` pauses on AFK/resting and switches to
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

## SavedVariables (schema 2)

One account-wide variable `BuyOrFarmForeverDB`. Defaults: `Core/DB.lua` (`DB.DEFAULTS`,
`DB.CHARACTER_DEFAULTS`). Schema 2 (0.10.0): `characters[k].wants` replaces `materialGoals`,
`activeGoalID`, `nextGoalID` and `craftEval.alternatives`; the settings `strategy`, `budgetCopper`,
`farmTimeLimitMinutes`, `useReservesInSourcing`, `farmAutoReview`, `questAlternatives`,
`window.allGoals` are removed and `window.tab` is reset. Migration 1 -> 2 (`Core/Wants.lua`): a goal
with a recipe that makes an item becomes a want of that item (crafts x smallest output), every other goal
its materials x crafts; duplicates and the cap are handled by `Wants.Sanitize` on load.

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

## Glossary

| Term | Meaning |
|---|---|
| want | an item the player wants with a count (`characters[].wants`); user-facing "Ziel" |
| plan / node | the acquisition plan of the wants and one item in it with its method (HAVE, BUY, FARM, CRAFT, OPEN) |
| hour value | copper one hour of farming is worth in the plan (setting, else the best route's rating per hour) |
| reagent | an item a recipe consumes (`recipe.reagents`); planned like any other item |
| recipe book | the recipes a character has seen in its own profession windows (`characters[].recipeBook`) |
| profession key | client-neutral profession id (`COOKING`, ...), never a localized name |
| category | what a recipe's product is good for (`STR`, `HEAL`, `CLASS_7`, ...), see Professions tab |
| route | the saved farm runs of one zone with their gold per hour (`GoldRoutes`) |
| savings goal | the gold buffer's goal |

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
