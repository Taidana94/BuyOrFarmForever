# Architecture

Full plan: `work/notes/BuyOrFarmForever-plan.md` in the development folder (not part of the repo).

## Layers

| Layer | Files | WoW API calls |
|---|---|---|
| Namespace | `Core/Init.lua` | none |
| Localization | `Locales/Locale.lua`, `Locales/deDE.lua` | none |
| Core helpers | `Core/Util.lua`, `Core/Log.lua`, `Core/DB.lua` | `Log.lua`: `DEFAULT_CHAT_FRAME`, `geterrorhandler` only |
| Core logic | `Core/Materials.lua` (goals, requirements, shortfall), `Core/Recipes.lua` (imported recipes), `Core/Stock.lua` (bag/bank counts via adapter, snapshots) | none |
| Adapter interface | `Adapters/Adapter.lua` | `DEFAULT_CHAT_FRAME` (mismatch message) |
| Client adapter | `Adapters/ClassicEra.lua` | all client-specific APIs |
| Events, commands, startup | `Core/Events.lua`, `Core/Slash.lua`, `Core/Main.lua` | `CreateFrame`, `SlashCmdList` |
| Chat UI (provisional) | `UI/ChatShared.lua` (helpers), `UI/GoalCommands.lua` (`/bof goal`, `/bof recipe`), `UI/StockCommands.lua` (`/bof stock`) | none (prints via `Log.Print`) |
| Window | `UI/MainWindow.lua` (frame, `/bof show`), `UI/MaterialTabLayout.lua` (widgets), `UI/MaterialTab.lua` (logic) | stable frame API only: `CreateFrame`, templates, `GameTooltip`, `UISpecialFrames`, `C_Timer.After` |

Core logic (later: materials, farm runs, prices, sourcing, craft evaluation, gold buffer) never calls
WoW APIs. It uses `ns.Client` (the adapter) and plain Lua data.

## Load order (TOC)

`Core/Init.lua` → `Locales/Locale.lua` → `Locales/deDE.lua` → `Core/Util.lua` → `Core/Log.lua` →
`Core/DB.lua` → `Core/Materials.lua` → `Core/Recipes.lua` → `Adapters/Adapter.lua` → `Adapters/ClassicEra.lua` →
`Core/Events.lua` → `Core/Stock.lua` → `Core/Slash.lua` → `UI/ChatShared.lua` → `UI/GoalCommands.lua` → `UI/StockCommands.lua` → `UI/MaterialTabLayout.lua` → `UI/MaterialTab.lua` → `UI/MainWindow.lua` → `Core/Main.lua`

Modules that listen to signals (`Stock.lua`) load after `Events.lua`; modules that register
subcommands (`UI/*Commands.lua`) load after `Slash.lua`.

## Adapter selection

Each client has its own TOC file that lists only its adapter
(`BuyOrFarmForever_Vanilla.toc` → `Adapters/ClassicEra.lua`). The adapter calls `Adapter.Register`.
`Register` validates the adapter (missing fields raise an error) and calls `IsCurrentClient()`
(`WOW_PROJECT_ID == WOW_PROJECT_CLASSIC`). On a mismatch, `ns.Client` stays nil, a German message is
printed and `Core/Main.lua` registers nothing.

### Adapter interface (stage 2d)

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
| `ReadSelectedRecipe()` | `{ key, outputItemID (0 = none), outputMin, outputMax, reagents = { { itemID, count } } }`, or nil + `"no_window"` \| `"no_selection"` \| `"loading"` |
| `events` (table) | WoW event name → client-neutral signal |

Signals so far: `BANK_OPENED`, `BANK_CLOSED`, `BAGS_CHANGED`, `ITEM_LOADED`. Internal signal:
`DATA_CHANGED` (raised by `Slash.Handle` after every registered command). Core code subscribes with
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
  character, for all items in the goals of *any* character (`Materials.TrackedItemIDsAll`), zeros
  included so "0" and "unknown" differ. Taken on `BAGS_CHANGED`, `BANK_OPENED`, `BANK_CLOSED` and on
  `/bof stock`. Deliberately not on login (bag data may not be loaded yet) and not on `PLAYER_LOGOUT`:
  in game (Classic Era 70003) both characters stored 0 hearthstones at logout although each had one,
  so counts at logout are treated as unreliable.
  Items no longer tracked are dropped. Realm and name come from the character key
  (`Name-NormalizedRealm`; normalized realm names have no hyphens).
- `Stock.Sanitize` (in `DB.VALIDATORS`) removes invalid snapshot entries on load.
- Labels are user text: control characters and `|` removed, max. 50 characters.
- `Materials.Sanitize` is registered in `DB.VALIDATORS` and repairs stored goals on load.

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
  Enchanting and Beast Training). Both can be open; the most recently opened one is used. Headers
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
| `BAGS_CHANGED`, `BANK_OPENED`, `BANK_CLOSED`, `DATA_CHANGED` (signals) | Material tab | handler added on show, removed on hide (the WoW events stay registered for `Stock`) | see above | requests one refresh |

Window refreshes are coalesced: any number of refresh requests in one frame lead to one
`C_Timer.After(0, ...)` callback, which redraws only if the window is still visible. The window is
created on first open and hidden, never destroyed; rows are a fixed pool of 10 frames.

No `OnUpdate` scripts and no tickers; one-shot `C_Timer.After(0)` only for coalescing. The adapter's window frame is not routed through
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
- The Material tab reads `Stock.Rows` (shared with `/bof stock`) and uses `Chat.ItemText` /
  `Chat.GoalName` for names. Buttons: previous/next goal (wraps), "all goals", recipe import
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
`DB.CHARACTER_DEFAULTS`). Fields not used yet (prices, recipes, farm runs, goals) already exist with
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

## Errors

`Core/Events.lua` calls each handler in `xpcall`. Errors go to `Log.ReportError`: stored in the debug
log and passed to `geterrorhandler()` (BugGrabber/BugSack or the default error frame). Other handlers
for the same event still run. No error is swallowed.

## Debug log

Ring buffer `db.debugLog`, max 200 entries `{ at, level, msg }`. `ERROR`/`WARN` always,
`INFO`/`TRACE`/`DEBUG` only in debug mode. `DEBUG` is also printed. Every dispatched event is traced
(`TRACE`) in debug mode. In read-only mode nothing is written into the stored data.
