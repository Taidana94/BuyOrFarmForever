# Architecture

Full plan: `work/notes/BuyOrFarmForever-plan.md` in the development folder (not part of the repo).

## Layers

| Layer | Files | WoW API calls |
|---|---|---|
| Namespace | `Core/Init.lua` | none |
| Localization | `Locales/Locale.lua`, `Locales/deDE.lua` | none |
| Core helpers | `Core/Util.lua`, `Core/Log.lua`, `Core/DB.lua` | `Log.lua`: `DEFAULT_CHAT_FRAME`, `geterrorhandler` only |
| Core logic | `Core/Materials.lua` (goals, requirements, shortfall), `Core/Stock.lua` (bag/bank counts via adapter, bank snapshot) | none |
| Adapter interface | `Adapters/Adapter.lua` | `DEFAULT_CHAT_FRAME` (mismatch message) |
| Client adapter | `Adapters/ClassicEra.lua` | all client-specific APIs |
| Events, commands, startup | `Core/Events.lua`, `Core/Slash.lua`, `Core/Main.lua` | `CreateFrame`, `SlashCmdList` |
| Chat UI (provisional) | `UI/ChatCommands.lua` (`/bof goal`, `/bof stock`) | none (prints via `Log.Print`) |

Core logic (later: materials, farm runs, prices, sourcing, craft evaluation, gold buffer) never calls
WoW APIs. It uses `ns.Client` (the adapter) and plain Lua data.

## Load order (TOC)

`Core/Init.lua` → `Locales/Locale.lua` → `Locales/deDE.lua` → `Core/Util.lua` → `Core/Log.lua` →
`Core/DB.lua` → `Core/Materials.lua` → `Adapters/Adapter.lua` → `Adapters/ClassicEra.lua` →
`Core/Events.lua` → `Core/Stock.lua` → `Core/Slash.lua` → `UI/ChatCommands.lua` → `Core/Main.lua`

Modules that listen to signals (`Stock.lua`) load after `Events.lua`; modules that register
subcommands (`ChatCommands.lua`) load after `Slash.lua`.

## Adapter selection

Each client has its own TOC file that lists only its adapter
(`BuyOrFarmForever_Vanilla.toc` → `Adapters/ClassicEra.lua`). The adapter calls `Adapter.Register`.
`Register` validates the adapter (missing fields raise an error) and calls `IsCurrentClient()`
(`WOW_PROJECT_ID == WOW_PROJECT_CLASSIC`). On a mismatch, `ns.Client` stays nil, a German message is
printed and `Core/Main.lua` registers nothing.

### Adapter interface (stage 2b)

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
| `events` (table) | WoW event name → client-neutral signal |

Signals so far: `BANK_OPENED`, `BANK_CLOSED`, `BAGS_CHANGED`, `LOGOUT`. Core code subscribes with
`Events.OnSignal(signal, fn)` and never names WoW events. `Events.Emit(signal, ...)` raises a signal.

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
  included so "0" and "unknown" differ. Taken on `BAGS_CHANGED`, `BANK_OPENED`, `BANK_CLOSED` and
  `LOGOUT` (also on `/reload`), deliberately not on login (bag data may not be loaded yet).
  Items no longer tracked are dropped. Realm and name come from the character key
  (`Name-NormalizedRealm`; normalized realm names have no hyphens).
- `Stock.Sanitize` (in `DB.VALIDATORS`) removes invalid snapshot entries on load.
- Labels are user text: control characters and `|` removed, max. 50 characters.
- `Materials.Sanitize` is registered in `DB.VALIDATORS` and repairs stored goals on load.

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
