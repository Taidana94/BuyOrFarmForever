# Features

Source: feature description (German) in `sources/BuyOrFarmForever-description-de.md` of the development
folder. Priority: material sourcing → craft evaluation → gold buffer.

| Area | Status |
|---|---|
| Foundation: SavedVariables, debug log, slash commands (`help`, `version`, `debug`, `reset`) | 0.1.0, tested in Classic Era |
| Material goals, requirements, bag + bank stock, shortfall (chat commands) | 0.2.0-alpha.1 (stage 2a), tested in Classic Era; replaced by wants in 0.10.0 |
| Stock of other characters (same realm, same faction counted) | 0.2.0-alpha.2 (stage 2b), tested in Classic Era (same faction); other faction/realm out of game only |
| Farm tab in the window (buttons, live time, estimates), `/bof farm keep all` | 0.3.0, tested in Classic Era |
| Craft evaluation: crafted item vs. equipped gear with stat weights, cost/time per point, owned material value, alternatives with cost, time effort and requirements (`/bof craft`, Craft tab) | 0.3.0 (stage 3), tested in Classic Era |
| Buy vs. farm vs. partial purchase, strategies, shared budget (`/bof plan`, Sourcing tab) | 0.2.0 (stage 2g), tested in Classic Era; replaced by the wants plan in 0.10.0 |
| Gold buffer: savings goals, distribution, overview, reserve check, net income, time value; Gold tab | 0.3.0 (stage 4), tested in Classic Era |
| Farm runs (start/pause/resume/travel/stop, review of unclear gains, save) and farm time estimates with data basis | 0.2.0-alpha.9 (stage 2f, chat commands), tested in Classic Era |
| Prices per unit from manual entry, merchants and the auction house; realm/faction, outdated flag | 0.2.0-alpha.6 (stage 2e), tested in Classic Era |
| Main window with Material tab (`/bof show`; display, goal switch, recipe import button) | 0.2.0-alpha.4 (stage 2d), tested in Classic Era |
| Recipe import from the profession / craft window (selected recipe, `/bof recipe`) | 0.2.0-alpha.3 (stage 2c), trade skill and craft window tested in Classic Era |
| Player relief: every action in the window (input boxes, item slots with drag and drop and shift-click, settings tab), farm automation (idle time, unclear gains by rule, auto save, auto pause/travel, start suggestion, target reached), tooltip lines, merchant/auction hints, weight templates, quest rewards as alternatives, minimap button, key bindings, summaries, automatic gold distribution with undo, income by source, old price cleanup | 0.4.0, tested in Classic Era |
| Optional Auctionator price source (live, switchable, not stored) | 0.5.0, tested in Classic Era |
| Sourcing with a farm time limit; joint evaluation of materials from the same runs (by-products) | 0.5.0, tested in Classic Era |
| Gold routes: farm something else, sell, buy (sale value per hour from saved runs) | 0.5.0, tested in Classic Era |
| Craft: armor and weapon DPS weights, verdict vs. planned replacement, level requirement | 0.5.0, tested in Classic Era |
| Gold planner: farm routes (zone + activity + target, looted coins), bag tasks (vendor / auction / disenchant, keep list), recipe book with craft profit and cooldowns, time plans for 1/2/4 h or any duration (`/bof goldplan`, planner view in the Gold buffer tab) | 0.6.0, tested in Classic Era (routes with developer sample runs) |
| Advisor ("Ratgeber"): context-aware suggestion cards in an own window and next to merchant, auction house, bank and mailbox; sell and buy at the merchant on click; window rows sell, disenchant, craft, savings goal, best hour (0.7.0-alpha.4) | 0.8.0 (developed as 0.7.0, not released separately), tested in Classic Era |
| Professions tab ("Berufe"): one view per profession with the learned recipes grouped by what they are good for (food/elixirs/enchantments per buffed stat, gear per stat, else item class), skill bar, search, reagent filter (all / some / complete), detail with reagents, crafts possible, cost, value and profit, button to create a material goal (user request 2026-10-23: learned recipes only, new tab) | 0.8.0, tested in Classic Era (Cooking, First Aid, Tailoring, Enchanting; other professions out of game only) |
| Crafting from the professions tab: count box, "Alle", "Stapel"; opens the profession window if needed (second click crafts); `/bof make` (user request 2026-10-23) | 0.9.0-alpha.1, out of game only |
| Wants ("Ziele"): one tab replaces Material, Sourcing and Craft; per wanted item the cheapest of have / buy / farm / craft, recursively for reagents, farm time valued at the best route's gold per hour; craft and farm from the plan; full automatic stock of bags and bank of every character; farm window (Start, Pause, Anreise, Beenden) and routes per zone in the Farm tab; gear rating in the professions detail, weights in the settings tab; old goals migrated (schema 2) (user request 2026-10-23) | 0.10.0-alpha.1, out of game only |
| Forever support (second adapter and TOC) | phase B, after Forever launch |
| English localization | phase 2 |

Decisions (2026-10-18): all professions; farm estimates per character by default with an account-wide
option; stock = bags + bank of the current and other characters on the same realm (same faction counted);
no mailbox; no fallback TOC; no "Forever" in the Classic Era title.
