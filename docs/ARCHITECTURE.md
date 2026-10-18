# Architecture

Full plan: `work/notes/BuyOrFarmForever-plan.md` in the development folder (not part of the repo).

## Layers

| Layer | Files | WoW API calls |
|---|---|---|
| Namespace | `Core/Init.lua` | none |
| Localization | `Locales/Locale.lua`, `Locales/deDE.lua` | none |
| Core helpers | `Core/Util.lua`, `Core/Log.lua`, `Core/DB.lua` | `Log.lua`: `DEFAULT_CHAT_FRAME`, `geterrorhandler` only |
| Adapter interface | `Adapters/Adapter.lua` | `DEFAULT_CHAT_FRAME` (mismatch message) |
| Client adapter | `Adapters/ClassicEra.lua` | all client-specific APIs |
| Events, commands, startup | `Core/Events.lua`, `Core/Slash.lua`, `Core/Main.lua` | `CreateFrame`, `SlashCmdList` |

Core logic (later: materials, farm runs, prices, sourcing, craft evaluation, gold buffer) never calls
WoW APIs. It uses `ns.Client` (the adapter) and plain Lua data.

## Load order (TOC)

`Core/Init.lua` → `Locales/Locale.lua` → `Locales/deDE.lua` → `Core/Util.lua` → `Core/Log.lua` →
`Core/DB.lua` → `Adapters/Adapter.lua` → `Adapters/ClassicEra.lua` → `Core/Events.lua` →
`Core/Slash.lua` → `Core/Main.lua`

## Adapter selection

Each client has its own TOC file that lists only its adapter
(`BuyOrFarmForever_Vanilla.toc` → `Adapters/ClassicEra.lua`). The adapter calls `Adapter.Register`.
`Register` validates the adapter (missing fields raise an error) and calls `IsCurrentClient()`
(`WOW_PROJECT_ID == WOW_PROJECT_CLASSIC`). On a mismatch, `ns.Client` stays nil, a German message is
printed and `Core/Main.lua` registers nothing.

### Adapter interface (stage 1)

| Function | Returns |
|---|---|
| `IsCurrentClient()` | bool |
| `GetBuildInfo()` | `{ version, build, date, interface }` |
| `GetLocale()` | locale code |
| `GetAddOnVersion(addonName)` | version string from the TOC, or nil |
| `GetCharacterKey()` | `{ key = "Name-NormalizedRealm", name, realm, normalizedRealm, faction }` or nil before login / for secret values |
| `GetServerTime()` | seconds since the epoch |
| `GetUptime()` | client uptime in seconds |

The interface grows with each stage (plan section 6).

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
