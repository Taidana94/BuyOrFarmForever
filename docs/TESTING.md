# Testing

## Out of game (development folder)

One command runs levels 0, 1, 1b and 2:

```text
py -3 -I work/tools/check.py outputs/BuyOrFarmForever
```

| Level | Content |
|---|---|
| 0 | TOC naming, required TOC fields, interface 11509 for `_Vanilla`, SemVer, listed files exist with exact case, no unlisted files, UTF-8 without BOM |
| 1 | `luac5.1 -p` for all Lua files, luacheck with the addon's `.luacheckrc` (warnings fail) |
| 1b | used locale keys exist in deDE, other locales have the same keys and placeholders, no hardcoded user text |
| 2 | unit tests in a mock client environment (`work/tests/`) |

The mock environment models Classic Era 1.15.9 (70003) and provides only the APIs in `.luacheckrc`.
It simulates startup (`ADDON_LOADED`, `PLAYER_LOGIN`), `/reload` (SavedVariables are serialized like
the client does, functions or invalid keys fail the test), slash commands, the error handler and time.

### Results

| Version | Date | Result |
|---|---|---|
| 0.1.0 | 2026-10-18 | 55 checks passed, 0 failed (43 unit tests) |

## In game

| Version | Client | Date | Result |
|---|---|---|---|
| 0.1.0 | Classic Era 1.15.9 | – | **not tested yet** |
| – | Forever | – | **not tested in Forever** |

### Checklist 0.1.0 (Classic Era)

Setup: only this addon + BugSack/BugGrabber enabled. `/console scriptErrors 1`.

1. First start without SavedVariables (delete `BuyOrFarmForever.lua` in SavedVariables if present):
   log in, no chat message, no BugSack error.
2. `/bof` → 5 lines of help. `/kof help` → same.
3. `/bof version` → `Version 0.1.0 · Interface 11509 · Build 70003 (1.15.9) · Classic Era`.
4. `/bof debug` → "Debug-Modus ist an …". `/reload`. `/bof debug` → "Debug-Modus ist aus.". `/bof debug` again (on).
5. `/bof reset` → prompt with 30 seconds. `/bof reset confirm` → "… zurückgesetzt". Debug is off again.
6. `/bof reset`, wait > 30 s, `/bof reset confirm` → "Es wartet kein Zurücksetzen …".
7. `/bof fly` → "Unbekannter Befehl: „fly“ …".
8. `/bof debug` (on), `/reload`, then log out completely and back in.
9. Enter combat (training dummy or mob), run `/bof version` during combat → no `ADDON_ACTION_BLOCKED`.
10. Umlauts in all messages display correctly.

Report back: BugSack content (if any), and the file
`WTF/Account/<ACCOUNT>/SavedVariables/BuyOrFarmForever.lua` (or read access to the folder).
