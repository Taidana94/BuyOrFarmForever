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
| 0.2.0-alpha.1 | 2026-10-18 | 77 checks passed, 0 failed (65 unit tests); mutation check: breaking the craft multiplier or the bank count fails 5 tests |
| 0.2.0-alpha.2 | 2026-10-18 | 84 checks passed, 0 failed (72 unit tests); mutation check: removing the faction or the realm filter fails 3 tests each |

## In game

Since 2026-10-18 the game folder `_classic_era_\Interface\AddOns\BuyOrFarmForever` is a junction to
`outputs\BuyOrFarmForever` in the development folder: the client loads the files of the branch that
is currently checked out. After a change, `/reload` is enough. Before a test, note the branch and
commit (`git log -1 --oneline`).

| Version | Client | Date | Result |
|---|---|---|---|
| 0.1.0 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed** (details below) |
| 0.2.0-alpha.1 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed (partly)** (details below) |
| 0.2.0-alpha.2 | Classic Era 1.15.9 | – | **not tested yet** (checklist below) |
| – | Forever | – | **not tested in Forever** |

### Result 0.1.0 (Classic Era, 2026-10-18)

Setup: only this addon + BugSack/BugGrabber. Character `CharA-RealmA` (Alliance).

| Check | Evidence | Result |
|---|---|---|
| First start without SavedVariables | SavedVariables: `meta.createdAt` 2026-10-18 17:10, schema 1, client `classic_era` | passed |
| Client detection in the real client | debug log: `client classic_era 1.15.9 (70003), interface 11509, locale deDE` | passed |
| Character data on `PLAYER_LOGIN` | SavedVariables: character entry with defaults and faction | passed |
| Debug mode persists over `/reload` | debug log: debug on, then load with status `ok` and login entries | passed |
| `/bof debug` off/on, `/bof reset` + `confirm` | debug log + settings back to defaults, character data kept | passed |
| Help, version line, reset prompt and timeout, unknown command, umlauts | confirmed by the user (chat output) | passed |
| Combat (no `ADDON_ACTION_BLOCKED`) | confirmed by the user | passed |
| Lua errors | BugGrabber: no errors recorded (session 7) | passed |
| Full logout/login with debug on (checklist step 8) | – | not performed |

Not tested: other client languages, interaction with other addons.

### Result 0.2.0-alpha.1 (Classic Era, 2026-10-18)

| Check | Evidence | Result |
|---|---|---|
| Goal created, item added via link, crafts | SavedVariables: goal 1 "Test", item 2589 × 4, crafts 3 | passed |
| `/bof stock` bag and bank counts | confirmed by the user ("always correct") | passed |
| Bank snapshot taken on bank visit | SavedVariables: `stock.bank[2589] = 1`, `bankAt` 17:38 | passed |
| **Q-T6:** live bank count with closed bank after `/reload` and after a full relog | confirmed by the user | passed |
| Lua errors | BugGrabber: none | passed |
| Snapshot comparison line (debug mode) | debug mode was off | not performed |
| `/bof goal delete` | goal still present | not performed |

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

### Checklist 0.2.0-alpha.1 (Classic Era, material goals)

Use a character that has some linen cloth (or any item) in bags and bank. `/bof debug` on.

1. `/bof goal new Test` → "Ziel 1 „Test“ angelegt …".
2. Open the chat line, type `/bof goal add `, shift-click linen cloth in the bags, type ` 4`, Enter →
   link shown, "jetzt 4 pro Herstellung".
3. `/bof goal add 2592 2` (wool cloth by id) → link or "Gegenstand 2592" if not cached yet.
4. `/bof goal crafts 3`, then `/bof stock` → need 12 / 6, bags and bank counts match what you see.
5. `/bof stock` before any bank visit → "Bank seit Anlegen des Ziels noch nicht besucht."
6. Visit the bank, close it, `/bof stock` → snapshot line "Bank beim letzten Besuch (gerade eben): …".
7. **Bank check (Q-T6):** move some linen from bags into the bank (bank open), close the bank,
   `/reload`, `/bof stock` **without** opening the bank. Is the live bank value equal to the snapshot?
   Then log out completely, log in, `/bof stock` again (still without the bank).
8. `/bof goal`, `/bof goal set 2589 0`, `/bof goal delete 1`, `/bof goal delete 1 confirm`.
9. Errors: `/bof goal add Leinenstoff 2`, `/bof goal add 2589 0`, `/bof goal crafts 0`.
10. `/bof` shows 7 help lines; `/bof version` shows `0.2.0-alpha.1`.

### Checklist 0.2.0-alpha.2 (Classic Era, other characters)

Needs a second character on the same realm (ideally also one of the other faction or realm).

1. Main character: goal with linen cloth (existing goal "Test" is fine). `/bof stock` → the line now
   ends with "Twinks 0 – …". Log out to the character selection.
2. Log in the alt, put some linen in its bags and/or bank (any bag change triggers the snapshot),
   log out.
3. Log in the main character, `/bof stock` → "Twinks <n>" and a line
   "    <Alt>: <n> (Taschen …, Bank …, Stand vor …)". The missing amount is reduced by the alt's count.
4. `/bof stock others` → "… nicht mehr mitgezählt", `/bof stock` without "Twinks";
   `/bof stock others` again → on.
5. If available: an alt of the other faction on the same realm → listed with
   "andere Fraktion, nicht mitgezählt". An alt on another realm → not listed.
6. `/bof version` → `0.2.0-alpha.2`.
