# Testing

## Out of game (development folder)

One command runs levels 0, 1, 1b, 1c and 2:

```text
py -3 -I work/tools/check.py outputs/BuyOrFarmForever
```

| Level | Content |
|---|---|
| 0 | TOC naming, required TOC fields, interface 11509 for `_Vanilla`, SemVer, listed files exist with exact case, no unlisted files, UTF-8 without BOM |
| 1 | `luac5.1 -p` for all Lua files, luacheck with the addon's `.luacheckrc` (warnings fail) |
| 1b | used locale keys exist in deDE, other locales have the same keys and placeholders, no hardcoded user text |
| 1c | cleanliness and performance (`work/tools/lua_static.py`): every `OnUpdate` script and ticker has `-- PERF-OK:` and is named in ARCHITECTURE.md; `CreateFrame` only at file level or in create/build functions; no magic numbers in `Core/` and `Adapters/` (0, 1, 2 allowed; constants are UPPER_SNAKE); functions at most 40 lines and nesting 3; files at most 300 lines |
| 2 | unit tests in a mock client environment (`work/tests/`), including an allocation test: 10000 bag events must not allocate memory beyond a constant |

The mock environment models Classic Era 1.15.9 (70003) and provides only the APIs in `.luacheckrc`.
It simulates startup (`ADDON_LOADED`, `PLAYER_LOGIN`), `/reload` (SavedVariables are serialized like
the client does, functions or invalid keys fail the test), slash commands, the error handler and time.

### Results

| Version | Date | Result |
|---|---|---|
| 0.1.0 | 2026-10-18 | 55 checks passed, 0 failed (43 unit tests) |
| 0.2.0-alpha.1 | 2026-10-18 | 77 checks passed, 0 failed (65 unit tests); mutation check: breaking the craft multiplier or the bank count fails 5 tests |
| 0.2.0-alpha.2 | 2026-10-18 | 84 checks passed, 0 failed (72 unit tests); mutation check: removing the faction or the realm filter fails 3 tests each |
| 0.2.0-alpha.2 (fix) | 2026-10-18 | 85 checks passed, 0 failed (73 unit tests); mutation check: restoring the logout snapshot fails the snapshot test |
| 0.2.0-alpha.3 | 2026-10-18 | 95 checks passed, 0 failed (83 unit tests); mutation checks: no window fallback, no header check, no reagent merge each fail 1 test |
| 0.2.0-alpha.10 | 2026-10-18 | 146 checks passed, 0 failed (129 unit tests); mutation checks: reversed buying order fails 3, ignoring the budget 5, SAVE_GOLD buying everything 1, no travel time 2 |
| 0.2.0-alpha.8 | 2026-10-18 | 138 checks passed, 0 failed (121 unit tests); mutation checks: no loot grace, never pausing at login, ignoring zero-yield target runs, counting decreases (after strengthening the test) each fail 1 |
| 0.2.0-alpha.7 | 2026-10-18 | 129 checks passed, 0 failed (112 unit tests); the new test fails without the selection hook |
| 0.2.0-alpha.6 | 2026-10-18 | 128 checks passed, 0 failed (111 unit tests); mutation checks: no auction page merge fails 1, ignoring price age fails 2, no unregister of auction results fails 1 |
| 0.2.0-alpha.5 | 2026-10-18 | 117 checks passed, 0 failed (100 unit tests; levels 0, 1, 1b, 1c, 2); 1c mutation check: injected OnUpdate, ticker, CreateFrame in a handler, magic numbers and deep nesting are all reported |
| 0.2.0-alpha.4 | 2026-10-18 | 107 checks passed, 0 failed (95 unit tests); mutation checks: no unregister on hide fails 2, no coalescing fails 1, no colors fails 2 (after strengthening the color test) |

## In game

Since 2026-10-18 the game folder `_classic_era_\Interface\AddOns\BuyOrFarmForever` is a junction to
`outputs\BuyOrFarmForever` in the development folder: the client loads the files of the branch that
is currently checked out. After a change, `/reload` is enough. Before a test, note the branch and
commit (`git log -1 --oneline`).

| Version | Client | Date | Result |
|---|---|---|---|
| 0.1.0 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed** (details below) |
| 0.2.0-alpha.1 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed (partly)** (details below) |
| 0.2.0-alpha.2 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **failed**, then **passed** after the logout fix (details below) |
| 0.2.0-alpha.3 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed (partly)** (details below) |
| 0.2.0-alpha.4 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed** (details below) |
| 0.2.0-alpha.5 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed** (smoke test) |
| 0.2.0-alpha.6 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed** (confirmed by the user; details below) |
| 0.2.0-alpha.7 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed** (user: "gut"; SavedVariables below) |
| 0.2.0-alpha.8 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed (partly)**, usability finding (details below) |
| 0.2.0-alpha.9 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed** (travel/farm split; details below) |
| 0.2.0-alpha.10 | Classic Era 1.15.9 | – | **not tested yet** (checklist below) |
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
| `/bof goal delete` | later SavedVariables: `materialGoals` empty, `nextGoalID` 2 (done before the 0.2.0-alpha.2 test) | passed |

### Result 0.2.0-alpha.2 (Classic Era, 2026-10-18)

Setup: this addon + BugSack/BugGrabber. Characters `CharA` and `CharB`, both
`RealmA`, Alliance. Test item: hearthstone (6948).

| Check | Evidence | Result |
|---|---|---|
| First attempt: alt counted | "Twinks 0"; SavedVariables: both characters `stock.bags[6948] = 0` although each has one; snapshots were taken on `PLAYER_LOGOUT` | **failed** (bug) |
| Fix: no logout snapshot, `/bof stock` stores a snapshot | SavedVariables: CharA `bags[6948] = 1`, CharB `bags[6948] = 1` | passed |
| `/bof stock` on CharA shows "Twinks 1" and the detail line for CharB | confirmed by the user | passed |
| `/bof stock others` off and on | confirmed by the user; SavedVariables: `countOtherCharacters = true` at the end | passed |
| Lua errors | `!BugGrabber.lua`: `errors` empty (session 23) | passed |
| Other-faction alt shown but not counted, other-realm alt hidden | no such characters | not performed (out of game only) |

Observation (own conclusion from the data, not measured directly): `C_Item.GetItemCount` returns 0
during `PLAYER_LOGOUT` in Classic Era 70003.

### Result 0.2.0-alpha.3 (Classic Era, 2026-10-18)

Setup: this addon + BugSack/BugGrabber. Character `CharA-RealmA`.

| Check | Evidence | Result |
|---|---|---|
| Recipe import from the trade skill window | SavedVariables: goal 3 with `recipeKey = "item:2852"`, reagent 2840 × 4; `db.recipes["item:2852"]` stored with `origin = "IMPORT"` | passed |
| Messages (no window, header, crafts errors), name display, `/reload` | confirmed by the user ("passt") | passed |
| Lua errors | `!BugGrabber.lua`: `errors` empty (session 25) | passed |
| Recipe key from `GetTradeSkillRecipeLink` | the stored key is `item:`, so the trade skill recipe link gave no `enchant:`/`spell:` id (or nil) | observation |
| Craft window (Enchanting), both windows open | no evidence in the data (no `spell:` recipe stored) | not performed |

The stored goal has `crafts = 1`; the checklist asked for `/bof recipe 3`. The unit test covers the
crafts argument; if the in-game command was entered with 3, this needs a recheck.

### Result 0.2.0-alpha.4 (Classic Era, 2026-10-18)

Checklist 0.2.0-alpha.4 (main window) confirmed by the user ("alles gepasst"): layout, numbers,
automatic refresh, goal switching, all goals, tooltip with the other character, recipe import
button, position after `/reload`, Escape and X, combat. SavedVariables: `settings.window` =
CENTER 150/49 (position saved), recipe `item:2862` imported via the button. `!BugGrabber.lua`:
no errors (session 27). Not tested: `/bof perf` (added after this test).

### Performance review (2026-10-18, before 0.2.0-alpha.5)

| Item | Finding | Action |
|---|---|---|
| Event dispatch | created an argument table and two closures per handler and event | reused contexts per nesting depth; measured: 10000 bag events now allocate a constant ~2.5 KB instead of ~1 KB per event |
| Trace messages | strings built for every event even with debug off | built only in debug mode |
| Stock snapshot on `BAG_UPDATE_DELAYED` | new tables per event (tracked list per character, snapshot tables) | reused scratch set, snapshot tables updated in place |
| `OnUpdate` / tickers | none | – |
| Events while idle | `BAG_UPDATE_DELAYED`, bank, profession window open/close (rare, cheap) | window events only while shown |
| Window | refresh coalesced to one per frame, only while visible; frames created once | – |
| `UpdateAddOnMemoryUsage` | expensive (walks all addons) | only on `/bof perf`, at most every 15 s |

In-game smoke test of 0.2.0-alpha.5 (after the refactoring): confirmed by the user ("passt");
SavedVariables: `lastAddonVersion = 0.2.0-alpha.5`, goal "Perftest" with items 6948, 2589, 159;
`!BugGrabber.lua`: no errors (session 30).

`/bof perf` in game (Classic Era 70003, 2026-10-18, reported by the user; window state not stated):

| Metric | Value |
|---|---|
| Memory | 259 KB |
| Share of frame time, peak | 0.13 % |
| Share of frame time, recent / average | not reported |
| Recount time | not reported |

The addon profiler was active (a share was shown). Target "idle CPU effectively zero" is consistent
with a peak of 0.13 %; a longer-session memory check is still open.

### Result 0.2.0-alpha.6 (Classic Era, 2026-10-18)

Characters: `CharA-RealmA` (Alliance; Mining, Blacksmithing) and
`CharC-RealmB` (Horde, other realm; Tailoring, Enchanting). The user reported "all tests
passed", including the auction scan, the craft window (enchantment goal named after the
enchantment, plan Q-T4) and two open profession windows.

| Check | Evidence | Result |
|---|---|---|
| Own price, unit check | SavedVariables (CharA): `prices["RealmA-Alliance"][2840].MANUAL = 120` | passed |
| Merchant price | SavedVariables (CharA): `[2880].MERCHANT = 100` (Weak Flux, 1s) | passed |
| Auction price, auction scan, tooltip, `/reload` | confirmed by the user | passed (user report) |
| Enchanting recipe import, name, two windows | confirmed by the user | passed (user report) |
| Lua errors | `!BugGrabber.lua`: no errors (session 33) | passed |

Update after the 0.2.0-alpha.7 test (SavedVariables 21:20): CharC has goals from enchantments
(`spell:7779`, `spell:13378`) and tailoring (`item:5762`, `item:4238`); the last two were created
6 s apart (tailoring, then enchantment), matching the checklist. `prices["RealmB-Horde"]` exists,
separate from `RealmA-Alliance`. `!BugGrabber.lua`: no errors.

Note: the earlier SavedVariables write (21:07) was older than CharC's tests (CharC's stock snapshot
predates his goal), so CharC's prices and the enchantment goal are not in the file yet. Those
results rest on the user's report only.

User feedback: with two open profession windows, the recipe that was **clicked last** should be
used, not the one of the window opened last (changed in 0.2.0-alpha.7).

### Result 0.2.0-alpha.8 (Classic Era, 2026-10-18)

Character `CharC-RealmB` (Horde, Tailoring/Enchanting), linen cloth from humanoids.

| Check | Evidence | Result |
|---|---|---|
| Looted items confirmed | saved run: linen cloth 7 and three other items, all confirmed | passed |
| stop → save, list, estimate goal | `farmRuns[2]` saved, no `currentRun` left, goal "Stofftest" created | passed |
| Lua errors | `!BugGrabber.lua`: no errors | passed |
| Travel/farm split | saved run: 10 s farm time, 300 s travel; the run stayed in travel mode while farming | **usability finding** |
| Unclear gains, keep | no unclear gains in the saved run | not performed |
| Logout pause | not in the data | not performed |

Finding: the travel toggle is easy to leave in the wrong mode, and the status line said "läuft" for
farming. 0.2.0-alpha.9 prints "Jetzt: Anreise …" / "Jetzt: Farmen …" after every toggle and calls the
farming state "farmt".

Retest with 0.2.0-alpha.9 (SavedVariables 21:53): saved run 3 = mobs, target linen cloth, 66 s farm
time, 20 s travel, linen cloth 6 + 1 other item, location changed on arrival (uiMapID 1454 -> 1411).
The split is now plausible. Unclear gains/keep and the logout pause were reported as tested by the
user but leave no trace in this data (no kept unclear item, no paused run) -> user report only.
`!BugGrabber.lua`: no errors.

User remark: players rarely use `/reload`. SavedVariables are written by the client on logout, exit
and `/reload` only; an addon cannot trigger it. `/reload` at the end of a test is only needed so the
results can be read from the file. Known limitation (README): after a client crash, changes since the
last save are lost, including a run started in that session.

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

First attempt (2026-10-18) found a bug: snapshots taken on `PLAYER_LOGOUT` stored 0 for every
item (both characters stored 0 hearthstones although each had one), so other characters always
showed "Twinks 0". Logout snapshots were removed; `/bof stock` now also stores a snapshot.

Uses the hearthstone (item 6948), which every character has.

1. Main character: `/reload`, `/bof goal add 6948 5` (in a goal), `/bof stock`.
2. Alt on the same realm: log in, `/bof stock` (stores its snapshot; "no goal selected" is fine), log out.
3. Main character: `/bof stock` → "Ruhestein: benötigt 5, Taschen 1, Bank 0, Twinks 1 – fehlt 3" and
   "    <Alt>: 1 (Taschen 1, Bank 0, Stand vor …)".
4. `/bof stock others` → off, `/bof stock` → "fehlt 4" without "Twinks"; `/bof stock others` again → on.
5. If available: an alt of the other faction on the same realm → listed with
   "andere Fraktion, nicht mitgezählt". An alt on another realm → not listed.
6. `/bof goal remove 6948` to clean up.

### Checklist 0.2.0-alpha.3 (Classic Era, recipe import)

Needs a character with a crafting profession; Enchanting additionally tests the craft window.

1. `/reload`, `/bof version` → `0.2.0-alpha.3`; `/bof` shows 8 help lines including `/bof recipe`.
2. `/bof recipe` without a profession window → "Öffne zuerst ein Berufsfenster …".
3. Open a profession (e.g. Tailoring), click a header line, `/bof recipe` → "… (keine Überschrift)".
4. Click a recipe (e.g. a linen item), `/bof recipe 3` → "Ziel n „[Item]“ aus dem Rezept angelegt:
   k Zutaten, 3× herstellen." The item name is a link (may be "Gegenstand <id>" if not cached yet).
5. `/bof stock` → the reagents of the recipe with need = count × 3 and correct bag/bank counts.
6. Compare the reagents and counts with the recipe in the window (report differences).
7. Enchanting (if available): open it, click an enchantment, `/bof recipe` → goal named like the
   enchantment (spell name). Report whether the name was the enchantment or a placeholder
   "Rezept <id>" (plan Q-T4).
8. With both windows open (e.g. Enchanting and Tailoring): `/bof recipe` uses the one opened last.
9. `/reload`, `/bof goal` → the recipe goals are listed with the recipe name.
10. Errors: `/bof recipe 0`, `/bof recipe abc` → message about the number of crafts.

### Checklist 0.2.0-alpha.4 (Classic Era, main window)

1. `/reload`, `/bof version` → `0.2.0-alpha.4`; `/bof` shows 9 help lines including `/bof show`.
2. `/bof show` → window "Kaufen oder farmen?" in the middle of the screen. Header "Ziel n von m: … – k×
   herstellen", columns Material, Bedarf, Taschen, Bank, Twinks, Fehlt; icons and item names.
   Umlauts correct, no text cut off or overlapping (report what looks wrong).
3. Numbers match `/bof stock`. "Fehlt" is red above 0, green at 0.
4. Move an item of the goal between bags or buy/sell one → the window updates by itself.
5. `<` / `>` switch the goal (also in `/bof goal` the `*` moves). "Alle Ziele zusammen" shows all.
6. Mouse over a row → item tooltip, below it the lines for other characters (e.g. CharB).
7. Open a profession window, select a recipe, click "Rezept übernehmen" → chat message, new goal shown.
8. Drag the window elsewhere, `/reload`, `/bof show` → same position. Escape closes it; the X too.
9. In combat: open/close the window and click buttons → no error, no "Aktion blockiert".
10. `/bof goal add <Item> 1` while the window is open → new row appears.
11. Performance: with the window closed nothing should happen; report anything unusual.

### Checklist 0.2.0-alpha.6 (Classic Era, prices)

Goal with a vendor reagent and a cloth, e.g. `/bof goal new Preistest`, `/bof goal add 2320 2`
(Grobes Garn, sold by tailoring vendors), `/bof goal add 2589 5` (Leinenstoff).

1. `/reload`, `/bof version` → `0.2.0-alpha.6`; `/bof show` → column "Preis/Stück" with "–".
2. `/bof price 2589 1s 20k` → "eigener Preis 1s 20k pro Stück gespeichert"; window shows 1s 20k.
   `/bof price 2589 120` → message about the unit.
3. Open a merchant that sells Grobes Garn (no need to buy) → window: price of Grobes Garn appears;
   `/bof price` → "… (Händler)". Compare with the merchant's price per piece.
4. Auction house: search "Leinenstoff" yourself → price "(AH, gerade eben)"; compare with the
   cheapest buyout per piece on the first page.
5. Auction house: click "AH-Scan" in the window (and `/bof price scan`) → chat "suche …"; the AH shows
   the search, the price updates. Clicking again after all missing items were searched → "schon gesucht".
   Report whether the search worked or the client blocked it.
6. Close the AH → "AH-Scan" is disabled. Mouse over a row → tooltip lists all price sources.
7. `/bof price 2589 clear` → own price removed.
8. `/reload` → prices kept. BugSack: no errors.

### Checklist 0.2.0-alpha.7 (Classic Era, last selected recipe)

1. `/reload`, `/bof version` → `0.2.0-alpha.7`.
2. Open Enchanting and Tailoring. Click a recipe in Tailoring, then one in Enchanting,
   `/bof recipe` → goal from the enchantment.
3. Click a recipe in Tailoring again (Enchanting stays open), `/bof recipe` → goal from the tailoring recipe.
4. Close Tailoring, `/bof recipe` → enchantment again.
5. `/reload` (so the results are saved), BugSack: no errors.

### Checklist 0.2.0-alpha.8 (Classic Era, farm runs)

CharA (Mining) near copper veins, e.g. Dun Morogh. One command per line.

1. `/reload`, `/bof version` → `0.2.0-alpha.8`.
2. `/bof farm travel` without a run → "Keine Farmrunde".
3. `/bof farm start gather 2770` → "Farmrunde gestartet (Sammeln, <Zone>)". `/bof farm travel`, ride to
   the veins, `/bof farm travel` again (arrival).
4. Mine 2–3 veins (with and without autoloot if possible). `/bof farm` → copper ore and rough stone
   "geplündert", times plausible.
5. `/bof farm pause`, wait a minute, `/bof farm resume` → farm time did not grow during the pause.
6. Take something from the mailbox or bank, or buy an item → `/bof farm` shows it as "unklar".
7. `/reload` during the run → `/bof farm` still "läuft", times continue.
8. `/bof farm stop` → review hint. `/bof farm keep <item>` for one unclear item, `/bof farm save`.
9. `/bof farm list` → the run. Goal with copper ore: `/bof goal new Erztest`, `/bof goal add 2770 40`,
   `/bof farm estimate` → estimate with "aus 1 Runden".
10. Optional: start a run, log out, log in after a few minutes → `/bof farm` "pausiert", the offline
    minutes are not counted. `/bof farm discard`.
11. `/bof perf` during a run (memory) and BugSack: no errors. `/reload` at the end.

### Checklist 0.2.0-alpha.10 (Classic Era, sourcing plan)

CharC: goal "Stofftest" (40 linen cloth, farm runs with linen exist). One command per line.

1. `/reload`, `/bof version` → `0.2.0-alpha.10`; `/bof` lists `/bof plan`, `/bof strategy`, `/bof budget`.
2. Add a second material with a price, e.g. `/bof goal add 2320 5` and `/bof price 2320 10k`;
   set a linen price, e.g. `/bof price 2589 50k`.
3. `/bof plan` → header with strategy and budget (your gold), one line per missing material
   (buy/farm amounts), sum line, time value note.
4. `/bof budget 10s` → `/bof plan`: with the small budget part of the linen is bought, the rest farmed.
   `/bof budget clear`.
5. `/bof strategy gold` → `/bof plan`: linen farmed (there are runs), thread bought (no runs).
   `/bof strategy farm` → nothing bought, thread "offen".
6. `/bof show` → tabs "Material" and "Beschaffung" at the top left; the title is not covered.
   "Beschaffung": strategy buttons (active one greyed), budget, table, sum. Click the strategies.
7. Spend or receive a little gold with the tab open → the plan updates.
8. Mouse over a row → price per piece and farm time for all of it.
9. Close and reopen the window → the last tab is shown again. `/reload` at the end; BugSack empty.
