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
| 1c | cleanliness and performance (`work/tools/lua_static.py`): every `OnUpdate` script and ticker has `-- PERF-OK:` and is named in ARCHITECTURE.md; `CreateFrame` only at file level or in create/build functions; no magic numbers in `Core/` and `Adapters/` (0, 1, 2 allowed; constants are UPPER_SNAKE); functions at most 40 lines and nesting 3; files at most 300 lines (locale files excluded: one string per line, data) |
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
| 0.11.0 | 2026-10-23 | 303 checks passed, 0 failed; release build of 0.11.0-alpha.17 (alphas 5–17: keep list icons, about/how-to/help topics, minimap button, wants "Alle/Neu", tooltip recipe lines, profession read date, enchanting products by name, reagent toggle) |
| 0.11.0-alpha.4 | 2026-10-23 | 297 checks passed, 0 failed; new tests: automatic farm start (not resting, target from missing loot, any loot, setting off), crafts on alts (task on the alt, plan text, not when known by the character), price history and resale (daily lows, units at the lowest price, median of earlier days, gain after the cut, stale listing, comparison line, pruning) |
| 0.11.0-alpha.3 | 2026-10-23 | 294 checks passed, 0 failed; new tests: route cache (reuse, copy, rebuild on a saved run, a signal and age), mailbox stock (only read at the mailbox, attachments summed, gold in mail, own count, account total, taken mail removed) |
| 0.11.0-alpha.1 | 2026-10-23 | 292 checks passed, 0 failed; new `test_strategies.lua` (gold per character, account rows and `/bof account`, fishing detection and fishing routes, crafted routes, comparison ranking and missing families, `/bof compare`, planner views) |
| 0.10.0-alpha.1 | 2026-10-23 | 284 checks passed, 0 failed (266 unit tests); new `test_acquire.lua` (planner: stock first, buy vs. craft, recursive reagents, sale value of stock, hour value and ties, open items, shared pool, cycles) and `test_wants.lua` (model, validation, migration 1 -> 2, `/bof want`, plan with alts' stock and recipes, cache); farm, window, hints, advisor, gold and recipe tests rewritten for wants, the farm window and routes; sourcing, material input, alternatives and quest tests removed with their features |
| 0.9.0-alpha.1 | 2026-10-23 | 324 checks passed, 0 failed (306 unit tests); 8 new tests in `test_make.lua` (craft counts, crafting in the open window with cap and "all", opening a closed or other window, combat/no reagents/unknown/enchantment refused, collapsed categories, smelting spell for Mining, detail buttons); mutation check: crafting in another profession's window fails 1 |
| 0.8.0 | 2026-10-23 | 316 checks passed, 0 failed (298 unit tests); against 0.8.0-alpha.1: skill bar guard (with test; mutation check: removing the guard fails 1) and the fix for the user's in-game finding (linen bolt showed a loss because owned reagents counted at their buy price; now at their sale value after the cut, like `CraftTasks`; the new test fails without the fix), version and documentation |
| 0.8.0-alpha.1 | 2026-10-23 | 315 checks passed, 0 failed; 14 new tests in `test_professions.lua` (book with profession/difficulty/skill, smelting as mining, enchantments kept, categories from facts, effect data keys, labels, grouping, reagent filter, search, economics, sanitizing, tab list/collapse/detail/filter/search, goal button, gear by stats); layout test includes the new tab; level 1c exempts `Data/` from the file length (data tables) |
| 0.4.0-alpha.2 | 2026-10-19 | 226 checks passed, 0 failed (208 unit tests); new layout test: every button label must fit its button (6.4 px per character + 4 px, calibrated on the in-game screenshot); it flagged the two overflowing labels, fixed by shorter texts |
| 0.4.0-alpha.1 | 2026-10-19 | 225 checks passed, 0 failed (207 unit tests); new tests per stage of the player relief plan; mutation checks: no sanitizing of alternative details fails 1, loot grace before merchant window in the farm capture fails 1; tests found and fixed: editable rows in the all-goals view, `Settings.Set` returning `false` for "off", read-only `false` run in `FarmAssist`, loot grace winning over an open merchant window (income sources and farm capture) |
| 0.3.0 | 2026-10-19 | 175 checks passed, 0 failed (157 unit tests); only version and documentation changed against 0.3.0-alpha.3 |
| 0.3.0-alpha.3 | 2026-10-19 | 175 checks passed, 0 failed (157 unit tests); mutation check: no sanitizing of alternative details fails 1 |
| 0.3.0-alpha.2 | 2026-10-19 | 172 checks passed, 0 failed (154 unit tests); new level 1b check for characters the game font draws (fails on the old `→` texts); the new stacking checks in the Craft and Gold tab tests fail without the fix |
| 0.3.0-alpha.1 | 2026-10-18 | 169 checks passed, 0 failed (152 unit tests); gold buffer mutation checks: ignoring the gold limit, no login guard, reserves ignored, no gap cap each fail 1; farm tab mutation checks: no ticker cancel on hide, ticker while paused each fail 1; mutation checks: strongest instead of weakest ring, no two-hand sum, ignoring weights, owned not capped (after adding a test) each fail 1–2 |
| 0.2.0 | 2026-10-18 | 146 checks passed, 0 failed (129 unit tests); only version and documentation changed against 0.2.0-alpha.10 |
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
| 0.2.0-alpha.10 | Classic Era 1.15.9 (70003), deDE | 2026-10-18 | **passed** (details below) |
| 0.3.0-alpha.1 | Classic Era 1.15.9 (70003), deDE | 2026-10-19 | **passed (partly)**, two display bugs (details below) |
| 0.3.0-alpha.2 | Classic Era 1.15.9 (70003), deDE | 2026-10-19 | **passed**: Craft tab lines no longer overlap, "Unterschied" instead of the box (user: "Passt") |
| 0.3.0-alpha.3 | Classic Era 1.15.9 (70003), deDE | 2026-10-19 | **passed**: user "done"; SavedVariables (11:45) show `lastAddonVersion` 0.3.0-alpha.3 and alternative 2 with `copper` 15000, `seconds` 5400, `requires` "Stufe 20" after `/reload`; `!BugGrabber.lua`: no new errors |
| 0.4.0-alpha.1 | Classic Era 1.15.9 (70003), deDE | 2026-10-19 | **passed (partly)**: user "Alles gut bis auf das hier" – template button labels overlapped in the Craft tab (screenshot); SavedVariables (12:59): `lastAddonVersion` 0.4.0-alpha.1, `lastSession` stored; no `bySource` yet (no data trace for income sources); `!BugGrabber.lua`: no new errors |
| 0.4.0-alpha.2 | Classic Era 1.15.9 (70003), deDE | 2026-10-19 | **passed**: template and kind buttons no longer overflow (user: "Passt") |
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
predates the goal), so CharC's prices and the enchantment goal are not in the file yet. Those
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

### Result 0.2.0-alpha.10 (Classic Era, 2026-10-18)

Character `CharC-RealmB`. Confirmed by the user ("passt"); SavedVariables (22:24):
`settings.window.tab = "SOURCING"` (tab remembered), `settings.strategy = "FARM_SELF"` (last
strategy of the checklist), `settings.budgetCopper = 0` (own budget cleared), own prices for coarse
thread (10k) and linen cloth (50k) next to the merchant and auction prices. `!BugGrabber.lua`: no
errors.

User feedback during the test: the table's farm time (with travel) and the tooltip's farm time for
everything (without travel) differed without explanation. Fixed in the same version: the tooltip
splits farm time and travel for the planned part and for the whole amount.

### Result 0.3.0-alpha.1 (Classic Era, 2026-10-19)

Character `CharC-RealmB` (Tailoring). User: everything matched the checklist except one display
problem (screenshot of the Craft tab). SavedVariables (11:26) and `!BugGrabber.lua`:

| Check | Evidence | Result |
|---|---|---|
| Lua errors | `!BugGrabber.lua`: only the old entry from a manual `/dump C_Item.GetItemStats(...)` (session 44, function does not exist in Classic Era); nothing from the addon | passed |
| Recipe goal (step 2) | recipe `item:6242` imported, goal 11 | passed |
| Craft evaluation, weights (steps 3–4) | user confirmed; weights back to 1 | passed |
| Alternatives (step 6) | old planned alternative removed, `POSSIBLE` 4338 stored | passed |
| Craft tab (step 7) | screenshot: comparison names the slot ("Brust"), goal navigation shown | passed, but see bugs |
| Farm tab (step 9) | user confirmed (tested on 2026-10-18; the runs of 22:06–22:16 in `farmRuns`) | passed |
| Gold buffer (step 10) | savings goals "Reiten" 5g and "Training" 1g, each fully `reserved` | passed |
| Income (step 11) | session 20745: 1019 s, gained 0, spent 0: no fake gain at login. Selling/repairing: user confirmed (tested on 2026-10-18), no gold change in the stored income records | passed (user) |
| Help tab, window width (steps 1, 12) | user confirmed | passed |

Bugs found (screenshot):
1. Craft tab: the alternative line wrapped to two lines and overlapped the limits line. Cause: fixed
   line offsets. Fixed in 0.3.0-alpha.2 (`Widgets.CreateTextStack`, also used for the Gold tab goals).
2. "→" in the comparison line rendered as a box: the Classic Era font has no U+2192. Fixed in
   0.3.0-alpha.2 (text says "Unterschied"); level 1b now rejects characters outside the verified set.

### Checklist 0.11.0-alpha.4 (Classic Era, automatic farm start, alt crafts, resale)

1. `/reload`, `/bof version` → `0.11.0-alpha.4`. BugSack empty. Settings tab: new check box
   "Farmrunde beim Looten automatisch starten" fits.
2. In a city loot something (e.g. a quest item or a chest in an inn): no run starts. Outside, kill and
   loot a mob: the farm window opens with a running run. Stand still for the idle time: the run ends.
3. Log in an alt with a profession window opened once, then the main: "Goldplaner" → "Plan"/"Vergleich"
   may list "… – auf <Alt> (Zutaten per Post)" when that recipe makes a profit.
4. Resale needs AH searches on 3 different days for the same item; then a clearly cheaper listing
   shows "Im AH kaufen und neu einstellen" in "Vergleich". On day 1 the comparison names the
   missing data ("im AH an mindestens 3 Tagen suchen").
5. `/bof perf` after browsing several AH pages.

### Checklist 0.11.0-alpha.3 (Classic Era, mailbox stock, route cache)

1. `/reload`, `/bof version` → `0.11.0-alpha.3`. BugSack empty.
2. Send an alt some items and gold, log in the alt, open the mailbox, do not take anything: the tooltip
   of a wanted item shows "Post n"; `/bof account` shows "(+ … in der Post)". Take the mail: the count
   moves from Post to Taschen.
3. Advisor window open while looting for a minute, then `/bof perf`: peak lower than the 7.54 % of 0.8.0.
4. Then the checklist 0.11.0-alpha.1 below.

### Checklist 0.11.0-alpha.1 (Classic Era, strategy comparison, account, fishing)

1. `/reload`, `/bof version` → `0.11.0-alpha.1`. BugSack empty.
2. `/bof account` → header with the gold of the characters on the realm; this character with its
   gold (matches the bag display), professions with skill and recipe count. Log an alt in and back:
   the alt appears with its gold.
3. Tab "Goldpuffer" → "Goldplaner": buttons "Plan", "Vergleich", "Konto" fit; "Vergleich" lists the
   strategies with "gewertet …", the last line "Ohne Daten: …"; 1/2/4 h change the numbers. "Konto"
   shows the account lines; "Plan" brings the old view back.
4. Fishing: start a farm run, fish a few times (5+ catches), stop → tab "Farmen" shows
   "<Zone> (Angeln)" as its own row. Check `/dump IsFishingLoot()` while a fishing loot window is
   open → `1` or `true` (unverified API return).
5. With a learned recipe whose product sells better than its reagent (e.g. linen → bolt with an AH
   price for the bolt) and a farm route that loots the reagent: "Vergleich" shows "Farmen, Beute
   verarbeiten, verkaufen" and the plan line "…, verarbeitet zu …".
6. `/bof perf` with the planner open on "Vergleich".

### Checklist 0.10.0-alpha.1 (Classic Era, wants, stock, farm window)

Before: back up `WTF/.../SavedVariables/BuyOrFarmForever.lua` (the migration rewrites the goals).

1. `/reload`, `/bof version` → `0.10.0-alpha.1`. BugSack empty. Chat: no repair warnings beyond the
   migration. Tabs: Ziele, Farmen, Berufe, Goldpuffer, Einstellungen, Hilfe.
2. Tab "Ziele": the old goals appear as wants (recipe goal → its product). Add Leinenstoffballen x5 via
   the slot: the tree shows "herstellen: 5×" with Leinenstoff below (hast du / kaufen / farmen), the
   summary lines and the hour value line.
3. Tooltip of a tree row with stock: "Du: Taschen n, Bank n" and the alts with their stand.
4. Click "Herstellen" in the tree: tailoring window opens (first click) / crafts (second click).
5. Bank: open and close the bank once, then `/reload`; a want covered by bank items shows "hast du".
   Log an alt in, wait 15 s, log the main in: the alt's bags count in the tooltip.
6. Farm: `/bof farm` opens the small window; Start → status line counts; Beenden → "Farmrunde
   gespeichert (nur Beute zählt)." and a row in tab "Farmen" with gold per hour. Right click on the
   minimap button opens the window / pauses.
7. Settings tab: weight boxes and "Vorschlag" at the bottom; "1 Std. Farmen ist wert" box; `/bof set
   hourValueGold 2` changes the hour value line in "Ziele".
8. `/bof perf` idle and with "Ziele" open; `/bof want` in chat.
9. Advisor at the merchant / bank: cards name items of the wants; sell suggestions leave wanted items
   and their reagents out.

### Checklist 0.9.0-alpha.1 (Classic Era, crafting from the professions tab)

1. `/reload`, `/bof version` → `0.9.0-alpha.1`. BugSack empty.
2. Tab "Berufe", Tailoring, select Leinenstoffballen with linen in the bags: bottom row "[1] Herstellen ·
   Alle: n · Stapel: n"; "Als Ziel anlegen" now right of "Zutaten".
3. Profession window closed: click "Herstellen" → the tailoring window opens, chat asks for a second click,
   no error message. Click again → 1 bolt is crafted.
4. Box "3" + Enter or "Herstellen" → 3 crafts; "Alle" → as many as the linen allows; moving cancels.
5. Cooking window open, then "Herstellen" on a tailoring recipe → the tailoring window replaces it.
6. In combat: "Im Kampf kann nichts hergestellt werden."; no "action blocked" message anywhere.
7. Enchanting recipe: no craft buttons, hint text instead.
8. Collapse a category in the tailoring window, then craft a recipe from it → it still works.
9. Experiment for a later single-click flow (only if you like): open the tailoring window, select the bolt,
   then `/run C_Timer.After(2, function() DoTradeSkill(GetTradeSkillSelectionIndex(), 1) end)` and wait 2 s.
   Report whether a bolt is crafted or an "action blocked"/"Interface action failed" message appears.

### Facts 0.8.0-alpha.1 (Classic Era 1.15.9, deDE, 2026-10-23, screenshots of the user)

- `GetTradeSkillLine()` with the window open: `"Kochkunst", 178, 225` and `"Schneiderei", 142, 225`.
- `GetCraftDisplaySkillLine()` with the enchanting window open: `"Verzauberkunst", 110, 150`.
- `C_TradeSkillUI.GetTradeSkillDisplayName(185)` = `"Kochkunst"`: exists in Classic Era and returns the same
  name as the window, so profession recognition by skill line id works (confirmed for Cooking).
- `GetTradeSkillLine()` without an open window: `"unknown", 0, 0`. The adapter reads skill lines only while
  a window is open.
- Smelting/Mining: not checked (the test character has no Mining).

### Performance review 0.8.0 (2026-10-23, before the release)

In game (user, `/bof perf`, Classic Era 1.15.9, after testing the professions tab, window state at the
time of the command not reported): memory 1640 KB; addon share of frame time: recent 0.00 %, average
0.01 %, peak 7.54 %; "Bestand aller Ziele neu berechnen" 1.520 ms (18 items).

Static review of the new and changed handlers (0.7.0 advisor was reviewed in its own stages):
- Professions tab: signals `BAGS_CHANGED`, `ITEM_LOADED`, `PRICES_CHANGED`, `DATA_CHANGED`,
  `RECIPES_CHANGED` only while the tab is shown (refresh mixin, unregistered on hide); refreshes coalesced
  to one per frame. A refresh groups one profession's recipes (a few hundred at most) and fills 15 rows;
  categories are cached per recipe for the session. No `OnUpdate`, no ticker, frames created once.
- `RecipeBook`: unchanged trigger (one `C_Timer.After(1)` per profession window burst); per capture
  additionally one skill line read per open window and one `RECIPES_CHANGED` signal.
- Idle with the window closed: no new per-frame work; average 0.01 % confirms that.

Assessment: the average is effectively zero. The peak (7.54 %) is a single frame since login, far above the
0.13 % measured for 0.2.0. Likely candidates are one-off bursts: the recipe book capture reading every recipe of
a window, or the first tab refresh that computes all categories and requests item data. Not reproduced or
attributed yet. The memory value includes Lua garbage not yet collected; the SavedVariables were last written
on 2026-10-19 (no `/reload` since), so they could not be checked. Follow-up (not blocking the release): measure
the peak after `/reload` with the window closed, then after opening the tab once, and memory after
`/run collectgarbage("collect")`.

### Result 0.8.0 fix: owned reagents (Classic Era, 2026-10-23)

Screenshots of the user (linen bolt, 37 linen in the bags, Auctionator open): lowest listings linen 27,
bolt 62. Tab: "Zutaten: 51k (aus der Tasche zum Verkaufswert)" = 2 x 27 x 0.95 = 51.3; "AH 59k (nach
Gebühr)" = 62 x 0.95 = 58.9; "Gewinn pro Herstellung: 8k" = 7.6; "herstellbar 18x". All values as
expected. Auctionator suggests posting 1 copper below the lowest listing (61 / 26); the addon uses the
lowest listing itself. The auction deposit (8 for the bolt) is refunded on sale and not counted.

### Result 0.8.0-alpha.1 (Classic Era, 2026-10-23)

User checked the professions tab (Cooking, Tailoring, Enchanting, First Aid on the test character) and
confirmed: "Passt soweit!". No details reported on single checklist points. `/bof perf` numbers: see the
performance review above. Not checked: Mining/Smelting, Alchemy, Leatherworking, Blacksmithing, Engineering,
Poisons; the user said to assume they work as well (2026-10-23).

### Checklist 0.8.0-alpha.1 (Classic Era, professions tab)

1. `/reload`, `/bof version` → `0.8.0-alpha.1`. BugSack empty.
2. Facts to report: `/dump GetTradeSkillLine()` with the cooking window open, the same with the
   smelting window open (expected "Bergbau" or "Verhüttung"), `/dump C_TradeSkillUI.GetTradeSkillDisplayName(185)`.
3. Open each profession window once (also Enchanting), then `/bof show` → tab "Berufe": one icon per
   profession (correct icon, tooltip with the number of recipes); name and skill bar match the window.
   No profession ends up under "Sonstige" (question mark icon), except old entries until their window
   was opened.
4. Cooking: groups such as "Ausdauer & Willenskraft", "Stärke", "Beweglichkeit", "Heilung"; names coloured
   like in the window (orange/yellow/green/grey). Click a group header: it collapses ("+"), click again.
5. A gear profession (Tailoring/Leatherworking/Blacksmithing): gear grouped by its largest stat; items
   without stats under "Rüstung & Verteidigung" or "Waffen"; bolts, bars etc. under the client's item class
   (e.g. "Handwerkswaren"). Enchanting: enchantments grouped by stat; nothing cut off.
6. Filter "Teilweise" / "Komplett" with some reagents in the bags; "3×" and "1/2" on the right are
   plausible. The filter is still set after `/reload`. Search: type part of a name; umlauts work.
7. Detail: icon tooltip, reagent lines (bags/need, "+n in der Bank"), costs, value, profit; "Als Ziel
   anlegen" creates a goal (tab "Material"), a second click increases it.
8. Mouse wheel scrolls a long list; nothing overlaps (screenshot welcome), the 8 tab buttons fit.
9. `/bof perf` with the tab closed and open; report the numbers.

### Result 0.7.0-alpha.6 (Classic Era, 2026-10-19)

User confirmed the alpha.4 to alpha.6 checklists ("jap"). Files: `!BugGrabber.lua` has no error from
this addon (only an old `/dump` typo of session 44). The SavedVariables (written 19:41) still show
`lastAddonVersion` 0.7.0-alpha.4, so they were saved before alpha.5/6 were loaded.

### Checklist 0.7.0-alpha.6 (Classic Era, farmed reagents)

1. `/bof version` → `0.7.0-alpha.6`. Checklists 0.7.0-alpha.5 and alpha.4 below still apply.
2. A recipe whose reagent has no price but was farmed in a measured run (or dev samples via
   `/bofdev seed`): Herstellen names it with "Zutaten farmen"; tooltip "Zutaten farmen: etwa …".

### Checklist 0.7.0-alpha.5 (Classic Era, craft values)

1. `/bof version` → `0.7.0-alpha.5`. Checklist 0.7.0-alpha.4 below still applies.
2. Profession character with a profitable recipe: Herstellen shows "Gewinn bis …"; the tooltip shows
   per recipe "Händler … · AH … · Zutaten …".
3. Put the reagents for 2 crafts in the bags: "Herstellen: 2× …", "Zutaten vorhanden".
4. A cooldown recipe (e.g. transmute) on cooldown: tooltip "Abklingzeit …: in …".
5. A goal from a recipe this character has not learned: no "Ziel: alles da" in Herstellen.

### Checklist 0.7.0-alpha.4 (Classic Era, advisor rows)

1. `/reload`, `/bof version` → `0.7.0-alpha.4`. BugSack empty.
2. `/bof advisor`: rows in this order: Verkaufen, Entzaubern (enchanter only), Herstellen, Sparziel,
   Deine beste Stunde. Empty rows grey with a reason. Nothing cut off.
3. Verkaufen: "Händler: x · AH: y"; tooltip lists both. At a merchant a click sells only the vendor
   list (buyback tab).
4. Enchanter with Auctionator and a green item: Entzaubern row; tooltip "(+… ggü. Verkaufen)".
   At the merchant the side card "Nicht verkaufen – entzaubern"; the item is not in the sell list.
5. Profession character (open the profession window once): Herstellen names a recipe; with the
   reagents in the bags "Zutaten vorhanden"; tooltip lists further recipes. Without prices:
   "Rezepte ohne Preis: n – scannen".
6. Click on Sparziel → Gold buffer tab; click on Deine beste Stunde → planner.

### Result 0.7.0-alpha.3 (Classic Era, 2026-10-19)

User: the narrow window is fine, but asked whether things were left out: profitable crafts from the
recipe book and disenchanting were not shown as own suggestions (crafts only inside the best hour,
the disenchant card dropped out of the 4 cards). User decision: fixed rows sell, disenchant (if
possible), craft, savings goal, best hour → 0.7.0-alpha.4.

### Result 0.7.0-alpha.2 (Classic Era, 2026-10-19)

Screenshot of the user: the advisor window still too wide (long checkbox labels) and every card
shown twice without an open window – `Advisor.Collect` ran the ANY sources a second time for the
context "ANY". 0.7.0-alpha.3: fixed (regression test), window width 300, clickable cards without
buttons, short checkbox labels (width test).

### Result 0.7.0-alpha.1 (Classic Era, 2026-10-19)

User: everything works ("Der rest ist perfekt"), but the advisor window is far too big. 0.7.0-alpha.2:
4 cards instead of 6, height follows the shown cards, width 380, scale 0.85; test added.

### Checklist 0.7.0-alpha.1 (Classic Era, advisor)

1. `/reload`, `/bof version` → `0.7.0-alpha.1`. BugSack empty.
2. Shift+click on the minimap button (or `/bof advisor`): window "Ratgeber" with cards (stripe,
   icon, title, gold line, grey line); hover shows the item or the item list. Nothing cut off.
3. Merchant: cards "Mach hier:" right of the merchant window. "Verkaufen" asks, then sells the list
   (check with the merchant's buyback tab). A missing goal material the merchant sells: "Kaufen"
   asks, then buys (whole merchant stacks).
4. Close the merchant during selling → stops with a message.
5. Bank with goal materials: card "Mitnehmen …". Mailbox on a character whose materials another
   character's goal needs: "An <Name> …". Auction house: purchases of the plan, "Scannen".
6. Full bags (<= 3 free) and logging in → the advisor opens by itself after a few seconds.
7. The two checkboxes at the bottom of the advisor switch the side cards and the login opening.
8. In combat: no errors when cards appear (merchant cannot be open in combat anyway).

### Result 0.6.0-alpha.2 (Classic Era, 2026-10-19)

User: new savings goal works again; everything else of the checklist passed ("Passt alles"). Farm
routes (`/bof goldsources`, planner, "Anderer Weg") were tested with the sample runs of the
developer addon `work/dev/BuyOrFarmForever_Dev` (`/bofdev seed`), not with real farm runs: the
looted-coin capture of real runs is covered by unit tests only.

### Release check 0.6.0 (2026-10-19)

| Step (CLAUDE.md section 9) | Result |
|---|---|
| Checks levels 0, 1, 1b, 1c, 2 | 275 passed, 0 failed (255 addon tests + 2 developer-addon tests) |
| In-game test (Classic Era) | 0.6.0-alpha.1 (spell and Auctionator checks; two findings) and 0.6.0-alpha.2 (all items) passed; 0.6.0 = 0.6.0-alpha.2 code |
| In-game test (Forever) | none – the release must not be called Forever-compatible |
| Version in TOC, CHANGELOG, README | 0.6.0 |
| Interface version | 11509 = client 1.15.9 (70003), unchanged |
| ZIP | built and inspected: top folder `BuyOrFarmForever/`, no dev files, developer addon not included |
| Performance | static review below; in-game `/bof perf` not measured for 0.6.0 |
| Tag | `v0.6.0`, only after the user's approval |

### Performance review before 0.6.0 (2026-10-19, static)

New handlers: `RecipeBook` on profession window events (always registered; one 1 s timer per burst,
then one read of the visible recipes); looted coins added in the existing `MONEY_CHANGED` handler
(one number). The Gold buffer tab adds `BAGS_CHANGED`, `PRICES_CHANGED`, `ITEM_LOADED` only while
shown; the planner view recomputes bag tasks (one bag pass, ~100 slots), craft tasks (recipe book,
at most 500 recipes) and routes (at most 500 runs, values cached per item) once per coalesced
refresh. No `OnUpdate`, no ticker. Verdict: ok.

### Result 0.6.0-alpha.1 (Classic Era, 2026-10-19, partial)

Reported by the user: `C_SpellBook.IsSpellKnown(13262)` = true on an enchanter (Disenchant spell ID
confirmed); `Auctionator.API.v1.GetDisenchantPriceByItemID("Test", 9515)` = 4874 (function present).
Bugs: (1) the "Neu" row of the Gold buffer tab lost the typed name/amount on focus loss, so
"Anlegen" did nothing – input boxes restored their shown value on focus loss; fixed with draft boxes
(`opts.draft`) for form fields (also purchase check and the Material tab count boxes), regression
test added. (2) the keep list was not visible – the planner now labels the slot and names the kept
items. Both in 0.6.0-alpha.2.

### Checklist 0.6.0-alpha.1 (Classic Era, gold planner)

1. `/reload`, `/bof version` → `0.6.0-alpha.1`. BugSack empty.
2. `/dump C_SpellBook.IsSpellKnown(13262)` (true on an enchanter, false otherwise) and, with
   Auctionator, `/dump Auctionator.API.v1.GetDisenchantPriceByItemID("Test", <green item id>)`.
3. Farm run with mobs (loot coins), save it: `/bof goldsources` shows the route "Gegner in <zone>"
   with gold per hour (sure includes the coins). Runs from before 0.6.0 are marked "ohne Beutegold".
4. Gold buffer tab: buttons "Goldpuffer" / "Goldplaner" top right; "Einkauf prüfen" now right of the
   goal header; nothing overlaps. "Goldplaner": time buttons, duration box `1h 30m`, steps, routes.
5. Bags with greys, a green item and stackable materials: steps "Beim Händler verkaufen", "Im AH
   einstellen", (enchanter) "Entzaubern …". Drag an item onto the keep slot → no longer suggested.
6. Open a profession window: `/bof goldplan` lists profitable crafts ("Herstellen und verkaufen")
   when the product and reagents have prices; a recipe with a cooldown appears once ready.
7. `/bof goldplan` without duration: plans for 1, 2 and 4 hours.

### Result 0.5.0-alpha.1 (Classic Era, 2026-10-19, partial)

Reported by the user: Auctionator prices work. `GetItemStats` of the main hand returns
`ITEM_MOD_DAMAGE_PER_SECOND_SHORT=22.954545974731` (DPS key confirmed). Bug: the Sourcing tab had no
goal arrows; fixed in 0.5.0-alpha.2 (shared `Widgets.CreateGoalNavigation`, test added). 
0.5.0-alpha.2: the user confirmed "Passt alles" for the whole 0.5.0 checklist including the arrows
(2026-10-19).

### Checklist 0.5.0-alpha.1 (Classic Era, Auctionator)

1. Without Auctionator: `/reload`, `/bof version` → `0.5.0-alpha.1`; `/bof price` as before, BugSack empty.
2. Install Auctionator, scan at the auction house (full scan or search for the goal materials).
3. `/dump Auctionator.API.v1.GetAuctionPriceByItemID("Test", 2589)` → a number (verify the API).
4. `/bof price` and the Material tab price tooltip show "… (Auctionator, vor …)"; the plan uses it.
5. Settings tab: switch "Preise von Auctionator verwenden" off → the Auctionator price disappears.
6. Sourcing tab: "Zeitlimit" `10m` + Enter → limit line under the list; more is bought if gold allows.
   Empty + Enter clears it. Nine rows, nothing overlaps (route, limit, summary, reserve, time value).
7. After two farm runs with different targets (one not in the goal, at least 10 min): "Anderer Weg"
   line under the plan. Runs that yield two goal materials: "nebenbei" in the row tooltip.
8. Craft tab: seven weight boxes (Stä … DPS) fit in one row; template "Stärke" sets DPS 5.
   `/dump GetItemStats(GetInventoryItemLink("player", 16))` shows whether the DPS key
   `ITEM_MOD_DAMAGE_PER_SECOND_SHORT` exists in Classic Era (verify).
9. Planned alternative for a craft goal → "Bis Alternative … kommt" or "Der Craft bleibt …" line;
   an item above your level shows "tragbar ab Stufe …".

### Checklist 0.4.0-alpha.1 (Classic Era, player relief)

Things only the client can show are marked (verify): they rely on APIs whose details are unverified.

1. `/reload`, `/bof version` → `0.4.0-alpha.1`. `/bof show`: title line above eight tab buttons, nothing
   overlaps. Minimap button visible (verify icon and border textures).
2. Material tab: "Neues Ziel", type a name + Enter, "Herstellungen" 2 + Enter. Drag an item from the bags
   onto the slot at the bottom left (verify `GetCursorInfo`), count 3, "Hinzufügen". Shift-click another
   item in the bags while the window is open (verify the link hook), "Hinzufügen". Change a count in a row,
   "x" removes, click the price cell, type `1s` + Enter. "Löschen" asks first. "Twinks mitzählen" toggles.
3. Recipe import with count 2; import the same recipe again → the goal goes to 4 crafts (no second goal).
4. Craft tab: weight box `1,5` + Enter; template buttons; the suggestion names your class role (verify
   talent points). "Alternativen": drag an item, toggle the kind, add; cost `1g`, time `45m`, requirement.
5. Gold tab: new goal (name + amount + "Anlegen"), rename, change the amount, "hoch", "erreicht", "x"
   (asks), "Gold verteilen", "Rückgängig", purchase check `3g`.
6. Sourcing tab: budget box `2g` + Enter, then empty + Enter.
7. Settings tab: switch a few settings, change a number, debug mode, "Leistung anzeigen", "Zurücksetzen"
   (asks).
8. Farm run from the Farm tab (target preselected). `/afk` → paused, back → resumed (verify). Enter a city
   or inn → paused, leave → resumed (verify `IsResting`). Take a flight path → travel, landing → farming
   (verify `UnitOnTaxi`). Stand still 6+ minutes, then loot → the farm time grew by at most 5 minutes.
   Buy something at a merchant during the run → not counted. "Beenden" without unclear gains → saved with
   an "Ergebnis" line.
9. Without a run, loot a material the selected goal misses → bar "Farmrunde starten?"; "Gegner" starts it.
10. Item tooltips (bags, auction house, merchant): goal materials show "fehlt …", crafted goal items show
    "Craft-Ziel, +n" (verify the tooltip hook).
11. Merchant: line under the merchant frame with free gold and reserves; buying into the reserves gives one
    warning. Auction house: hint about materials without a price.
12. A quest with a reward for the slot of an item a goal crafts → bar "Merken" adds it (verify the quest
    reward APIs).
13. Esc → Key Bindings → AddOns: two entries "Kaufen oder farmen?" (verify `Bindings.xml` loading); bind one.
14. Log out, wait over a minute, log in → after about 5 s "Letzte Sitzung …".
15. `/bof gold` → "Quellen" line (loot coins, merchant).
16. In combat: open the window, shift-click, hover items → no "Aktion blockiert"/taint message. BugSack empty.
17. `/bof perf` with the window closed and with a run in the Farm tab.

### Checklist 0.3.0-alpha.3 (Classic Era, alternative details)

1. `/reload`, `/bof version` → `0.3.0-alpha.3`. Select a goal from a wearable recipe.
2. `/bof alt add <item link> planned Questbelohnung` → note the number n in the answer.
3. `/bof alt cost n 1g 50s`, `/bof alt time n 1h 30m`, `/bof alt req n Stufe 20, Questreihe` → each
   answer shows the alternative and below it "Aufwand: Kosten 1g 50s, Zeit 1 Std. 30 Min.; Voraussetzung: …".
4. `/bof craft` and tab "Craft" → below the alternative: "Aufwand: … (Craft: Kosten …, Farmzeit …)".
   Long lines wrap without overlapping.
5. `/bof alt cost n clear` → "Kosten unbekannt". Errors: `/bof alt time n 90` (no unit),
   `/bof alt cost 99 1g` (unknown number) → clear messages, nothing changes.
6. `/reload` → the details are kept. BugSack: no errors.

### Release check 0.5.0 (2026-10-19)

| Step (CLAUDE.md section 9) | Result |
|---|---|
| Checks levels 0, 1, 1b, 1c, 2 | 256 passed, 0 failed |
| In-game test (Classic Era) | 0.5.0-alpha.1 (Auctionator, DPS key; one finding: no goal arrows in the Sourcing tab) and 0.5.0-alpha.2 (all checklist items) passed; 0.5.0 = 0.5.0-alpha.2 code |
| In-game test (Forever) | none – the release must not be called Forever-compatible |
| Version in TOC, CHANGELOG, README | 0.5.0 |
| Interface version | 11509 = client 1.15.9 (70003), unchanged |
| Addon list metadata | `## Category` (free text, read by `Blizzard_AddOnList/AddonList.lua` in 70003), `## Category-deDE` (localized variant), `## IconTexture` (coin icon of the minimap button); confirmed in game 2026-10-19: group "Berufe", coin icon, version 0.5.0, no errors |
| ZIP | built and inspected: 82 files, top folder `BuyOrFarmForever/`, no dev files |
| Performance | static review below; in-game `/bof perf` not measured for 0.5.0 |
| Tag | `v0.5.0`, only after the user's approval |

### Performance review before 0.5.0 (2026-10-19, static)

No new events, tickers or `OnUpdate`. Auctionator is read on demand (price lookups while building a
plan, a tab or `/bof price`), never in an event loop. The Sourcing tab now also runs
`FarmEstimates.Byproducts` per farmable missing material and `GoldRoutes.List` once per refresh
(at most 500 runs; sale value looked up once per item); refreshes stay coalesced and only happen
while the tab is shown. The time limit re-settles the plan at most once per plan line. Verdict: ok.

### Release check 0.4.0 (2026-10-19)

| Step (CLAUDE.md section 9) | Result |
|---|---|
| Checks levels 0, 1, 1b, 1c, 2 | 226 passed, 0 failed |
| In-game test (Classic Era) | 0.4.0-alpha.1 (all checklist items, one layout finding) and 0.4.0-alpha.2 (fix) passed; 0.4.0 = 0.4.0-alpha.2 code |
| In-game test (Forever) | none – the release must not be called Forever-compatible |
| Version in TOC, CHANGELOG, README | 0.4.0 |
| Interface version | 11509 = client 1.15.9 (70003), unchanged |
| ZIP | built and inspected (see below) |
| Performance | static review below; in-game `/bof perf` for 0.4.0 was not measured (release approved without it) |
| Tag | `v0.4.0`, pushed with `main` after the user's approval (2026-10-19) |

ZIP `outputs/BuyOrFarmForever.zip` (2026-10-19): 79 files, top folder `BuyOrFarmForever/`, `/` as
separator, no dev files; TOC `## Version: 0.4.0`, `## Interface: 11509`. Found during this check:
`Bindings.xml` (not in the TOC) was missing from the ZIP; `work/tools/build_zip.py` now adds it
(`.pkgmeta` does not exclude it). The 0.3.0 ZIP was moved to `work/backup/BuyOrFarmForever-0.3.0.zip`.

### Performance review before 0.4.0 (2026-10-19, static)

New always-registered handlers (all cheap flag updates or rare): `MoneyContext` (window and loot
open/close flags), `TooltipLines` (dirty flag on bag/data/equipment changes; the cache is rebuilt
only on the next item tooltip), `GoldAuto` (one comparison per gold change; distributes only with
the setting and after a gain), `QuestAlternatives` (quest frame only), `FarmSuggest` loot/bag
handlers (only while the setting is on; reads the missing items once per loot window). Handlers
registered only while needed: `FarmAssist` player state (while a run exists), `ShopHints` gold
signal (while a merchant is open), `FarmCapture` window and combat signals (while a run is running).
Timers: one-shot `C_Timer.After` only (taxi check, login summary, price cleanup, prompt bar hide);
the only ticker is still the Farm tab clock. No `OnUpdate` (level 1c). Tooltip hook: one table
lookup per item tooltip after the first rebuild. Verdict: ok; no in-game numbers for 0.4.0.

### Release check 0.3.0 (2026-10-19)

| Step (CLAUDE.md section 9) | Result |
|---|---|
| Checks levels 0, 1, 1b, 1c, 2 | 175 passed, 0 failed |
| In-game test (Classic Era) | every feature tested in 0.3.0-alpha.1 to alpha.3 (results above); 0.3.0 = 0.3.0-alpha.3 code |
| In-game test (Forever) | none – the release must not be called Forever-compatible |
| Version in TOC, CHANGELOG, README | 0.3.0 |
| Interface version | 11509 = client 1.15.9 (70003), unchanged since 2026-10-18 (debug log of the user's client) |
| ZIP | built and inspected (see below) |
| Performance | static review below; in game `/bof perf` idle and with a running farm run in the Farm tab: "quasi 0" (user, 2026-10-19; exact numbers not reported) |
| Tag | `v0.3.0` local only; push/publication only after the user's approval |

ZIP `outputs/BuyOrFarmForever.zip` (2026-10-19): 56 files, top folder `BuyOrFarmForever/`, `/` as
separator, no `.git`, `docs/`, `.luacheckrc`, `.pkgmeta`; TOC `## Version: 0.3.0`, `## Interface: 11509`;
includes the new `UI/AltCommands.lua`. The 0.2.0 ZIP was moved to `work/backup/BuyOrFarmForever-0.2.0.zip`.

### Performance review before 0.3.0 (2026-10-19, static)

Only what changed since the review before 0.2.0:

| Handler | Registered | Frequency | Cost | Verdict |
|---|---|---|---|---|
| `PLAYER_MONEY` → `IncomeCapture` | always (was: only while the Sourcing tab is shown) | per gold change | one income record update; `Income.RecordChange` builds a list of at most 60 day keys for pruning (one small table per gold change) | ok: gold changes are rare (loot, vendor), not per frame |
| `BAGS_CHANGED`, `LOGOUT` → `IncomeCapture` checkpoint | always | per bag-change burst | two number updates, no allocation once the day record exists | ok |
| `PLAYER_EQUIPMENT_CHANGED` → Craft tab | only while the Craft tab is shown | per equipment change | one coalesced refresh (sourcing plan + stat comparison) | ok |
| Craft tab, Gold tab, Farm tab refresh signals | only while the tab is shown | per signal, coalesced to one refresh per frame | text lines only (fixed pools of font strings) | ok |
| Farm tab ticker (`C_Timer.NewTicker`, 1 s, `-- PERF-OK`) | only while the Farm tab is visible **and** a run is running; cancelled on hide, pause and stop | 1 per second | one status text update | ok (unit test: no ticker when hidden or paused) |
| `OnUpdate` | none | – | – | ok (level 1c) |

### Release check 0.2.0 (2026-10-18)

| Step (CLAUDE.md section 9) | Result |
|---|---|
| Checks levels 0, 1, 1b, 1c, 2 | 146 passed, 0 failed |
| In-game test (Classic Era) | every feature tested in the alpha versions (results above); 0.2.0 = 0.2.0-alpha.10 code |
| In-game test (Forever) | none – the release must not be called Forever-compatible |
| Version in TOC, CHANGELOG, README | 0.2.0 |
| Interface version | 11509 = client 1.15.9 (70003), confirmed in game (`/dump GetBuildInfo()`, debug log) |
| ZIP | built and inspected (see below) |
| Tag | `v0.2.0` local only; push/publication only after the user's approval |

### Performance review before 0.2.0 (2026-10-18)

| Handler | Registered | Frequency | Cost | Verdict |
|---|---|---|---|---|
| `ADDON_LOADED`, `PLAYER_LOGIN` (Main) | until handled once | once | load and validate the database | ok |
| `BAG_UPDATE_DELAYED` → `Stock` snapshot | always | per bag-change burst | tracked items only, no allocation in steady state (unit test: 10000 events, constant ~2.5 KB) | ok |
| `BAG_UPDATE_DELAYED` → `FarmCapture` | only while a farm run is running | per bag-change burst | scan of the carried bags (~100 slots); our code allocates nothing (two reused count tables), the client returns one info table per slot | ok, run-only |
| `BANKFRAME_OPENED/CLOSED` | always | per bank visit | snapshot | ok |
| `MERCHANT_SHOW/CLOSED`, `MERCHANT_UPDATE` | show/close always, update only while open | per merchant visit | one table per offer, once per visit | ok |
| `AUCTION_HOUSE_SHOW/CLOSED`, `AUCTION_ITEM_LIST_UPDATE` | list update only while the AH is open | per result page (user-driven) | up to 50 small tables per page | ok, AH-only |
| `LOOT_OPENED/CLOSED`, `PLAYER_LOGOUT` | only while a farm run is running | per loot window | flag/time only | ok |
| `PLAYER_MONEY` | only while the Sourcing tab is shown | per gold change | one coalesced refresh | ok |
| `ITEM_DATA_LOAD_RESULT` | only while the window is shown | per loaded item | one coalesced refresh per frame | ok |
| `TRADE_SKILL_SHOW/CLOSE`, `CRAFT_SHOW/CLOSE` | always | per profession window | two flags | ok |
| Hooks `SelectTradeSkill`, `SelectCraft` | once at load | per recipe click | one variable | ok |
| `OnUpdate`, tickers | none | – | – | ok (level 1c) |
| `C_Timer.After(0)` | per coalesced refresh | at most once per frame while the window is visible | – | ok |

In game (0.2.0-alpha.5): 259 KB memory, peak 0.13 % of frame time. Open: memory over a long session
(several hours, with farm runs and the window open) was not measured.

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

### Checklist 0.3.0-alpha.1 (Classic Era, craft evaluation)

A character with a crafting profession that makes wearable items (Tailoring, Blacksmithing).
One command per line.

1. `/reload`, `/bof version` → `0.3.0-alpha.1`. The window title is on the right, the three tab buttons
   "Material", "Beschaffung", "Craft" on the left do not cover it.
2. Profession window: select a wearable recipe (e.g. a cloth chest or bracers), `/bof recipe`.
3. `/bof craft` → "[Item]: Wertung X – angelegt: [your item] (Y), Unterschied +/-Z", cost line, per-point line
   (if better), limits line, weights line. Check X and Y against the item tooltips (sum of STR, AGI,
   STA, INT, SPI with all weights 1).
4. `/bof weights int 2` → the scores change; `/bof weights int 1` again.
5. `/bof craft <link of an item in your bags>` → comparison with the equipped item of that slot.
   Rings/trinkets: compared with the weaker one. A material → "kann nicht angelegt werden".
6. `/bof alt add <some item> planned Questbelohnung`, `/bof alt add <other item> drop` → `/bof craft`
   shows both alternatives; `/bof alt remove 1`.
7. `/bof show`, tab "Craft" → the same lines. Equip a different item in that slot → the tab updates.
8. Owned materials: carry some reagents of the recipe → "Schon vorhanden: …" line with vendor value.
9. Tab "Farmen": "Start: Gegner" → chat confirms, the time counts up every second; "Anreise" →
   button reads "Angekommen", click again; "Pause"/"Fortsetzen"; loot something; "Beenden" →
   "Unklare mitzählen", "Speichern" appear; "Speichern". Switch tabs/close the window during a run
   and reopen → time still right. Estimates for the selected goal are listed.
10. Gold buffer: `/bof gold add 5g Reiten`, `/bof gold add 1g Training`, `/bof gold distribute`, `/bof gold`
    → overview with reserves and free gold; `/bof gold check 3g` → reserve use. Tab "Goldpuffer":
    same overview, buttons work, the 5 tab buttons do not overlap the title.
11. Income: after login no fake income (`/bof gold` right after login: no big gain); sell something
    → gain; repair/buy → spending. After 1 h of play: net per hour and the time value in the
    Sourcing tab.
12. Tab "Hilfe": all commands, long lines wrap, mouse wheel scrolls. Window 720 px wide; the six
    tab buttons do not overlap the title.
13. `/reload` at the end; BugSack: no errors.
