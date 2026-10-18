# Features

Source: feature description (German) in `sources/BuyOrFarmForever-description-de.md` of the development
folder. Priority: material sourcing → craft evaluation → gold buffer.

| Area | Status |
|---|---|
| Foundation: SavedVariables, debug log, slash commands (`help`, `version`, `debug`, `reset`) | 0.1.0, tested out of game only |
| Material goals, requirements, bag + bank stock, shortfall (chat commands) | 0.2.0-alpha.1 (stage 2a), tested out of game only |
| Stock of other characters (same realm, same faction counted) | 0.2.0-alpha.2 (stage 2b), tested in Classic Era (same faction); other faction/realm out of game only |
| Prices per unit from manual entry, merchants and the auction house; realm/faction, outdated flag | 0.2.0-alpha.6 (stage 2e), tested out of game only |
| Main window with Material tab (`/bof show`; display, goal switch, recipe import button) | 0.2.0-alpha.4 (stage 2d), tested in Classic Era |
| Recipe import from the profession / craft window (selected recipe, `/bof recipe`) | 0.2.0-alpha.3 (stage 2c), trade skill window tested in Classic Era; craft window (Enchanting) out of game only |
| Main window, Material tab | planned (stage 2d) |
| Prices, farm runs, sourcing comparison | planned (stage 2e) |
| Craft evaluation (all professions, stat weights, tooltip-based stats if `GetItemStats` is missing) | planned (stage 3) |
| Gold buffer (savings goals, priorities, reserve check) | planned (stage 4) |
| Main window with tabs Material, Farm, Craft, Goldpuffer, Hilfe | planned |
| Forever support (second adapter and TOC) | phase B, after Forever launch |
| English localization | phase 2 |

Decisions (2026-10-18): all professions; farm estimates per character by default with an account-wide
option; stock = bags + bank of the current and other characters on the same realm (same faction counted);
no mailbox; no fallback TOC; no "Forever" in the Classic Era title.
