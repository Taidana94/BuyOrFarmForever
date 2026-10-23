# Localization

## Status

| Locale | File | Status |
|---|---|---|
| deDE | `Locales/deDE.lua` | base language, complete |
| enUS | – | planned (phase 2) |

## Rules

- No user-visible text in logic code. All text comes from `ns.L`.
- Keys are stable English identifiers in `UPPER_SNAKE_CASE`.
- One string per line, double quotes, `L.KEY = "..."` (required by the check script).
- Placeholders: `%1$s`, `%2$d` by position, filled by `ns.Util.Format` (pure Lua, does not rely on the
  client's `string.format` extensions). Translations may reorder placeholders but must use the same set.
- Fallback chain: active locale → `deDE` → the key itself (recorded in `ns.Locale.missing`).
- The active locale is set once from `Client:GetLocale()` when the adapter registers.
- SavedVariables contain no localized text, only keys, IDs and user-entered text.
- Files are UTF-8 without BOM.
- Only characters the game font draws: ASCII, Latin-1 (umlauts, `ß`, `·`, `×`) and `–`, `„`, `“`
  (verified in Classic Era 1.15.9 on 2026-10-19). `→` shows as a box there. The check script
  (level 1b) rejects every other character. Forever fonts are not verified yet.

## Keys built at runtime

Some keys are built from a fixed set of values: `CATEGORY_<key>` (`RecipeCategories.ORDER` and `LOADING`),
`PROF_MATS_<mode>` / `PROF_MATS_TIP_<mode>` (`ProfessionView.MATS`), `PROF_DIFFICULTY_<DIFFICULTY>`
(`RecipeBook.DIFFICULTIES`), `TEMPLATE_<key>`, `STAT_SHORT_<stat>`. The check script cannot see them; a unit
test (`work/tests/test_professions.lua`) checks that every value has a label. Item class names
(`CLASS_<id>` categories) and profession names come from the client.

## Exception: debug messages

Messages written with `Log.Info/Warn/Error/Trace/Debug` are technical English. They are meant for
development and error reports, not for normal use, and are only shown in chat in debug mode.
The `[Debug]` prefix and the explanation when debug mode is switched on are localized.

## Adding a language

1. Copy `Locales/deDE.lua` to `Locales/<code>.lua`, change `NewLocale("deDE")` to the new code.
2. Translate the values, keep keys and placeholders.
3. Add the file to the TOC after `Locales/deDE.lua`.
4. Run the check script; level 1b reports missing or extra keys and placeholder differences.
